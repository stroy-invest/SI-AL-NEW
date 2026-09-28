codeunit 50238 "SI Notif. Lifecycle Mgt."
{
    Permissions =
        tabledata "SI Notification Entry" = RM;

    procedure MarkAsRead(
        var NotificationEntry: Record "SI Notification Entry")
    begin
        ValidateCurrentUserRecipient(NotificationEntry);

        if NotificationEntry.Status =
           NotificationEntry.Status::Dismissed
        then
            Error(
                DismissedNotificationErr,
                NotificationEntry."Entry No.");

        if NotificationEntry.Status =
           NotificationEntry.Status::Read
        then
            exit;

        NotificationEntry.Status :=
            NotificationEntry.Status::Read;

        NotificationEntry."Read At" :=
            CurrentDateTime();

        NotificationEntry.Modify(true);
    end;

    procedure MarkAsUnread(
        var NotificationEntry: Record "SI Notification Entry")
    begin
        ValidateCurrentUserRecipient(NotificationEntry);

        if NotificationEntry.Status =
           NotificationEntry.Status::Dismissed
        then
            Error(
                DismissedNotificationErr,
                NotificationEntry."Entry No.");

        if NotificationEntry.Status =
           NotificationEntry.Status::Unread
        then
            exit;

        NotificationEntry.Status :=
            NotificationEntry.Status::Unread;

        Clear(NotificationEntry."Read At");

        NotificationEntry.Modify(true);
    end;

    procedure Dismiss(
        var NotificationEntry: Record "SI Notification Entry")
    begin
        ValidateCurrentUserRecipient(NotificationEntry);

        if NotificationEntry.Status =
           NotificationEntry.Status::Dismissed
        then
            exit;

        NotificationEntry.Status :=
            NotificationEntry.Status::Dismissed;

        NotificationEntry."Dismissed At" :=
            CurrentDateTime();

        if NotificationEntry."Read At" = 0DT then
            NotificationEntry."Read At" :=
                CurrentDateTime();

        NotificationEntry.Modify(true);
    end;

    procedure OpenAndMarkAsRead(
        var NotificationEntry: Record "SI Notification Entry")
    var
        NotificationActionMgt: Codeunit "SI Notification Action Mgt.";
    begin
        ValidateCurrentUserRecipient(NotificationEntry);

        NotificationActionMgt.OpenSourceRecord(
            NotificationEntry);

        if NotificationEntry.Status =
           NotificationEntry.Status::Unread
        then
            MarkAsRead(NotificationEntry);
    end;

    local procedure ValidateCurrentUserRecipient(
        NotificationEntry: Record "SI Notification Entry")
    begin
        if IsNullGuid(
            NotificationEntry."Recipient Security ID")
        then
            Error(
                RecipientNotDefinedErr,
                NotificationEntry."Entry No.");

        if NotificationEntry."Recipient Security ID" <>
           UserSecurityId()
        then
            Error(
                AccessDeniedErr,
                NotificationEntry."Entry No.");
    end;

    var
        DismissedNotificationErr:
            Label 'Повідомлення %1 уже приховано. Його статус не можна змінити.';

        RecipientNotDefinedErr:
            Label 'Для повідомлення %1 не визначено отримувача.';

        AccessDeniedErr:
            Label 'Ви не можете змінювати повідомлення %1, оскільки воно призначене іншому користувачу.';
}