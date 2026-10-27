permissionset 63000 "SI GEO ADMIN"
{
    Assignable = true;
    Caption = 'SI Geo Service: адміністратор';
    Permissions =
        tabledata "SI Geo Location Point" = RIMD,
        tabledata "SI Geo Ship-to Point" = RIMD,
        table "SI Geo Ship-to Point" = X,
        page "SI Geo Ship-to Points" = X,
        page "SI Geo Delivery Routing Test" = X,
        codeunit "SI Geo Ship-to Resolver" = X,
        table "SI Geo Location Point" = X,
        page "SI Geo Location Points" = X,
        page "SI Geo Geocoding Test" = X,
        page "SI Geo Routing Test" = X,
        page "SI Geo Location Routing Test" = X,
        codeunit "SI Geo Test Mgt." = X,
        codeunit "SI Geo Response Parser" = X,
        codeunit "SI Geo Routing Test Mgt." = X,
        codeunit "SI Geo Routing Parser" = X,
        codeunit "SI Geo Point Resolver" = X;
}
