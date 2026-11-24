permissionset 65000 "SI IW LOC ADMIN"
{
    Assignable = true;
    Caption = 'SI IW Localization Adapter: Адміністратор';

    Permissions =
        codeunit "SI IW BP Identifier Sync" = X,
        codeunit "SI IW BP Event Subscriber" = X,
        codeunit "SI IW Vehicle Projection Mgt." = X,
        codeunit "SI IW Vehicle Sync Queue Mgt." = X,
        codeunit "SI IW Vehicle Sync Events" = X,
        codeunit "SI IW Vehicle Sync Processor" = X,
        codeunit "SI IW Vehicle Sync Worker" = X,
        codeunit "SI IW Integration Setup Check" = X,

        table "SI IW Vehicle Type Mapping" = X,
        table "SI IW Vehicle Sync Outbox" = X,
        table "SI IW Setup Check Result" = X,

        tabledata Vendor = RM,
        tabledata Customer = RM,
        tabledata "SI Business Partner" = R,
        tabledata "SI IW Vehicle Type Mapping" = RIMD,
        tabledata "SI IW Vehicle Sync Outbox" = RIMD,

        tabledata "SI Vehicle Profile" = R,
        tabledata "SI Vehicle Type" = R,
        tabledata "Job Queue Entry" = R,
        tabledata "SI Vehicle Brand" = R,
        tabledata "SI Vehicle Model" = R,
        tabledata IWSVehicle = RIM,
        tabledata "SI Vehicle Capacity" = R,
        tabledata "SI Vehicle Capacity Type" = R,

        page "SI IW Vehicle Capacity Part" = X,
        page "SI IW Vehicle Legacy FactBox" = X,
        page "SI IW Vehicle Type Mappings" = X,
        page "SI IW Vehicle Sync Outbox" = X,
        page "SI IW Setup Check Results" = X;
}