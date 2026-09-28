page 52056 "SI Requester Notif. Inbox"
{
    Caption = 'Сповіщення за моїми заявками';
    PageType = List;
    SourceTable = "SI Request Inbox Buffer";
    SourceTableTemporary = true;

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
            repeater(Inbox)
            {
                field(Message; Rec.Message)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає повідомлення про заявку.';
                }

                field("Request Status"; Rec."Request Status")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає поточний статус заявки.';
                }

                field("Execution Date"; Rec."Execution Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає дату виконання заявки.';
                }

                field("Received At"; Rec."Received At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає дату й час надходження повідомлення.';
                }

                field("Current Approver Name"; Rec."Current Approver Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає погоджувача, у якого заявка зараз перебуває на погодженні.';
                }

                field("Final Approver Name"; Rec."Final Approver Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає погоджувача, який виконав остаточну дію із заявкою.';
                }

                field("Is Read"; Rec."Is Read")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає, чи було повідомлення переглянуто.';
                }

                field("Is Hidden"; Rec."Is Hidden")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає, чи було повідомлення приховано.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OpenRequest)
            {
                Caption = 'Відкрити';
                ApplicationArea = All;
                Image = Navigate;
                ToolTip = 'Відкриває пов’язану заявку та позначає повідомлення прочитаним.';

                trigger OnAction()
                var
                    NotificationEntry: Record "SI Notification Entry";
                    NotificationLifecycleMgt: Codeunit "SI Notif. Lifecycle Mgt.";
                begin
                    GetNotificationEntry(
                        NotificationEntry);

                    NotificationLifecycleMgt.OpenAndMarkAsRead(
                        NotificationEntry);

                    RefreshInboxState(
                        NotificationEntry);
                end;
            }

            action(MarkAsRead)
            {
                Caption = 'Позначити прочитаним';
                ApplicationArea = All;
                ToolTip = 'Позначає вибране повідомлення як прочитане.';

                trigger OnAction()
                var
                    NotificationEntry: Record "SI Notification Entry";
                    NotificationLifecycleMgt: Codeunit "SI Notif. Lifecycle Mgt.";
                begin
                    GetNotificationEntry(
                        NotificationEntry);

                    NotificationLifecycleMgt.MarkAsRead(
                        NotificationEntry);

                    RefreshInboxState(
                        NotificationEntry);
                end;
            }

            action(MarkAsUnread)
            {
                Caption = 'Позначити непрочитаним';
                ApplicationArea = All;
                ToolTip = 'Позначає вибране повідомлення як непрочитане.';

                trigger OnAction()
                var
                    NotificationEntry: Record "SI Notification Entry";
                    NotificationLifecycleMgt: Codeunit "SI Notif. Lifecycle Mgt.";
                begin
                    GetNotificationEntry(
                        NotificationEntry);

                    NotificationLifecycleMgt.MarkAsUnread(
                        NotificationEntry);

                    RefreshInboxState(
                        NotificationEntry);
                end;
            }

            action(HideNotification)
            {
                Caption = 'Приховати';
                ApplicationArea = All;
                ToolTip = 'Приховує вибране повідомлення з основного списку.';

                trigger OnAction()
                var
                    NotificationEntry: Record "SI Notification Entry";
                    NotificationLifecycleMgt: Codeunit "SI Notif. Lifecycle Mgt.";
                begin
                    GetNotificationEntry(
                        NotificationEntry);

                    NotificationLifecycleMgt.Dismiss(
                        NotificationEntry);

                    RefreshInboxState(
                        NotificationEntry);
                end;
            }

            action(ShowHidden)
            {
                Caption = 'Показати приховані';
                ApplicationArea = All;
                Image = ShowList;
                Visible = not ShowHiddenEntries;
                ToolTip = 'Показує в списку також приховані повідомлення.';

                trigger OnAction()
                begin
                    ShowHiddenEntries := true;

                    ApplyHiddenFilter();

                    CurrPage.Update(false);
                end;
            }

            action(HideHidden)
            {
                Caption = 'Не показувати приховані';
                ApplicationArea = All;
                Image = FilterLines;
                Visible = ShowHiddenEntries;
                ToolTip = 'Приховує зі списку повідомлення, позначені як приховані.';

                trigger OnAction()
                begin
                    ShowHiddenEntries := false;

                    ApplyHiddenFilter();

                    CurrPage.Update(false);
                end;
            }
        }

        area(Promoted)
        {
            actionref(OpenRequestPromoted; OpenRequest)
            {
            }

            actionref(MarkAsReadPromoted; MarkAsRead)
            {
            }

            actionref(MarkAsUnreadPromoted; MarkAsUnread)
            {
            }

            actionref(HideNotificationPromoted; HideNotification)
            {
            }

            actionref(ShowHiddenPromoted; ShowHidden)
            {
            }

            actionref(HideHiddenPromoted; HideHidden)
            {
            }
        }
    }

    trigger OnOpenPage()
    var
        RequestInboxMgt: Codeunit "SI Request Inbox Mgt.";
    begin
        RequestInboxMgt.LoadRequesterNotificationInbox(Rec);

        Rec.SetCurrentKey("Received At");
        Rec.Ascending(false);

        ShowHiddenEntries := false;
        ApplyHiddenFilter();

        if ShowUnreadOnly then
            Rec.SetRange(
                "Is Read",
                false);

        if Rec.FindFirst() then;
    end;

    procedure SetUnreadOnly()
    begin
        ShowUnreadOnly := true;
    end;

    local procedure GetNotificationEntry(
        var NotificationEntry: Record "SI Notification Entry")
    begin
        if not NotificationEntry.Get(
            Rec."Notification Entry No.")
        then
            Error(
                NotificationNotFoundErr,
                Rec."Notification Entry No.");
    end;

    local procedure RefreshInboxState(
        NotificationEntry: Record "SI Notification Entry")
    begin
        Rec."Is Read" :=
            NotificationEntry."Read At" <> 0DT;

        Rec."Is Hidden" :=
            NotificationEntry."Dismissed At" <> 0DT;

        Rec.Modify();

        CurrPage.Update(false);
    end;

    local procedure ApplyHiddenFilter()
    begin
        if ShowHiddenEntries then
            Rec.SetRange("Is Hidden")
        else
            Rec.SetRange(
                "Is Hidden",
                false);
    end;

    var
        ShowHiddenEntries: Boolean;
        ShowUnreadOnly: Boolean;

        NotificationNotFoundErr:
            Label 'Повідомлення %1 не знайдено.';
}