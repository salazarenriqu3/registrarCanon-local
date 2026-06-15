const fs = require("fs");
const path = require("path");

const root = "c:/Users/admin/Downloads/registrar1/registrar";
const files = [];

function walk(dir) {
  for (const ent of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, ent.name);
    if (ent.isDirectory() && !ent.name.includes("node_modules") && ent.name !== "target") walk(p);
    else if (/\.(md|txt|sql)$/i.test(ent.name)) files.push(p);
  }
}
walk(path.join(root, "handoff"));
walk(path.join(root, "db"));
files.push(path.join(root, "START_HERE.txt"));
files.push("c:/Users/admin/Desktop/May 26, 2026 Systems/enrollment3/HANDOVER.md");

const reps = [
  ["db/demo_scripts/00_fresh_demo_bootstrap.sql", "db/capss-demo-required/01_setup/01_fresh_demo_bootstrap.sql"],
  ["db\\demo_scripts\\00_fresh_demo_bootstrap.sql", "db\\capss-demo-required\\01_setup\\01_fresh_demo_bootstrap.sql"],
  ["demo_scripts/00_fresh_demo_bootstrap.sql", "capss-demo-required/01_setup/01_fresh_demo_bootstrap.sql"],
  ["00_fresh_demo_bootstrap.sql", "capss-demo-required/01_setup/01_fresh_demo_bootstrap.sql"],
  ["db/demo_scripts/00_bsit_full_align_term_and_curriculum.sql", "db/capss-demo-required/01_setup/02_bsit_full_align_term_and_curriculum.sql"],
  ["demo_scripts/00_bsit_full_align_term_and_curriculum.sql", "capss-demo-required/01_setup/02_bsit_full_align_term_and_curriculum.sql"],
  ["00_bsit_full_align_term_and_curriculum.sql", "capss-demo-required/01_setup/02_bsit_full_align_term_and_curriculum.sql"],
  ["db/demo_scripts/seed_program_fees_full_lifecycle.sql", "db/capss-demo-required/01_setup/03_seed_program_fees_full_lifecycle.sql"],
  ["demo_scripts/seed_program_fees_full_lifecycle.sql", "capss-demo-required/01_setup/03_seed_program_fees_full_lifecycle.sql"],
  ["seed_program_fees_full_lifecycle.sql", "capss-demo-required/01_setup/03_seed_program_fees_full_lifecycle.sql"],
  ["db/demo_scripts/demo_full_lifecycle.sql", "db/capss-demo-required/02_demo_seed_pick_one/demo_full_lifecycle.sql"],
  ["db/demo_scripts/demo_elon_2026-0004_fresh.sql", "db/capss-demo-required/02_demo_seed_pick_one/demo_elon_2026-0004_fresh.sql"],
  ["db/demo_scripts/00_demo_applicant_setup.sql", "db/capss-demo-required/02_demo_seed_pick_one/00_demo_applicant_setup.sql"],
  ["db/demo_scripts/00_demo_reset.sql", "db/capss-demo-required/06_reset/00_demo_reset.sql"],
  ["demo_scripts/demo_full_lifecycle.sql", "capss-demo-required/02_demo_seed_pick_one/demo_full_lifecycle.sql"],
  ["db/demo_scripts/01_demo_grades_y1s1.sql", "db/capss-demo-required/03_grades_maria/01_demo_grades_y1s1.sql"],
  ["db/demo_scripts/02_demo_grades_y1s2.sql", "db/capss-demo-required/03_grades_maria/02_demo_grades_y1s2.sql"],
  ["db/demo_scripts/03_demo_grades_y2s1.sql", "db/capss-demo-required/03_grades_maria/03_demo_grades_y2s1.sql"],
  ["db/demo_scripts/04_demo_grades_y2s2.sql", "db/capss-demo-required/03_grades_maria/04_demo_grades_y2s2.sql"],
  ["db/demo_scripts/05_demo_grades_y3s1.sql", "db/capss-demo-required/03_grades_maria/05_demo_grades_y3s1.sql"],
  ["db/demo_scripts/06_demo_grades_y3s2.sql", "db/capss-demo-required/03_grades_maria/06_demo_grades_y3s2.sql"],
  ["db/demo_scripts/07_demo_grades_y4s1.sql", "db/capss-demo-required/03_grades_maria/07_demo_grades_y4s1.sql"],
  ["db/demo_scripts/08_demo_grades_y4s2.sql", "db/capss-demo-required/03_grades_maria/08_demo_grades_y4s2.sql"],
];

let n = 0;
for (const f of files) {
  if (!fs.existsSync(f)) continue;
  let c = fs.readFileSync(f, "utf8");
  let changed = false;
  for (const [a, b] of reps) {
    if (c.includes(a)) {
      c = c.split(a).join(b);
      changed = true;
    }
  }
  if (changed) {
    fs.writeFileSync(f, c);
    n++;
    console.log("updated", path.relative(root, f));
  }
}
console.log("Total files updated:", n);
