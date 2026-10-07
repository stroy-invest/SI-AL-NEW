permissionset 54032 "SI BP ROLE SETUP"
{
    Assignable = true;
    Caption = 'SI BP: Налаштування ролей';

    Permissions =
        // Configuration of Customer/Vendor role setup records.
        // Intended for MDA / functional administrator.
        // Delete is intentionally withheld.
        tabledata "SI BP Cust. Role Setup" = RIM,
        tabledata "SI BP Vend. Role Setup" = RIM,

        table "SI BP Cust. Role Setup" = X,
        table "SI BP Vend. Role Setup" = X,

        page "SI BP Cust. Role Setup Part" = X,
        page "SI BP Vend. Role Setup Part" = X,

        codeunit "SI BP Role Config Mgt." = X,

        tabledata "SI BP Template Setting" = RIM,
        table "SI BP Template Setting" = X,
        page "SI BP Template Settings" = X,
        codeunit "SI BP Template Resolver" = X;
}
