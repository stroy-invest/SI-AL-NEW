# Application layer — MVP

- `SI Product Config. Mgt.` — фасад для сторінок.
- `SI Configuration Engine` — створення та зміна продуктової моделі.
- `SI Validation Engine` — перевірка конфігурацій, категорій і дублів.
- `SI Naming Engine` — назви, коди, канонічні значення та hash.
- `SI ERP Context Resolver` — Item Category, Item Template і Base UoM.
- `SI Product Identity Mgt.` — семантичні Item/Variant Composite Keys.
- `SI ERP Projection Validator` — готовність попереднього перегляду.
- `SI ERP Projection Mgt.` — оркестрація тільки ERP Preview.

Автоматичне створення Item / Item Variant буде окремим наступним кроком і не повинно повертати старий ручний сценарій прив’язки.
