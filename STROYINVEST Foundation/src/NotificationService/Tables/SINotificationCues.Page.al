page 50259 "SI Notification Cues"
{
    Caption = 'Сповіщення';
    PageType = CardPart;
    SourceTable = "SI Notification Cue";
    RefreshOnActivate = true;

    layout
    {
        area(Content)
        {
            cuegroup(Notifications)
            {
                Caption = 'Сповіщення';

                field("Unread Notifications"; Rec."Unread Notifications")
                {
                    ApplicationArea = All;
                    Caption = 'Непрочитані сповіщення';
                    DrillDown = true;
                    ToolTip = 'Показує кількість непрочитаних сповіщень поточного користувача.';

                    trigger OnDrillDown()
                    var
                        NotificationEntry: Record "SI Notification Entry";
                    begin
                        NotificationEntry.SetRange(
                            "Recipient Security ID",
                            UserSecurityId());

                        NotificationEntry.SetRange(
                            Status,
                            NotificationEntry.Status::Unread);

                        Page.Run(
                            Page::"SI My Notifications",
                            NotificationEntry);
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
        ApplyUserFilter();
    end;

    local procedure InitializeCue()
    begin
        if not Rec.Get('USER') then begin
            Rec.Init();
            Rec."Primary Key" := 'USER';
            Rec.Insert();
        end;

        ApplyUserFilter();
    end;

    local procedure ApplyUserFilter()
    begin
        Rec.SetRange(
            "Recipient Security ID Filter",
            UserSecurityId());

        Rec.CalcFields(
            "Unread Notifications");
    end;
}