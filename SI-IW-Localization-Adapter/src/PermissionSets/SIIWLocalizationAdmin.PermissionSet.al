permissionset 65000 "SI IW LOC ADMIN"
{
    Assignable = true;
    Caption = 'SI IW Localization Adapter: Адміністратор';

    Permissions =
        codeunit "SI IW BP Identifier Sync" = X,
        codeunit "SI IW BP Event Subscriber" = X,
        tabledata "SI Business Partner" = R,
        tabledata Customer = RM,
        tabledata Vendor = RM;
}
