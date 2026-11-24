permissionset 53003 "SI MASTER DATA READ"
{
    Assignable = true;
    Caption = 'SI Master Data: Read Only';

    Permissions =
        // ============================================================
        // STANDARD BC MASTER DATA — READ ONLY
        // No Item List / Item Categories page execution is granted.
        // Cards are available when opened from controlled business UI.
        // ============================================================
        tabledata Item = R,
        tabledata "Item Attribute" = R,
        tabledata "Item Attribute Value" = R,
        tabledata "Item Attribute Value Mapping" = R,
        tabledata "Item Category" = R,
        tabledata "Item Unit of Measure" = R,
        tabledata "Item Variant" = R,
        table "SI Attribute Semantic" = X,
        tabledata "SI Attribute Semantic" = R,
        table "SI Category Attribute Buffer" = X,
        // ============================================================
        // ITEM CUSTOM VIEW — READ/OPEN ONLY
        // ============================================================
        tabledata "SI Category Attribute Buffer" = R,
        table "SI Config. ERP Projection" = X,
        tabledata "SI Config. ERP Projection" = R,
        table "SI ERP Projection Prev Buffer" = X,
        table "SI Family Parameter" = X,
        tabledata "SI Family Parameter" = R,
        table "SI Family Template Parameter" = X,
        tabledata "SI Family Template Parameter" = R,
        table "SI Item ERP Projection" = X,
        tabledata "SI Item ERP Projection" = R,
        table "SI Item Package" = X,
        tabledata "SI Item Package" = R,
        table "SI Package Type" = X,
        // Create/Delete UI pages and management codeunit are NOT granted:
        // page "SI New Item Category"
        // page "SI New Item Cat. Attrs"
        // codeunit "SI Item Cat. Workspace Mgt."

        // ============================================================
        // SI MASTER DATA TOOLKIT / UoM — READ ONLY
        // ============================================================
        tabledata "SI Package Type" = R,
        table "SI Parameter Value" = X,
        tabledata "SI Parameter Value" = R,
        table "SI Parameter Value Attr." = X,
        tabledata "SI Parameter Value Attr." = R,
        table "SI Product Config." = X,
        tabledata "SI Product Config." = R,
        table "SI Product Config. Value" = X,
        tabledata "SI Product Config. Value" = R,
        table "SI Product Family" = X,
        // ============================================================
        // PRODUCT CONFIGURATOR — READ ONLY
        // ============================================================
        tabledata "SI Product Family" = R,
        table "SI Product Family Template" = X,
        tabledata "SI Product Family Template" = R,
        table "SI Product Parameter" = X,
        tabledata "SI Product Parameter" = R,
        table "SI Value Attr. Definition" = X,
        tabledata "SI Value Attr. Definition" = R,
        tabledata "Unit of Measure" = R,
        codeunit "SI Derived UoM Calc." = X,
        // Read-only resolver/validation services only.
        codeunit "SI ERP Context Resolver" = X,
        codeunit "SI ERP Projection Validator" = X,
        codeunit "SI Naming Engine" = X,
        codeunit "SI Reference Parameter Mgt." = X,
        // Calculation/lookup service may be used, but no setup/migration tools.
        codeunit "SI UoM Mgt." = X,
        codeunit "SI Validation Engine" = X,
        codeunit "SI Value Attr. Resolver" = X,
        page "Item Attributes" = X,
        page "Item Attribute Values" = X,
        page "Item Card" = X,
        page "Item Category Card" = X,
        page "Item Units of Measure" = X,
        page "Item Variants" = X,
        page "SI Attribute Semantics" = X,
        page "SI Category Attributes FactBox" = X,
        page "SI Compatible UoM Lookup" = X,
        page "SI Config. ERP Projection" = X,
        page "SI Config. ERP Projections" = X,
        page "SI ERP Projection Preview" = X,
        page "SI Family Parameters" = X,
        page "SI Group Items Part" = X,
        page "SI Item Category Tree Select" = X,
        page "SI Item Class. Workspace" = X,
        page "SI Item ERP Projections" = X,
        page "SI Item Packages" = X,
        page "SI Item Packages Part" = X,
        page "SI Item Variants Part" = X,
        page "SI Package Type Card" = X,
        page "SI Package Types" = X,
        page "SI Parameter Value Attrs" = X,
        page "SI Parameter Values" = X,
        page "SI Prod. Config. Values" = X,
        page "SI Prod. Families Part" = X,
        page "SI Product Config. Card" = X,
        page "SI Product Configs." = X,
        page "SI Product Configs Part" = X,
        page "SI Product Families" = X,
        page "SI Product Family Card" = X,
        page "SI Product Param. Card" = X,
        page "SI Product Parameters" = X,
        page "SI Unit of Measure Card" = X,
        page "SI Value Attr. Definitions" = X,
        page "SI Value Attr. FactBox" = X,
        page "Units of Measure" = X;
}
