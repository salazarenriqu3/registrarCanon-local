$p = 'c:\Users\admin\Downloads\registrar1\registrar\src\main\resources\CAPSS_Deployment_and_Demo_Manual.md'
$c = [System.IO.File]::ReadAllText($p)

$c = $c.Replace('## SECTION 2 \u2014 Files Needed', '## SECTION 2b — Files Needed')
$c = $c.Replace('## SECTION 2 â€" Files Needed', '## SECTION 2b — Files Needed')

$c = $c.Replace(
    'Then follow **Section 4** (database) and **Section 5** (deploy) below.',
    'Then follow **Section 3** (database) and **Section 4** (deploy) below.'
)

$oldRow = @'
| 7 | `demo_full_lifecycle.sql` OR `demo_elon_2026-0004_fresh.sql` OR `00_demo_applicant_setup.sql` | **Before demo** | Maria / Elon / live applicant |
| 8 | `db/demo_scripts/01_demo_grades_y1s1.sql` | **During demo** â€" after Y1S1 block enroll | 10 subjects â€" Year 1 Sem 1 grades |
'@
$newRow = @'
| 7 | `demo_full_lifecycle.sql` OR `demo_elon_2026-0004_fresh.sql` OR `00_demo_applicant_setup.sql` | **Before demo** | Maria / Elon / live applicant |
| 8 | **Build & deploy WARs** | **Before demo** | See `NEW_PC_SETUP.md` or `FINANCE_FIX_STEPS.md` |
| 9 | `db/demo_scripts/01_demo_grades_y1s1.sql` | **During demo** — after Y1S1 block enroll | 10 subjects — Year 1 Sem 1 grades |
'@
if ($c.Contains($oldRow)) { $c = $c.Replace($oldRow, $newRow) }

$c = $c.Replace(
    '### Script 1: `db/fix` *(only required SQL on a fresh PC)*',
    '### Script 1: `db/fix` *(fresh setup — step 1 of 5)*'
)

$c = $c.Replace(
    "> The Tomcat installation path on this machine is:`r`n> ``C:\Users\Peyt\Downloads\apache-tomcat-10.1.41-windows-x64\apache-tomcat-10.1.41\``",
    '> Use your Tomcat install path, e.g. ``C:\apache-tomcat-10.1.54\``'
)

$oldSetup = @'
SETUP (before panel arrives):
  [ ] db/fix executed in Workbench â€" no red errors (only SQL script required on fresh PC)
  [ ] db/demo_scripts/00_demo_applicant_setup.sql OR demo_full_lifecycle.sql executed
  [ ] All three WARs on port 8080: /admission + /enrollment + /registrar
  [ ] Two browser windows open side by side
  [ ] Enrollment window OPEN (system_settings enrollment_open = 'true')
'@
$newSetup = @'
SETUP (before panel arrives):
  [ ] db/fix — no red errors
  [ ] 00_fresh_demo_bootstrap.sql
  [ ] 00_bsit_full_align_term_and_curriculum.sql
  [ ] seed_program_fees_full_lifecycle.sql
  [ ] demo_full_lifecycle.sql OR demo_elon_2026-0004_fresh.sql OR 00_demo_applicant_setup.sql
  [ ] Latest enrollment.war + registrar.war + admission.war deployed; Tomcat restarted
  [ ] All three apps on http://localhost:8080
  [ ] enrollment_open = true
'@
if ($c.Contains($oldSetup)) { $c = $c.Replace($oldSetup, $newSetup) }

$filesBlock = @'
```
USB / delivery folder
â"œâ"€â"€ db/fix                             â†' single consolidated schema + seed file [REQUIRED]
â"œâ"€â"€ db/SQL_README.md                   â†' SQL inventory + single-script install guide
â"œâ"€â"€ db/eacdb_cross_system_schema.sql   â†' legacy DB only (merged into db/fix)
â"œâ"€â"€ db/demo_scripts/                   â†' folder containing step-by-step 4-year demo scripts
â"œâ"€â"€ admission.war                      â†' online application portal (port 8080, path /admission)
â"œâ"€â"€ registrar.war                      â†' registrar sub-system (port 8080 — same Tomcat as enrollment)
â"”â"€â"€ enrollment.war                     â†' enrollment3 sub-system (port 8080)
```
'@
$newFilesBlock = @'
```
USB / delivery folder
├── registrar/                         ← source + db/fix + demo_scripts [REQUIRED]
├── enrollment3/                       ← enrollment source + mvnw.cmd [REQUIRED to build]
├── admission source/                  ← builds admission.war
├── registrar/src/main/resources/
│   ├── NEW_PC_SETUP.md                ← new machine checklist
│   ├── AGENT_HANDOVER_JUN2026.md       ← dev/agent handoff
│   └── CAPSS_Deployment_and_Demo_Manual.md
├── db/fix                             ← inside registrar/ [REQUIRED once per PC]
├── db/demo_scripts/                   ← bootstrap, fees, demo seeds, grades
├── admission.war                      ← or build from source
├── registrar.war
└── enrollment.war
```
'@
if ($c.Contains($filesBlock)) { $c = $c.Replace($filesBlock, $newFilesBlock) }

[System.IO.File]::WriteAllText($p, $c, [System.Text.UTF8Encoding]::new($false))
Write-Host 'Patched CAPSS manual'
