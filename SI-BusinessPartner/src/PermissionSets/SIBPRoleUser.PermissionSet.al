permissionset 54031 "SI BP ROLE USER"
{
    Assignable = true;
    Caption = 'SI BP: Користувач ролей';

    Permissions =
        // Operational lifecycle of Business Partner roles.
        // Delete is intentionally withheld.
        tabledata "SI BP Role" = RIM,
        tabledata "SI BP Role Status Entry" = RI,

        table "SI BP Role" = X,
        table "SI BP Role Status Entry" = X,

        table "SI BP Partner Tree Buffer" = X,
        page "SI Business Partners Tree" = X,

        page "SI BP Roles" = X,
        page "SI BP Role Card" = X,
        page "SI BP Role History" = X,
        page "SI BP Role Change Dialog" = X,
        page "SI BP Role Create Dialog" = X,

        // Legacy custom template layer removed; role setup remains read-only for operational users.
        tabledata "SI BP Cust. Role Setup" = R,
        tabledata "SI BP Vend. Role Setup" = R,

        table "SI BP Cust. Role Setup" = X,
        table "SI BP Vend. Role Setup" = X,

        // ERP projection is visible and may be maintained through controlled Mgt. codeunits.
        tabledata "SI BP ERP Projection" = RIMD,
        tabledata "SI BP ERP Proj. Bank" = RIMD,

        table "SI BP ERP Projection" = X,
        table "SI BP ERP Proj. Bank" = X,

        page "SI BP Projection Card" = X,
        page "SI BP ERP Projection Part" = X,
        page "SI BP ERP Proj. Banks" = X,

        codeunit "SI BP Projection Mgt." = X,
        codeunit "SI BP Role Config Mgt." = X,
        codeunit "SI BP Role Mgt." = X,

        tabledata "SI BP Template Setting" = R,
        table "SI BP Template Setting" = X,
        codeunit "SI BP Template Resolver" = X,
        page "SI BP Role Activation Wizard" = X,
        codeunit "SI BP Role Activation Mgt." = X;
}
