page 50258 "SI My Notifications"
{
    Caption = 'Мої сповіщення';
    PageType = List;
    SourceTable = "SI Notification Entry";
    UsageCategory = Lists;
    ApplicationArea = All;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Notifications)
            {
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає, чи було повідомлення прочитано.';
                }

                field(Title; Rec.Title)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає заголовок повідомлення.';
                }

                field(Message; Rec.Message)
                {
                    ApplicationArea = All;
                    MultiLine = true;
                    ToolTip = 'Визначає текст повідомлення.';
                }

                field(Severity; Rec.Severity)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає рівень важливості повідомлення.';
                }

                field("Created At"; Rec."Created At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає дату й час створення повідомлення.';
                }

                field("Source Record Caption"; Rec."Source Record Caption")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає пов’язаний бізнес-запис.';
                }

                field("Action Caption"; Rec."Action Caption")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає назву доступної дії переходу.';
                }

                field("Read At"; Rec."Read At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає дату й час прочитання повідомлення.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OpenNotification)
            {
                Caption = 'Відкрити';
                ApplicationArea = All;
                Image = Navigate;
                // Enabled = Rec."Target Page ID" <> 0;
                ToolTip = 'Відкриває пов’язаний бізнес-запис і позначає повідомлення прочитаним.';

                trigger OnAction()
                var
                    NotificationLifecycleMgt: Codeunit "SI Notif. Lifecycle Mgt.";
                begin
                    NotificationLifecycleMgt.OpenAndMarkAsRead(Rec);
                    CurrPage.Update(false);
                end;
            }

            action(MarkAsRead)
            {
                Caption = 'Позначити прочитаним';
                ApplicationArea = All;
                Image = Approve;
                Enabled = Rec.Status = Rec.Status::Unread;
                ToolTip = 'Позначає вибране повідомлення прочитаним.';

                trigger OnAction()
                var
                    NotificationLifecycleMgt: Codeunit "SI Notif. Lifecycle Mgt.";
                begin
                    NotificationLifecycleMgt.MarkAsRead(Rec);
                    CurrPage.Update(false);
                end;
            }

            action(MarkAsUnread)
            {
                Caption = 'Позначити непрочитаним';
                ApplicationArea = All;
                Image = Undo;
                Enabled = Rec.Status = Rec.Status::Read;
                ToolTip = 'Повертає вибране повідомлення до статусу непрочитаного.';

                trigger OnAction()
                var
                    NotificationLifecycleMgt: Codeunit "SI Notif. Lifecycle Mgt.";
                begin
                    NotificationLifecycleMgt.MarkAsUnread(Rec);
                    CurrPage.Update(false);
                end;
            }

            action(DismissNotification)
            {
                Caption = 'Приховати';
                ApplicationArea = All;
                Image = Delete;
                ToolTip = 'Приховує вибране повідомлення зі списку особистих сповіщень.';

                trigger OnAction()
                var
                    NotificationLifecycleMgt: Codeunit "SI Notif. Lifecycle Mgt.";
                begin
                    if not Confirm(
                        DismissConfirmQst,
                        false,
                        Rec.Title)
                    then
                        exit;

                    NotificationLifecycleMgt.Dismiss(Rec);

                    CurrPage.Update(false);
                end;
            }
        }

        area(Promoted)
        {
            actionref(OpenNotificationPromoted; OpenNotification)
            {
            }

            actionref(MarkAsReadPromoted; MarkAsRead)
            {
            }

            actionref(DismissNotificationPromoted; DismissNotification)
            {
            }
        }
    }

    trigger OnOpenPage()
    begin
        ApplyUserFilters();

        Rec.SetCurrentKey("Created At");
        Rec.Ascending(false);
    end;

    local procedure ApplyUserFilters()
    begin
        Rec.FilterGroup(2);

        Rec.SetRange(
            "Recipient Security ID",
            UserSecurityId());

        Rec.SetFilter(
            Status,
            '<>%1',
            Rec.Status::Dismissed);

        Rec.FilterGroup(0);
    end;

    var
        DismissConfirmQst:
            Label 'Приховати повідомлення «%1»?';
}