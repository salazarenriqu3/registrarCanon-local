const fs = require("fs");
const p =
  "c:/Users/admin/Downloads/registrar1/registrar/docs/handoff/legacy-capss/02-panel-demo/CAPSS_Deployment_and_Demo_Manual.md";
let c = fs.readFileSync(p, "utf8");

const reps = [
  ["**`NEW_PC_SETUP.md`**", "**`../01-new-pc/NEW_PC_SETUP.md`**"],
  ["**`AGENT_HANDOVER_JUN2026.md`**", "**`../03-agent-dev/AGENT_HANDOVER_JUN2026.md`**"],
  ["open **`NEW_PC_SETUP.md`** (same folder as this manual)", "open **`../01-new-pc/NEW_PC_SETUP.md`**"],
  ["read **`AGENT_HANDOVER_JUN2026.md`**", "read **`../03-agent-dev/AGENT_HANDOVER_JUN2026.md`**"],
  ["See `NEW_PC_SETUP.md` or `FINANCE_FIX_STEPS.md`", "See `../01-new-pc/NEW_PC_SETUP.md` or `../05-demo-guides/FINANCE_FIX_STEPS.md`"],
  ["`db/SQL_README.md`", "`../04-database/SQL_README.md`"],
  ["**`db/SQL_README.md`**", "**`../04-database/SQL_README.md`**"],
  ["`db/demo_scripts/README_DEMO_SQL.md`", "`../05-demo-guides/README_DEMO_SQL.md`"],
  ["**`README_DEMO_SQL.md`**", "**`../05-demo-guides/README_DEMO_SQL.md`**"],
  ["`README_DEMO_SQL.md`", "`../05-demo-guides/README_DEMO_SQL.md`"],
  ["`FRESH_FINANCE_DEMO.md`", "`../05-demo-guides/FRESH_FINANCE_DEMO.md`"],
  ["`FINANCE_FIX_STEPS.md`", "`../05-demo-guides/FINANCE_FIX_STEPS.md`"],
  [
    "├── registrar/src/main/resources/\n│   ├── NEW_PC_SETUP.md                ← new machine checklist\n│   ├── AGENT_HANDOVER_JUN2026.md      ← dev/agent handoff\n│   └── CAPSS_Deployment_and_Demo_Manual.md",
    "├── registrar/docs/handoff/legacy-capss/                 ← all docs (this manual)\n│   ├── 01-new-pc/\n│   ├── 02-panel-demo/\n│   ├── 03-agent-dev/\n│   ├── 04-database/\n│   └── 05-demo-guides/",
  ],
];

for (const [from, to] of reps) {
  if (c.includes(from)) {
    c = c.split(from).join(to);
    console.log("OK:", from.slice(0, 50));
  } else {
    console.log("MISS:", from.slice(0, 50));
  }
}

fs.writeFileSync(p, c);
console.log("Done");
