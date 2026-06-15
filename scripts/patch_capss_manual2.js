const fs = require("fs");
const p =
  "c:/Users/admin/Downloads/registrar1/registrar/src/main/resources/CAPSS_Deployment_and_Demo_Manual.md";
let c = fs.readFileSync(p, "utf8");

c = c.replace(/## SECTION 2 . Files Needed/, "## SECTION 2b \u2014 Files Needed");

c = c.replace(
  /SETUP \(before panel arrives\):[\s\S]*?\[ \] Enrollment window OPEN \(system_settings enrollment_open = 'true'\)/,
  `SETUP (before panel arrives):
  [ ] db/fix \u2014 no red errors
  [ ] 00_fresh_demo_bootstrap.sql
  [ ] 00_bsit_full_align_term_and_curriculum.sql
  [ ] seed_program_fees_full_lifecycle.sql
  [ ] demo_full_lifecycle.sql OR demo_elon_2026-0004_fresh.sql OR 00_demo_applicant_setup.sql
  [ ] Latest enrollment.war + registrar.war + admission.war deployed; Tomcat restarted
  [ ] All three apps on http://localhost:8080
  [ ] enrollment_open = true`
);

// Fix grade script row numbers after build WAR row
const gradeRows = [
  ["01_demo_grades_y1s1", "10 subjects"],
  ["02_demo_grades_y1s2", "8 subjects"],
  ["03_demo_grades_y2s1", "7 subjects"],
  ["04_demo_grades_y2s2", "6 subjects"],
  ["05_demo_grades_y3s1", "6 subjects"],
  ["06_demo_grades_y3s2", "5 subjects"],
  ["07_demo_grades_y4s1", "4 subjects"],
  ["08_demo_grades_y4s2", "2 subjects"],
];
let n = 9;
for (const [script, note] of gradeRows) {
  const re = new RegExp(
    `\\| \\d+ \\| \`db/demo_scripts/${script}\\.sql\` \\| \\*\\*During demo\\*\\* .+ \\| ${note.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}`,
    "u"
  );
  const m = c.match(re);
  if (m) {
    c = c.replace(m[0], m[0].replace(/^\| \d+ \|/, `| ${n} |`));
    n++;
  }
}

fs.writeFileSync(p, c);
console.log("Fixed section2b, setup, grade row numbers");
