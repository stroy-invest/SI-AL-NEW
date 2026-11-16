#!/usr/bin/env python3
"""Static regression checks for PF accounting patch; not an AL compiler."""
from pathlib import Path
import json
import re

root = Path(__file__).resolve().parents[1]
source = root / "src"
files = {p.relative_to(root).as_posix(): p.read_text(encoding="utf-8-sig") for p in source.rglob("*.al")}
assert json.loads((root / "app.json").read_text(encoding="utf-8"))["version"] == "1.0.0.79"

objects = {}
for path, content in files.items():
    found = re.search(
        r'^\s*(table|page|pageextension|tableextension|codeunit|enum|enumextension|permissionset|permissionsetextension|report|query|xmlport|interface|controladdin|profile)\s+(\d+)\s+',
        content, re.I | re.M,
    )
    if not found:
        if re.search(r'^\s*controladdin\s+"[^"]+"', content, re.I | re.M):
            continue
        raise AssertionError(f"No AL object declaration in {path}")
    kind, number = found.group(1).lower(), int(found.group(2))
    key = (kind, number)
    assert key not in objects, f"Duplicate {key}: {path} and {objects.get(key)}"
    objects[key] = path

joined = "\n".join(files.values())
for obsolete_action in (
    'Codeunit "SI Prok Prod Simulator"',
    'Codeunit "SI Prok Two Truck Sim"',
    'Page "SI Prok Sim Truck Batches"',
    'Page "SI Prok Prod Sim Result"',
    'Codeunit "SI Prok TC01 Output Override"',
):
    assert obsolete_action not in joined, obsolete_action

for path, content in files.items():
    if '"Simulation"' in content or '::Simulation' in content:
        assert path.endswith(
            ("SIProkProductionFact.Table.al", "SIProkAccountingPrepMode.Enum.al",
             "SIProkShipment.Table.al")
        ), f"Runtime relies on historical Simulation: {path}"
    if "CheckFact(" in content:
        assert not re.search(r'CheckFact\([^)]*,', content), f"Legacy mode argument: {path}"

prep = files["src/ProductionFact/Codeunits/SIProkAccountingPrepMgt.Codeunit.al"]
journal = files["src/ProductionFact/Codeunits/SIProkJournalPreparation.Codeunit.al"]
reconcile = files["src/ProductionFact/Codeunits/SIProkJournalReconciliation.Codeunit.al"]
posting = files["src/ProductionFact/Codeunits/SIProkControlledPosting.Codeunit.al"]
audit = files["src/ProductionFact/Codeunits/SIProkPostingAudit.Codeunit.al"]
card = files["src/ProductionFact/Pages/SIProkProductionFactCard.Page.al"]
assert 'Component."Flushing Method"::Manual' in prep
assert 'Material.SetRange("Production Fact Entry No.", Fact."Entry No.")' in journal
assert 'Link.SetRange("Production UUID", Fact."Production UUID")' in journal
assert 'AssertRowsComplete(Fact)' in reconcile
assert 'Audit.AssertGroupNotPosted(Fact, true)' in posting
assert 'Audit.AssertGroupPosted(Fact, false)' in posting
assert 'Audit.AssertGroupPosted(Fact, true)' in posting
assert 'Codeunit.Run(Codeunit::"Item Jnl.-Post Batch"' in posting
assert 'procedure RecoverOutputSandbox' in posting
assert 'Ledger.SetRange("Document No.", DocumentNo)' in audit
assert 'Caption = \'Перевірити готовність\'' in card
assert 'Caption = \'Провести Output / Consumption (Sandbox)\'' in card

print(f"PASS: {len(files)} AL files, {len(objects)} unique AL objects; source-level invariants verified.")
print("NOTE: AL compilation, BC deployment, and real posting require the customer's BC toolchain.")
