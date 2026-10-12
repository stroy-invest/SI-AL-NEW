permissionset 54030 "SI BP ROLE ADMIN"
{
    Assignable = true;
    Caption = 'SI BP: Адміністратор ролей';

    Permissions =
        // Core Business Partner tables: PTE0004 coverage for Production validation.
        tabledata "SI BP Address" = RIMD,
        table "SI BP Address" = X,
        tabledata "SI BP Bank Account" = RIMD,
        table "SI BP Bank Account" = X,
        tabledata "SI BP Contact Point" = RIMD,
        table "SI BP Contact Point" = X,
        tabledata "SI BP Customer Setup" = RIMD,
        table "SI BP Customer Setup" = X,
        tabledata "SI BP Materialization Run" = RIMD,
        table "SI BP Materialization Run" = X,
        tabledata "SI BP Materialization Step" = RIMD,
        table "SI BP Materialization Step" = X,
        tabledata "SI BP Vendor Setup" = RIMD,
        table "SI BP Vendor Setup" = X,
        tabledata "SI Business Partner" = RIMD,
        table "SI Business Partner" = X,
        tabledata "SI Foreign Bank" = RIMD,
        table "SI Foreign Bank" = X,

        tabledata "SI BP Role" = RIMD,
        tabledata "SI BP Role Status Entry" = RIMD,

        table "SI BP Role" = X,
        table "SI BP Role Status Entry" = X,

        table "SI BP Partner Tree Buffer" = X,
        page "SI Business Partners Tree" = X,

        page "SI BP Roles" = X,
        page "SI BP Role Card" = X,
        page "SI BP Role History" = X,
        page "SI BP Role Change Dialog" = X,
        page "SI BP Role Create Dialog" = X,

        tabledata "SI BP Cust. Role Setup" = RIMD,
        tabledata "SI BP Vend. Role Setup" = RIMD,

        table "SI BP Cust. Role Setup" = X,
        table "SI BP Vend. Role Setup" = X,

        page "SI BP Cust. Role Setup Part" = X,
        page "SI BP Vend. Role Setup Part" = X,
        tabledata "SI BP ERP Projection" = RIMD,
        tabledata "SI BP ERP Proj. Bank" = RIMD,

        table "SI BP ERP Projection" = X,
        table "SI BP ERP Proj. Bank" = X,

        page "SI BP Projection Card" = X,
        page "SI BP ERP Proj. Banks" = X,

        codeunit "SI BP Projection Mgt." = X,
        codeunit "SI BP Role Config Mgt." = X,
        codeunit "SI BP Role Mgt." = X,

        tabledata "SI BP Template Setting" = RIMD,
        table "SI BP Template Setting" = X,
        page "SI BP Template Settings" = X,
        codeunit "SI BP Template Resolver" = X,
        page "SI BP Role Activation Wizard" = X,
        codeunit "SI BP Role Activation Mgt." = X;
}
