permissionset 58000 "SI MDT ADMIN"
{
    Assignable = true;
    Caption = 'SI Master Data Toolkit: Administrator';

    Permissions =
        tabledata "SI Package Type" = RIMD,
        table "SI Package Type" = X,
        page "SI Package Types" = X,
        page "SI Package Type Card" = X,


        tabledata "SI Item Package" = RIMD,
        table "SI Item Package" = X,
        page "SI Item Packages" = X,
        page "SI Item Packages Part" = X,
        page "SI Compatible UoM Lookup" = X,
        page "SI Derived UoM Test" = X,

        table "SI Item Derived UoM Value" = X,
        tabledata "SI Item Derived UoM Value" = RIMD,

        codeunit "SI UoM Mgt." = X,
        codeunit "SI Derived UoM Calc." = X,
        codeunit "SI Item UoM Conversion" = X,
        codeunit "SI Item Package Mgt." = X,
        codeunit "SI Item Attr. UoM Migration" = X;
}
