codeunit 50464 "SI EDS Audit Logger"
{
    procedure WriteIsolated(
        CorrelationID: Guid;
        ServiceCode: Code[50];
        OperationCode: Code[50];
        ProviderCode: Code[50];
        EndpointCode: Code[50];
        RequestURL: Text;
        StartedAt: DateTime;
        FinishedAt: DateTime;
        DurationMs: Integer;
        HTTPStatusCode: Integer;
        ResultType: Enum "SI EDS Result Type";
        ErrorCode: Code[50];
        ErrorMessage: Text;
        LogResponseBody: Boolean;
        ResponseBody: Text)
    var
        EDSParameter: Record "SI EDS Parameter";
        SafeRequestURL: Text;
        SafeErrorMessage: Text;
        SafeLogResponseBody: Boolean;
        SafeResponseBody: Text;
        QueryPosition: Integer;
    begin
        // C7 Fix 4: sanitize BEFORE raising the integration event.
        // Every subscriber must receive the same redacted payload.
        SafeRequestURL := RequestURL;
        SafeErrorMessage := ErrorMessage;
        SafeLogResponseBody := LogResponseBody;
        SafeResponseBody := ResponseBody;

        EDSParameter.SetRange("Service Code", ServiceCode);
        EDSParameter.SetRange("Operation Code", OperationCode);
        EDSParameter.SetRange(Location, EDSParameter.Location::Query);
        EDSParameter.SetRange(Source, EDSParameter.Source::Credential);
        EDSParameter.SetRange(Enabled, true);

        if not EDSParameter.IsEmpty() then begin
            QueryPosition := StrPos(SafeRequestURL, '?');
            if QueryPosition > 0 then
                SafeRequestURL := CopyStr(SafeRequestURL, 1, QueryPosition - 1) + '?[REDACTED]'
            else
                SafeRequestURL := '[REDACTED]';
            SafeErrorMessage := 'EDS Query Credential: details suppressed.';
            SafeLogResponseBody := false;
            SafeResponseBody := '';
        end;

        OnWriteIsolated(
            CorrelationID,
            ServiceCode,
            OperationCode,
            ProviderCode,
            EndpointCode,
            SafeRequestURL,
            StartedAt,
            FinishedAt,
            DurationMs,
            HTTPStatusCode,
            ResultType,
            ErrorCode,
            SafeErrorMessage,
            SafeLogResponseBody,
            SafeResponseBody);
    end;

    [IntegrationEvent(false, false, true)]
    local procedure OnWriteIsolated(
        CorrelationID: Guid;
        ServiceCode: Code[50];
        OperationCode: Code[50];
        ProviderCode: Code[50];
        EndpointCode: Code[50];
        RequestURL: Text;
        StartedAt: DateTime;
        FinishedAt: DateTime;
        DurationMs: Integer;
        HTTPStatusCode: Integer;
        ResultType: Enum "SI EDS Result Type";
        ErrorCode: Code[50];
        ErrorMessage: Text;
        LogResponseBody: Boolean;
        ResponseBody: Text)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SI EDS Audit Logger", 'OnWriteIsolated', '', false, false)]
    local procedure PersistLog(
        CorrelationID: Guid;
        ServiceCode: Code[50];
        OperationCode: Code[50];
        ProviderCode: Code[50];
        EndpointCode: Code[50];
        RequestURL: Text;
        StartedAt: DateTime;
        FinishedAt: DateTime;
        DurationMs: Integer;
        HTTPStatusCode: Integer;
        ResultType: Enum "SI EDS Result Type";
        ErrorCode: Code[50];
        ErrorMessage: Text;
        LogResponseBody: Boolean;
        ResponseBody: Text)
    var
        ExecLog: Record "SI EDS Exec. Log";
        EDSParameter: Record "SI EDS Parameter";
        SafeRequestURL: Text;
        SafeErrorMessage: Text;
        SafeLogResponseBody: Boolean;
        QueryPosition: Integer;
    begin
        // C6: persistence boundary defense-in-depth. The orchestrator
        // already redacts, but any future caller of WriteIsolated must
        // not be able to persist a query credential's URL or response.
        SafeRequestURL := RequestURL;
        SafeErrorMessage := ErrorMessage;
        SafeLogResponseBody := LogResponseBody;

        EDSParameter.SetRange("Service Code", ServiceCode);
        EDSParameter.SetRange("Operation Code", OperationCode);
        EDSParameter.SetRange(Location, EDSParameter.Location::Query);
        EDSParameter.SetRange(Source, EDSParameter.Source::Credential);
        EDSParameter.SetRange(Enabled, true);

        // Conservative operation-level rule: routing may select a
        // provider dynamically; do not rely on ProviderCode being present.
        if not EDSParameter.IsEmpty() then begin
            QueryPosition := StrPos(SafeRequestURL, '?');
            if QueryPosition > 0 then
                SafeRequestURL := CopyStr(SafeRequestURL, 1, QueryPosition - 1) + '?[REDACTED]'
            else
                SafeRequestURL := '[REDACTED]';
            SafeErrorMessage := 'EDS Query Credential: details suppressed.';
            SafeLogResponseBody := false;
        end;

        ExecLog.Init();
        ExecLog."Correlation ID" := CorrelationID;
        ExecLog."Service Code" := ServiceCode;
        ExecLog."Operation Code" := OperationCode;
        ExecLog."Provider Code" := ProviderCode;
        ExecLog."Endpoint Code" := EndpointCode;
        ExecLog."Request URL" := SafeRequestURL;
        ExecLog."Started At" := StartedAt;
        ExecLog."Finished At" := FinishedAt;
        ExecLog."Duration (ms)" := DurationMs;
        ExecLog."HTTP Status Code" := HTTPStatusCode;
        ExecLog."Result Type" := ResultType;
        ExecLog."Error Code" := ErrorCode;
        ExecLog."Error Message" := SafeErrorMessage;
        ExecLog.Insert(true);

        if SafeLogResponseBody then begin
            ExecLog.SetResponseBody(ResponseBody);
            ExecLog.Modify(false);
        end;
    end;
}
