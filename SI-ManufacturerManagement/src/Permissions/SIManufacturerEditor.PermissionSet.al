permissionset 55002 "SI MANUFACT EDIT"
{
    Assignable = true;
    Caption = 'SI Manufacturer: Редактор';

    Permissions =
        // Master Data Administrator / designated editor.
        // Delete is intentionally withheld.
        tabledata "SI Manufacturer" = RIM,
        tabledata "SI Manufacturer Product" = RIM,
        tabledata "SI Approved Manufacturer Prod." = RIM,
        tabledata "SI Category Manufacturer" = RIM,
        tabledata "Item Variant" = RI,

        table "SI Manufacturer" = X,
        table "SI Manufacturer Product" = X,
        table "SI Approved Manufacturer Prod." = X,
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
