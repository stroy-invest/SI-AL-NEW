permissionset 55001 "SI MANUFACT USER"
{
    Assignable = true;
    Caption = 'SI Manufacturer: Користувач';

    Permissions =
        codeunit "SI Manufacturer Ref. Provider" = X,
        // Ordinary operational users can browse manufacturer master data.
        tabledata "SI Manufacturer" = R,
        tabledata "SI Manufacturer Product" = R,
        tabledata "SI Approved Manufacturer Prod." = R,
        tabledata "SI Category Manufacturer" = R,

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
        page "SI Approved Mfr. Products FB" = X;
}
