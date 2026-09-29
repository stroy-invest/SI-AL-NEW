permissionset 53001 "SI PROD CONFIG USER"
{
    Assignable = true;
    Caption = 'SI Конфігуратор: користувач';

    Permissions =
        codeunit "SI Reference Parameter Mgt." = X,
        // Operational product configuration.
        tabledata "SI Product Config." = RIM,
        tabledata "SI Product Config. Value" = RIM,
        tabledata "SI Item ERP Projection" = R,
        tabledata "SI Config. ERP Projection" = R,

        // Configuration master data is read-only for ordinary users.
        tabledata "SI Product Family" = R,
        tabledata "SI Product Parameter" = R,
        tabledata "SI Parameter Value" = R,
        tabledata "SI Family Parameter" = R,
        tabledata "SI Product Family Template" = R,
        tabledata "SI Family Template Parameter" = R,

        table "SI Product Config." = X,
        table "SI Product Config. Value" = X,
        table "SI Item ERP Projection" = X,
        table "SI Config. ERP Projection" = X,
        table "SI Product Family" = X,
        table "SI Product Parameter" = X,
        table "SI Parameter Value" = X,
        table "SI Family Parameter" = X,
        table "SI Product Family Template" = X,
        table "SI Family Template Parameter" = X,
        table "SI ERP Projection Prev Buffer" = X,

        // End-user UI.
        page "SI Product Configs." = X,
        page "SI Product Configs List" = X,
        page "SI Product Config. Card" = X,
        page "SI Product Config. Wizard" = X,
        page "SI Prod. Config. Values" = X,
        page "SI Product Configs Part" = X,
        page "SI Product Families" = X,
        page "SI Product Family Card" = X,
        page "SI Prod. Families Part" = X,
        page "SI Family Parameters" = X,
        page "SI Parameter Values" = X,
        page "SI Product Parameters" = X,
        page "SI Product Param. Card" = X,
        page "SI Param. Values Part" = X,
        page "SI Family Params Part" = X,
        page "SI Item ERP Projections" = X,
        page "SI ERP Projection Preview" = X,
        page "SI Config. ERP Projection" = X,
        page "SI Config. ERP Projections" = X,
        page "SI Item Category Tree Select" = X,

        // Runtime engines required by the user workflow.
        codeunit "SI Configuration Engine" = X,
        codeunit "SI ERP Context Resolver" = X,
        codeunit "SI ERP Projection Validator" = X,
        codeunit "SI Naming Engine" = X,
        codeunit "SI Product Config. Mgt." = X,
        codeunit "SI Product Identity Mgt." = X,
        codeunit "SI Validation Engine" = X,
        tabledata "SI SKU Location Buffer" = RIMD,
        table "SI SKU Location Buffer" = X,
        page "SI SKU Location Select" = X,
        codeunit "SI Product Tree Context" = X,
        codeunit "SI SKU Location Mgt." = X;

        // Intentionally excluded:
        // - ERP materializers / projection write management
        // - projection cleanup
        // - family template management
        // - variant number management/counter
}
