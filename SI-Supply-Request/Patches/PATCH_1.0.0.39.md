# SI Supply Request Engine 1.0.0.39

## Purchase Receiving Location Refactor

- Purchase allocation no longer inherits Project Location as its planning/receipt Location.
- Added explicit Item + Variant -> default Receiving Location setup (`SI Item Receiving Location`).
- Variant-specific setup takes priority; Item-level setup is fallback.
- Purchase allocation auto-resolves `Target Location Code` from this setup and exposes it as `Склад приходу`.
- `Склад приходу` remains editable while the Supply Decision is Draft.
- Purchase `Source Location Code` is not used.
- Receiving Location lookup/domain validation excludes semantic Location types:
  - СКЛАД ГП
  - СКЛАД ПРОЕКТУ
  - СКЛАД ТЗ
  - ПІДРОЗДІЛ
- Approval revalidates Purchase Receiving Location.
- Existing Planning Demand flow remains unchanged: Purchase demand takes `SI Supply Allocation.Target Location Code`, which now contains the Receiving Location.
- Project Location remains on the Decision/Request lineage as the final internal destination / construction-project context.

## Acceptance scenario

REQ-00045 / reinforcement Ø12:
1. Configure default receiving Location for Item/Variant (e.g. WH-METAL).
2. Create Purchase allocation.
3. Verify `Склад приходу` defaults to configured Location, not Project Location.
4. Optionally change it to another allowed corporate Location before approval.
5. Approve.
6. Rebuild Planning Demand and verify the selected Receiving Location is preserved downstream.
7. Continue through Forecast -> standard BC Planning -> PO and verify the same Location reaches the Purchase Order.
