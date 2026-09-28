page 52057 "SI Requester Notification Cues"
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

                field("Unread Request Notif. Count"; Rec."Unread Request Notif. Count")
                {
                    ApplicationArea = All;
                    Caption = 'Непрочитані сповіщення';
                    DrillDown = true;
                    ToolTip = 'Показує кількість непрочитаних сповіщень за заявками поточного користувача.';

                    trigger OnDrillDown()
                    var
                        RequesterNotifInbox: Page "SI Requester Notif. Inbox";
                    begin
                        RequesterNotifInbox.SetUnreadOnly();
                        RequesterNotifInbox.Run();
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
            "Requester Notif. Event Filter",
            '%1|%2|%3',
            RequestApprovedEventCodeLbl,
            RequestReturnedEventCodeLbl,
            RequestRejectedEventCodeLbl);

        Rec.CalcFields(
            "Unread Request Notif. Count");
    end;

    var
        RequestApprovedEventCodeLbl:
            Label 'REQUEST_APPROVED',
            Locked = true;

        RequestReturnedEventCodeLbl:
            Label 'REQUEST_RETURNED',
            Locked = true;

        RequestRejectedEventCodeLbl:
            Label 'REQUEST_REJECTED',
            Locked = true;
}