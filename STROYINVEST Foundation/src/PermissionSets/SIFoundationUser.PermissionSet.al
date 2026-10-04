permissionset 50198 "SI FOUNDATION USER"
{
    Assignable = true;
    Caption = 'SI Foundation: Користувач';

    Permissions =
        // Corporate reference data: read-only for operational users.
        tabledata "SI Country Currency" = R,
        tabledata "SI Legal Form Group" = R,
        tabledata "SI Legal Form" = R,
        tabledata "SI Legal Form Foreign" = R,
        tabledata "SI Country Legal Form" = R,
        tabledata "SI Bank Directory" = R,
        tabledata "SI Location Type" = R,
        tabledata "SI Location Setup" = R,

        table "SI Country Currency" = X,
        table "SI Legal Form Group" = X,
        table "SI Legal Form" = X,
        table "SI Legal Form Foreign" = X,
        table "SI Country Legal Form" = X,
        table "SI Bank Directory" = X,
        table "SI Location Type" = X,
        table "SI Location Setup" = X,
        page "SI Location Types" = X,

        page "SI Country Currencies" = X,
        page "SI Legal Form Groups" = X,
        page "SI Legal Forms" = X,
        page "SI Foreign Legal Forms" = X,
        page "SI Country Legal Forms" = X,
        page "SI Bank Directory" = X,

        // Operational services that may be called from business modules.
        codeunit "SI Address Parser Mgt." = X,
        codeunit "SI Country Currency Mgt." = X,
        codeunit "SI IBAN Mgt." = X,
        codeunit "SI UA Identifier Mgt." = X,
        codeunit "SI Bank Resolver" = X,
        codeunit "SI NBU Bank Resolver" = X,
        codeunit "SI EDS Orchestrator" = X,
        codeunit "SI EDS Provider Context" = X,
        codeunit "SI EDS HTTP Transport" = X,

        // Organizational Identity is read-only for operational users.
        tabledata "SI User Identity Assignment" = R,
        table "SI User Identity Assignment" = X,
        tabledata "SI User Identity Purpose" = R,
        table "SI User Identity Purpose" = X,
        codeunit "SI Org. Identity Mgt." = X,

        // Runtime EDS configuration is read-only.
        // Credentials/secrets are intentionally excluded.
        tabledata "SI EDS Service" = R,
        tabledata "SI EDS Operation" = R,
        tabledata "SI EDS Provider" = R,
        tabledata "SI EDS Endpoint" = R,
        tabledata "SI EDS Provider Route" = R,
        tabledata "SI EDS Operation Group" = R,
        tabledata "SI EDS Parameter" = R,

        table "SI EDS Service" = X,
        table "SI EDS Operation" = X,
        table "SI EDS Provider" = X,
        table "SI EDS Endpoint" = X,
        table "SI EDS Provider Route" = X,
        table "SI EDS Operation Group" = X,
        table "SI EDS Parameter" = X,
        table "SI EDS Runtime Param" = X,
        page "SI Product Selector" = X,
        page "SI Product Selector Test" = X,
        codeunit "SI Product Selector Mgt." = X,
        page "SI Category Selector" = X,
        codeunit "SI Category Selector Mgt." = X;
}
