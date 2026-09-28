permissionset 53003 "SI MASTER DATA READ"
{
    Assignable = true;
    Caption = 'SI Master Data: Read Only';

    Permissions =
        codeunit "SI Reference Parameter Mgt." = X,
        // ============================================================
        // STANDARD BC MASTER DATA — READ ONLY
        // No Item List / Item Categories page execution is granted.
        // Cards are available when opened from controlled business UI.
        // ============================================================
        tabledata Item = R,
        tabledata "Item Variant" = R,
        tabledata "Item Category" = R,
        tabledata "Unit of Measure" = R,
        tabledata "Item Unit of Measure" = R,
        tabledata "Item Attribute" = R,
        tabledata "Item Attribute Value" = R,
        tabledata "Item Attribute Value Mapping" = R,

        page "Item Card" = X,
        page "Item Variants" = X,
        page "Item Category Card" = X,
        page "Units of Measure" = X,
        page "Item Units of Measure" = X,
        page "Item Attributes" = X,
        page "Item Attribute Values" = X,

        // ============================================================
        // ITEM CUSTOM VIEW — READ/OPEN ONLY
        // ============================================================
        tabledata "SI Category Attribute Buffer" = R,
        table "SI Category Attribute Buffer" = X,

        page "SI Item Class. Workspace" = X,
        page "SI Group Items Part" = X,
        page "SI Item Variants Part" = X,
        page "SI Category Attributes FactBox" = X,

        // Create/Delete UI pages and management codeunit are NOT granted:
        // page "SI New Item Category"
        // page "SI New Item Cat. Attrs"
        // codeunit "SI Item Cat. Workspace Mgt."

        // ============================================================
        // SI MASTER DATA TOOLKIT / UoM — READ ONLY
        // ============================================================
        tabledata "SI Package Type" = R,
        tabledata "SI Item Package" = R,

        table "SI Package Type" = X,
        table "SI Item Package" = X,

        page "SI Package Types" = X,
        page "SI Package Type Card" = X,
        page "SI Item Packages" = X,
        page "SI Item Packages Part" = X,
        page "SI Compatible UoM Lookup" = X,
        page "SI Unit of Measure Card" = X,

        // Calculation/lookup service may be used, but no setup/migration tools.
        codeunit "SI UoM Mgt." = X,
        codeunit "SI Derived UoM Calc." = X,

        // ============================================================
        // PRODUCT CONFIGURATOR — READ ONLY
        // ============================================================
        tabledata "SI Product Family" = R,
        tabledata "SI Product Parameter" = R,
        tabledata "SI Parameter Value" = R,
        tabledata "SI Family Parameter" = R,
        tabledata "SI Product Family Template" = R,
        tabledata "SI Family Template Parameter" = R,
        tabledata "SI Product Config." = R,
        tabledata "SI Product Config. Value" = R,
        tabledata "SI Item ERP Projection" = R,
        tabledata "SI Config. ERP Projection" = R,

        table "SI Product Family" = X,
        table "SI Product Parameter" = X,
        table "SI Parameter Value" = X,
        table "SI Family Parameter" = X,
        table "SI Product Family Template" = X,
        table "SI Family Template Parameter" = X,
        table "SI Product Config." = X,
        table "SI Product Config. Value" = X,
        table "SI Item ERP Projection" = X,
        table "SI Config. ERP Projection" = X,
        table "SI ERP Projection Prev Buffer" = X,

        page "SI Product Families" = X,
        page "SI Product Family Card" = X,
        page "SI Family Parameters" = X,
        page "SI Product Parameters" = X,
        page "SI Product Param. Card" = X,
        page "SI Parameter Values" = X,
        page "SI Product Configs." = X,
        page "SI Product Config. Card" = X,
        page "SI Prod. Config. Values" = X,
        page "SI Product Configs Part" = X,
        page "SI Prod. Families Part" = X,
        page "SI Item ERP Projections" = X,
        page "SI ERP Projection Preview" = X,
        page "SI Config. ERP Projection" = X,
        page "SI Config. ERP Projections" = X,
        page "SI Item Category Tree Select" = X,

        // Read-only resolver/validation services only.
        codeunit "SI ERP Context Resolver" = X,
        codeunit "SI ERP Projection Validator" = X,
        codeunit "SI Naming Engine" = X,
        codeunit "SI Validation Engine" = X,
        tabledata "SI Attribute Semantic" = R,
        table "SI Attribute Semantic" = X,
        page "SI Attribute Semantics" = X;
}
