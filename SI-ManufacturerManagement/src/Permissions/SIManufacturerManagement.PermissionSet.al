permissionset 55000 "SI Manufact. Mgt"
{
    Assignable = true;
    Caption = 'SI Manufacturer Management';

    Permissions =
        tabledata "SI Manufacturer" = RIMD,
        table "SI Manufacturer" = X,
        tabledata "SI Manufacturer Product" = RIMD,
        table "SI Manufacturer Product" = X,
        tabledata "SI Approved Manufacturer Prod." = RIMD,
        table "SI Approved Manufacturer Prod." = X,
        tabledata "SI Category Manufacturer" = RIMD,
        tabledata "Item Variant" = RI,
        table "SI Category Manufacturer" = X,
        page "SI Manufacturers" = X,
        page "SI Manufacturer Card" = X,
        page "SI Manufacturer Products" = X,
        page "SI Manufacturer Product Card" = X,
        page "SI Approved Mfr. Products" = X,
        page "SI Category Manufacturers" = X,
        page "SI Add Category Manufacturer" = X,
        page "SI Add Approved Mfr. Product" = X,
        page "SI Approved Mfr. Products FB" = X,
        page "SI Create Variant from MfrProd" = X,
        codeunit "SI Manufacturer Mgt." = X,
        codeunit "SI Manufacturer Ref. Provider" = X;
}