permissionset 52001 "SI REQ APPROVER"
{
    Assignable = true;
    Caption = 'SI Погоджувач заявок';

    IncludedPermissionSets =
        "SI NOTIF USER";

    Permissions =
        tabledata "SI Request Header" = RIM,
        tabledata "SI Request Line" = R,
        tabledata "SI Req. Status Log" = RI,
        tabledata "SI Requester Setup" = R,
        tabledata "SI Construction Object" = R,

        page "SI Request List" = X,
        page "SI Request Card" = X,
        page "SI Request Lines" = X,
        page "SI Req. Status Log Part" = X,

        codeunit "SI Request Status Mgt." = X,

        tabledata "SI My Approvals Cue" = RIM,
        page "SI My Approvals Cues" = X,

        codeunit "SI Req. Notification Mgt." = X,
        codeunit "SI Req. Notif. Navigator" = X,

        tabledata "SI Request Inbox Buffer" = RIMD,
        table "SI Request Inbox Buffer" = X,
        page "SI Request Approver Inbox" = X,
        page "SI Approver Notification Cues" = X,
        codeunit "SI Request Inbox Mgt." = X,

        codeunit "SI Req. Recipient Helper" = X,
        codeunit "SI Req. Requester Resolver" = X,
        codeunit "SI Req. Curr. Appr. Resolver" = X,
        codeunit "SI Req. Next Appr. Resolver" = X;
}