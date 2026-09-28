permissionset 53002 "SI MASTER DATA ADMIN"
{
    Assignable = true;
    Caption = 'SI Master Data Administrator';

    Permissions =
        codeunit "SI Reference Parameter Mgt." = X,
        // ============================================================
        // STANDARD BC MASTER DATA
        // ============================================================
        tabledata Item = RIMD,
        tabledata "Item Variant" = RIMD,
        tabledata "Item Category" = RIMD,
        tabledata "Unit of Measure" = RIMD,
        tabledata "Item Unit of Measure" = RIMD,
        tabledata "Item Attribute" = RIMD,
        tabledata "Item Attribute Value" = RIMD,
        tabledata "Item Attribute Value Mapping" = RIMD,

        page "Item List" = X,
        page "Item Card" = X,
        page "Item Variants" = X,
        page "Item Categories" = X,
        page "Item Category Card" = X,
        page "Units of Measure" = X,
        page "Item Units of Measure" = X,
        page "Item Attributes" = X,
        page "Item Attribute Values" = X,

        // ============================================================
        // ITEM CUSTOM VIEW / CATEGORY WORKSPACE
        // ============================================================
        tabledata "SI Category Attribute Buffer" = RIMD,
        table "SI Category Attribute Buffer" = X,

        page "SI Item Class. Workspace" = X,
        page "SI Group Items Part" = X,
        page "SI Item Variants Part" = X,
        page "SI Category Attributes FactBox" = X,
        page "SI New Item Category" = X,
        page "SI New Item Cat. Attrs" = X,

        //codeunit "SI Item Cat. Workspace Mgt." = X,

        // ============================================================
        // SI MASTER DATA TOOLKIT / UoM
        // ============================================================
        tabledata "SI Package Type" = RIMD,
        tabledata "SI Item Package" = RIMD,

        table "SI Package Type" = X,
        table "SI Item Package" = X,

        page "SI Package Types" = X,
        page "SI Package Type Card" = X,
        page "SI Item Packages" = X,
        page "SI Item Packages Part" = X,
        page "SI Compatible UoM Lookup" = X,
        page "SI Unit of Measure Card" = X,

        codeunit "SI UoM Mgt." = X,
        codeunit "SI Derived UoM Calc." = X,
        codeunit "SI Item Package Mgt." = X,

        // ============================================================
        // SI PRODUCT CONFIGURATOR — MASTER DATA / MATERIALIZATION
        // ============================================================
        tabledata "SI Product Family" = RIMD,
        tabledata "SI Product Parameter" = RIMD,
        tabledata "SI Parameter Value" = RIMD,
        tabledata "SI Family Parameter" = RIMD,
        tabledata "SI Product Family Template" = RIMD,
        tabledata "SI Family Template Parameter" = RIMD,
        tabledata "SI Product Config." = RIMD,
        tabledata "SI Product Config. Value" = RIMD,
        tabledata "SI Item ERP Projection" = RIMD,
        tabledata "SI Config. ERP Projection" = RIMD,
        tabledata "SI ERP Variant No. Counter" = RIMD,

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
        table "SI ERP Variant No. Counter" = X,
        table "SI ERP Projection Prev Buffer" = X,

        page "SI Product Families" = X,
        page "SI Product Family Card" = X,
        page "SI Product Family Templates" = X,
        page "SI Product Family Tmpl. Card" = X,
        page "SI Family Parameters" = X,
        page "SI Family Template Parameters" = X,
        page "SI Family Params Part" = X,
        page "SI Product Parameters" = X,
        page "SI Product Param. Card" = X,
        page "SI Parameter Values" = X,
        page "SI Param. Values Part" = X,
        page "SI Product Configs." = X,
        page "SI Product Config. Card" = X,
        page "SI Product Config. Wizard" = X,
        page "SI Product Model Wizard" = X,
        page "SI Prod. Config. Studio" = X,
        page "SI Prod. Config. Values" = X,
        page "SI Product Configs Part" = X,
        page "SI Prod. Families Part" = X,
        page "SI Item ERP Projections" = X,
        page "SI ERP Projection Preview" = X,
        page "SI Config. ERP Projection" = X,
        page "SI Config. ERP Projections" = X,
        page "SI Item Category Tree Select" = X,
        page "SI Semantic Parameters Part" = X,
        page "SI Wiz. Avail. Params" = X,
        page "SI Wiz. Family Params" = X,
        page "SI Wiz. Param. Values" = X,
        page "SI Wiz. Parameter Card" = X,
        page "SI Wiz. Product Parameters" = X,

        codeunit "SI Configuration Engine" = X,
        codeunit "SI ERP Context Resolver" = X,
        codeunit "SI ERP Item Materializer" = X,
        codeunit "SI ERP Projection Mgt." = X,
        codeunit "SI ERP Orphan Cleanup Subs." = X,
        codeunit "SI ERP Projection Validator" = X,
        codeunit "SI ERP Variant Materializer" = X,
        codeunit "SI ERP Variant No. Mgt." = X,
        codeunit "SI Naming Engine" = X,
        codeunit "SI Family Template Mgt." = X,
        codeunit "SI Product Config. Mgt." = X,
        codeunit "SI Product Identity Mgt." = X,
        codeunit "SI Validation Engine" = X,

        tabledata "SI Attribute Semantic" = RIMD,
        table "SI Attribute Semantic" = X,
        page "SI Attribute Semantics" = X;

    // Deliberately NOT included:
    // codeunit "SI ERP Projection Cleanup Mgt."
    // codeunit "SI Product Config Upgrade"
    // codeunit "SI Item Attr. UoM Migration"
    // page/codeunit diagnostic test objects
}
