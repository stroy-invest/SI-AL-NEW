permissionset 63380 "SI VEHICLE MGT"
{
    Assignable = true;
    Caption = 'SI Vehicle Management';
    Permissions =
        page "SI Vehicle Model Tree" = X,
        page "SI Vehicle Model Char FactBox" = X,
        page "SI Vehicle Tree New Brand" = X,
        page "SI Vehicle Tree New Model" = X,
        codeunit "SI Vehicle Capacity Migration" = X,
        tabledata "SI Vehicle Model Capacity" = RIMD,
        table "SI Vehicle Model Capacity" = X,
        page "SI Vehicle Model Capacities" = X,
        page "SI Vehicle Model Card" = X,
        tabledata "SI Vehicle Brand" = RIMD,
        tabledata "SI Vehicle Model" = RIMD,
        table "SI Vehicle Brand" = X,
        table "SI Vehicle Model" = X,
        page "SI Vehicle Brands" = X,
        page "SI Vehicle Models" = X,
        tabledata "SI Vehicle Setup" = RIMD,
        table "SI Vehicle Setup" = X,
        page "SI Vehicle Setup" = X,
        tabledata "SI Vehicle Profile" = RIMD,
        tabledata "SI Vehicle Type" = RIMD,
        tabledata "SI Vehicle Capacity Type" = RIMD,
        tabledata "SI Vehicle Capacity" = RIMD,
        table "SI Vehicle Profile" = X,
        table "SI Vehicle Type" = X,
        table "SI Vehicle Capacity Type" = X,
        table "SI Vehicle Capacity" = X,
        page "SI Vehicle List" = X,
        page "SI Vehicle Card" = X,
        page "SI Vehicle Types" = X,
        page "SI Vehicle Capacity Types" = X,
        page "SI Vehicle Capacities" = X,
        codeunit "SI Vehicle Management" = X;
}
