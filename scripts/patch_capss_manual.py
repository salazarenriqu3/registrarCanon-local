# -*- coding: utf-8 -*-
from pathlib import Path

p = Path(r"c:\Users\admin\Downloads\registrar1\registrar\src\main\resources\CAPSS_Deployment_and_Demo_Manual.md")
c = p.read_text(encoding="utf-8")

replacements = [
    ("## SECTION 2 \u2014 Files Needed", "## SECTION 2b \u2014 Files Needed"),
    (
        "Then follow **Section 4** (database) and **Section 5** (deploy) below.",
        "Then follow **Section 3** (database) and **Section 4** (deploy) below.",
    ),
    (
        "### Script 1: `db/fix` *(only required SQL on a fresh PC)*",
        "### Script 1: `db/fix` *(fresh setup \u2014 step 1 of 5)*",
    ),
    (
        "> The Tomcat installation path on this machine is:\n"
        "> `C:\\Users\\Peyt\\Downloads\\apache-tomcat-10.1.41-windows-x64\\apache-tomcat-10.1.41\\`",
        "> Use your Tomcat install path, e.g. `C:\\apache-tomcat-10.1.54\\`",
    ),
]

for old, new in replacements:
    if old in c:
        c = c.replace(old, new)
        print("OK:", old[:50])
    else:
        print("MISS:", old[:50])

# Insert build WAR row before grade script row 8
needle = "| 8 | `db/demo_scripts/01_demo_grades_y1s1.sql`"
insert = (
    "| 8 | **Build & deploy WARs** | **Before demo** | See `NEW_PC_SETUP.md` or `FINANCE_FIX_STEPS.md` |\n"
    "| 9 | `db/demo_scripts/01_demo_grades_y1s1.sql`"
)
if needle in c and "**Build & deploy WARs**" not in c:
    c = c.replace(needle, insert, 1)
    # Renumber following grade rows 9->10 etc (only first occurrence chain)
    for n in range(15, 8, -1):
        c = c.replace(f"| {n} | `db/demo_scripts/", f"| {n+1} | `db/demo_scripts/", 1)
    print("OK: inserted build WAR row")
else:
    print("SKIP: build WAR row")

old_setup = """SETUP (before panel arrives):
  [ ] db/fix executed in Workbench \u2014 no red errors (only SQL script required on fresh PC)
  [ ] db/demo_scripts/00_demo_applicant_setup.sql OR demo_full_lifecycle.sql executed
  [ ] All three WARs on port 8080: /admission + /enrollment + /registrar
  [ ] Two browser windows open side by side
  [ ] Enrollment window OPEN (system_settings enrollment_open = 'true')"""

new_setup = """SETUP (before panel arrives):
  [ ] db/fix \u2014 no red errors
  [ ] 00_fresh_demo_bootstrap.sql
  [ ] 00_bsit_full_align_term_and_curriculum.sql
  [ ] seed_program_fees_full_lifecycle.sql
  [ ] demo_full_lifecycle.sql OR demo_elon_2026-0004_fresh.sql OR 00_demo_applicant_setup.sql
  [ ] Latest enrollment.war + registrar.war + admission.war deployed; Tomcat restarted
  [ ] All three apps on http://localhost:8080
  [ ] enrollment_open = true"""

if old_setup in c:
    c = c.replace(old_setup, new_setup)
    print("OK: setup checklist")
else:
    print("MISS: setup checklist")

files_start = c.find("```\nUSB / delivery folder")
files_end = c.find("```", files_start + 4)
if files_start != -1 and files_end != -1:
    new_block = """```
USB / delivery folder
├── registrar/                         ← source + db/fix + demo_scripts [REQUIRED]
├── enrollment3/                       ← enrollment source + mvnw.cmd [REQUIRED to build]
├── admission source/                  ← builds admission.war
├── registrar/src/main/resources/
│   ├── NEW_PC_SETUP.md                ← new machine checklist
│   ├── AGENT_HANDOVER_JUN2026.md      ← dev/agent handoff
│   └── CAPSS_Deployment_and_Demo_Manual.md
├── db/fix                             ← inside registrar/ [REQUIRED once per PC]
├── db/demo_scripts/                   ← bootstrap, fees, demo seeds, grades
├── admission.war                      ← or build from source
├── registrar.war
└── enrollment.war
```"""
    c = c[:files_start] + new_block + c[files_end + 3 :]
    print("OK: files block")

p.write_text(c, encoding="utf-8")
print("Done")
