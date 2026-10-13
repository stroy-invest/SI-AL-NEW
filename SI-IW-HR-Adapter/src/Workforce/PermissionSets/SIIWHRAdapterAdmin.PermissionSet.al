permissionset 51000 "SIIWHR ADAPTER ADMIN"
{
    Assignable = true;
    Caption = 'SI IW HR Adapter: Адміністратор';

    Permissions =
        tabledata "SI IW Position Cap. Map" = RIMD,
        table "SI IW Position Cap. Map" = X,
        page "SI IW Position Cap. Maps" = X,
        page "SI IW Workforce Test" = X,
        codeunit "SI IW Workforce Provider" = X;
}
