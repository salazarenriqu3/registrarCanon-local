const fs = require("fs");
const p =
  "c:/Users/admin/Downloads/registrar1/registrar/src/main/resources/CAPSS_Deployment_and_Demo_Manual.md";
let c = fs.readFileSync(p, "utf8");

function rep(label, from, to) {
  if (c.includes(from)) {
    c = c.replace(from, to);
    console.log("OK:", label);
  } else {
    console.log("MISS:", label);
  }
}

rep(
  "section2b",
  "## SECTION 2 \u2014 Files Needed",
  "## SECTION 2b \u2014 Files Needed"
);
rep(
  "section refs",
  "Then follow **Section 4** (database) and **Section 5** (deploy) below.",
  "Then follow **Section 3** (database) and **Section 4** (deploy) below."
);
rep(
  "db/fix title",
  "### Script 1: `db/fix` *(only required SQL on a fresh PC)*",
  "### Script 1: `db/fix` *(fresh setup \u2014 step 1 of 5)*"
);
rep(
  "tomcat path",
  "> The Tomcat installation path on this machine is:\n> `C:\\Users\\Peyt\\Downloads\\apache-tomcat-10.1.41-windows-x64\\apache-tomcat-10.1.41\\`",
  "> Use your Tomcat install path, e.g. `C:\\apache-tomcat-10.1.54\\`"
);

if (!c.includes("Build & deploy WARs")) {
  c = c.replace(
    "| 8 | `db/demo_scripts/01_demo_grades_y1s1.sql`",
    "| 8 | **Build & deploy WARs** | **Before demo** | See `NEW_PC_SETUP.md` or `FINANCE_FIX_STEPS.md` |\n| 9 | `db/demo_scripts/01_demo_grades_y1s1.sql`"
  );
  for (let n = 15; n >= 9; n--) {
    c = c.replace(
      `| ${n} | \`db/demo_scripts/`,
      `| ${n + 1} | \`db/demo_scripts/`
    );
  }
  console.log("OK: build WAR row");
}

const oldSetup = `SETUP (before panel arrives):
  [ ] db/fix executed in Workbench \u2014 no red errors (only SQL script required on fresh PC)
  [ ] db/demo_scripts/00_demo_applicant_setup.sql OR demo_full_lifecycle.sql executed
  [ ] All three WARs on port 8080: /admission + /enrollment + /registrar
  [ ] Two browser windows open side by side
  [ ] Enrollment window OPEN (system_settings enrollment_open = 'true')`;

const newSetup = `SETUP (before panel arrives):
  [ ] db/fix \u2014 no red errors
  [ ] 00_fresh_demo_bootstrap.sql
  [ ] 00_bsit_full_align_term_and_curriculum.sql
  [ ] seed_program_fees_full_lifecycle.sql
  [ ] demo_full_lifecycle.sql OR demo_elon_2026-0004_fresh.sql OR 00_demo_applicant_setup.sql
  [ ] Latest enrollment.war + registrar.war + admission.war deployed; Tomcat restarted
  [ ] All three apps on http://localhost:8080
  [ ] enrollment_open = true`;

rep("setup checklist", oldSetup, newSetup);

const start = c.indexOf("```\nUSB / delivery folder");
const end = c.indexOf("```", start + 4);
if (start !== -1 && end !== -1) {
  const block = `\`\`\`
USB / delivery folder
\u251c\u2500\u2500 registrar/                         \u2190 source + db/fix + demo_scripts [REQUIRED]
\u251c\u2500\u2500 enrollment3/                       \u2190 enrollment source + mvnw.cmd [REQUIRED to build]
\u251c\u2500\u2500 admission source/                  \u2190 builds admission.war
\u251c\u2500\u2500 registrar/src/main/resources/
\u2502   \u251c\u2500\u2500 NEW_PC_SETUP.md                \u2190 new machine checklist
\u2502   \u251c\u2500\u2500 AGENT_HANDOVER_JUN2026.md      \u2190 dev/agent handoff
\u2502   \u2514\u2500\u2500 CAPSS_Deployment_and_Demo_Manual.md
\u251c\u2500\u2500 db/fix                             \u2190 inside registrar/ [REQUIRED once per PC]
\u251c\u2500\u2500 db/demo_scripts/                   \u2190 bootstrap, fees, demo seeds, grades
\u251c\u2500\u2500 admission.war                      \u2190 or build from source
\u251c\u2500\u2500 registrar.war
\u2514\u2500\u2500 enrollment.war
\`\`\``;
  c = c.slice(0, start) + block + c.slice(end + 3);
  console.log("OK: files block");
}

fs.writeFileSync(p, c);
console.log("Done");
