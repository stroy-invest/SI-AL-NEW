codeunit 61063 "SI Supply Req Audit Mgt"
{
    // The audit writer participates in the caller's transaction.
    // No COMMIT, no background sessions, no suppression of insert errors.
    Permissions = tabledata "SI Supply Req Event Log" = i;

    procedure LogEvent(RequestNo: Code[20]; EventType: Enum "SI Supply Req Event Type"; FieldName: Text; OldValue: Text; NewValue: Text; Reason: Text; Details: Text; CorrelationId: Guid)
    var
        EventLog: Record "SI Supply Req Event Log";
    begin
        if RequestNo = '' then
            Error('Неможливо записати подію без номера заявки.');

        EventLog.Init();
        EventLog."Request No." := RequestNo;
        EventLog."Event Type" := EventType;
        EventLog."Event At" := CurrentDateTime();
        EventLog."User ID" := CopyStr(UserId(), 1, MaxStrLen(EventLog."User ID"));
        EventLog."Field Name" := CopyStr(FieldName, 1, MaxStrLen(EventLog."Field Name"));
        EventLog."Old Value" := CopyStr(OldValue, 1, MaxStrLen(EventLog."Old Value"));
        EventLog."New Value" := CopyStr(NewValue, 1, MaxStrLen(EventLog."New Value"));
        EventLog.Reason := CopyStr(Reason, 1, MaxStrLen(EventLog.Reason));
        EventLog.Details := CopyStr(Details, 1, MaxStrLen(EventLog.Details));
        if IsNullGuid(CorrelationId) then
            CorrelationId := CreateGuid();
        EventLog."Correlation ID" := CorrelationId;
        EventLog.Insert(true);
    end;

    procedure NewCorrelationId(): Guid
    begin
        exit(CreateGuid());
    end;
}
