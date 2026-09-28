page 52058 "SI Approver Notification Cues"
{
    Caption = 'Сповіщення';
    PageType = CardPart;
    SourceTable = "SI My Approvals Cue";
    ApplicationArea = All;
    RefreshOnActivate = true;

    layout
    {
        area(Content)
        {
            cuegroup(Notifications)
            {
                Caption = 'Сповіщення';

                field("Unread Approver Notif. Count"; Rec."Unread Approver Notif. Count")
                {
                    ApplicationArea = All;
                    Caption = 'Непрочитані сповіщення';
                    DrillDown = true;
                    ToolTip = 'Показує кількість непрочитаних сповіщень про заявки, адресованих поточному погоджувачу.';

                    trigger OnDrillDown()
                    var
                        ApproverInbox: Page "SI Request Approver Inbox";
                    begin
                        ApproverInbox.SetUnreadOnly();
                        ApproverInbox.Run();
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        InitializeCue();
    end;

    trigger OnAfterGetRecord()
    begin
        ApplyCueFilters();
    end;

    local procedure InitializeCue()
    begin
        if not Rec.Get('MAIN') then begin
            Rec.Init();
            Rec."Primary Key" := 'MAIN';
            Rec.Insert();
        end;

        ApplyCueFilters();
    end;

    local procedure ApplyCueFilters()
    begin
        Rec.SetRange(
            "Recipient Security ID Filter",
            UserSecurityId());

        Rec.SetFilter(
            "Approver Notif. Event Filter",
            '%1|%2',
            RequestSubmittedEventCodeLbl,
            RequestApprovalRequiredEventCodeLbl);

        Rec.CalcFields(
            "Unread Approver Notif. Count");
    end;

    var
        RequestSubmittedEventCodeLbl:
            Label 'REQUEST_SUBMITTED',
            Locked = true;

        RequestApprovalRequiredEventCodeLbl:
            Label 'REQUEST_APPROVAL_REQUIRED',
            Locked = true;
}
