permissionset 52000 "SI REQUESTER"
{
    Assignable = true;
    Caption = 'SI Заявник';

    IncludedPermissionSets =
        "SI NOTIF USER";

    Permissions =
        tabledata "SI Request Header" = RIM,
        tabledata "SI Request Line" = RIMD,
        tabledata "SI Req. Status Log" = RI,
        tabledata "SI Construction Object" = R,
        tabledata "SI Request Setup" = R,
        tabledata "SI Requester Setup" = R,
        tabledata "SI My Approvals Cue" = RIMD,

        table "SI My Approvals Cue" = X,

        page "SI Request List" = X,
        page "SI Request Card" = X,
        page "SI Request Lines" = X,
        page "SI Req. Status Log Part" = X,
        page "SI My Approvals Cues" = X,

        page "SI Requester Inbox" = X,
        codeunit "SI Request Inbox Mgt." = X,
        table "SI Request Inbox Buffer" = X,
        tabledata "SI Request Inbox Buffer" = RIMD,
        page "SI Requester Notif. Inbox" = X,
        page "SI Requester Notification Cues" = X,

        codeunit "SI Req. Notif. Navigator" = X,
        codeunit "SI Request Status Mgt." = X,
        codeunit "SI Req. Notification Mgt." = X,
        codeunit "SI Req. Recipient Helper" = X,
        codeunit "SI Req. Requester Resolver" = X,
        codeunit "SI Req. Curr. Appr. Resolver" = X,
        codeunit "SI Req. Next Appr. Resolver" = X;
}