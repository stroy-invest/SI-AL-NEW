permissionset 50281 "SI NOTIF ADMIN"
{
    Assignable = true;
    Caption = 'SI Нотифікації: адміністратор';

    Permissions =
        tabledata "SI Business Event Definition" = RIMD,
        table "SI Business Event Definition" = X,

        tabledata "SI Recipient Group" = RIMD,
        table "SI Recipient Group" = X,

        tabledata "SI Business Event Entry" = RIMD,
        table "SI Business Event Entry" = X,

        tabledata "SI Notification Entry" = RIMD,
        table "SI Notification Entry" = X,

        table "SI Notif. Recipient Buffer" = X,

        codeunit "SI Business Event Service" = X,
        codeunit "SI Notification Dispatcher" = X,
        codeunit "SI Notif. Fingerprint Mgt." = X,
        codeunit "SI Explicit User Resolver" = X,
        codeunit "SI Notification Test Mgt." = X,

        page "SI Business Event Definitions" = X,
        page "SI Business Event Def. Card" = X,
        page "SI Recipient Groups" = X,
        page "SI Recipient Group Card" = X,
        page "SI Business Event Entries" = X,
        page "SI Business Event Entry" = X,
        page "SI Notification Entries" = X,
        page "SI Notification Entry" = X,
        codeunit "SI Notif. Lifecycle Mgt." = X;
}