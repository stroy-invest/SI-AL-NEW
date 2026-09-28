# SI Construction Project 1.0.0.0 — Phase 1 / Slice 1

Minimal domain foundation for the first BC ↔ Proktek vertical slice.

Implemented:
- `SI Customer Type`: `External`, `Internal Project`.
- Customer extension with technical SI customer type.
- Project (`Job`) extension with hidden `SI Project Customer No.` relation.
- Standard `Job."Location Code"` is mandatory for SI project initialization.
- `SI Project Customer Mgt.` creates one technical Internal Project Customer and links it to the Project.
- Project Card action `Ініціалізувати SI Project`.
- Repeated initialization validates and reuses the existing Project Customer; it does not create a duplicate.

Not implemented in this slice:
- Proktek dependency/code.
- Customer synchronization to Proktek.
- Concrete order.
- Production staging/import.
- Posting, Sales Orders, Transfer Orders, Production Orders.

Object range reserved in this app: `60000..60999`.
