codeunit 50237 "SI Notification Action Mgt."
{
    procedure OpenSourceRecord(
        NotificationEntry: Record "SI Notification Entry")
    var
        IsHandled: Boolean;
    begin
        ValidateNavigationData(NotificationEntry);

        OnOpenSourceRecord(
            NotificationEntry,
            IsHandled);

        if not IsHandled then
            Error(
                NavigationProviderNotFoundErr,
                NotificationEntry."Entry No.",
                NotificationEntry."Source Table ID",
                NotificationEntry."Target Page ID");
    end;

    local procedure ValidateNavigationData(
        NotificationEntry: Record "SI Notification Entry")
    begin
        if NotificationEntry."Target Page ID" = 0 then
            Error(
                TargetPageNotDefinedErr,
                NotificationEntry."Entry No.");

        if NotificationEntry."Source Table ID" = 0 then
            Error(
                SourceTableNotDefinedErr,
                NotificationEntry."Entry No.");

        if NotificationEntry."Source Record ID".TableNo() = 0 then
            Error(
                SourceRecordNotDefinedErr,
                NotificationEntry."Entry No.");

        if NotificationEntry."Source Record ID".TableNo() <>
           NotificationEntry."Source Table ID"
        then
            Error(
                SourceTableMismatchErr,
                NotificationEntry."Entry No.",
                NotificationEntry."Source Table ID",
                NotificationEntry."Source Record ID".TableNo());
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOpenSourceRecord(
        NotificationEntry: Record "SI Notification Entry";
        var IsHandled: Boolean)
    begin
    end;

    var
        TargetPageNotDefinedErr:
            Label 'Для повідомлення %1 не визначено цільову сторінку.';

        SourceTableNotDefinedErr:
            Label 'Для повідомлення %1 не визначено таблицю пов’язаного запису.';

        SourceRecordNotDefinedErr:
            Label 'Для повідомлення %1 не визначено пов’язаний запис.';

        SourceTableMismatchErr:
            Label 'Для повідомлення %1 таблиця джерела %2 не відповідає таблиці запису %3.';

        NavigationProviderNotFoundErr:
            Label 'Для повідомлення %1 не знайдено провайдера навігації для таблиці %2 та сторінки %3.';
}