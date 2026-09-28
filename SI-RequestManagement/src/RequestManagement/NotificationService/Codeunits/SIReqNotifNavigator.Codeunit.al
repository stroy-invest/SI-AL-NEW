codeunit 52041 "SI Req. Notif. Navigator"
{
    [EventSubscriber(
        ObjectType::Codeunit,
        Codeunit::"SI Notification Action Mgt.",
        'OnOpenSourceRecord',
        '',
        false,
        false)]
    local procedure OnOpenSourceRecord(
        NotificationEntry: Record "SI Notification Entry";
        var IsHandled: Boolean)
    var
        RequestHeader: Record "SI Request Header";
        SourceRecordRef: RecordRef;
    begin
        if IsHandled then
            exit;

        if NotificationEntry."Source Table ID" <>
           Database::"SI Request Header"
        then
            exit;

        SourceRecordRef.Get(
            NotificationEntry."Source Record ID");

        SourceRecordRef.SetTable(
            RequestHeader);

        Page.Run(
            Page::"SI Request Card",
            RequestHeader);

        IsHandled := true;
    end;
}