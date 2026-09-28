permissionset 58001 "SI MDT USER"
{
    Assignable = true;
    Caption = 'SI Master Data Toolkit: User';

    Permissions =
        // Ordinary users have READ ONLY access to all UoM/package master data.
        tabledata "SI Package Type" = R,
        table "SI Package Type" = X,
        page "SI Package Types" = X,
        page "SI Package Type Card" = X,


        tabledata "SI Item Package" = R,
        table "SI Item Package" = X,
        page "SI Item Packages" = X,
        page "SI Item Packages Part" = X,
        page "SI Compatible UoM Lookup" = X,
        page "SI Unit of Measure Card" = X,
        page "SI Item UoM Conversion Test" = X,

        table "SI Item Derived UoM Value" = X,
        tabledata "SI Item Derived UoM Value" = R,

        // Runtime calculation/validation only.
        codeunit "SI UoM Mgt." = X,
        codeunit "SI Derived UoM Calc." = X,
        codeunit "SI Item UoM Conversion" = X;

    // No create/modify/delete.
    // No migration/test utilities.
    // No SI Item Package Mgt. write service.
}
