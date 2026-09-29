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
    begin
        OnWriteIsolated(
            CorrelationID,
            ServiceCode,
            OperationCode,
            ProviderCode,
            EndpointCode,
            RequestURL,
            StartedAt,
            FinishedAt,
            DurationMs,
            HTTPStatusCode,
            ResultType,
            ErrorCode,
            ErrorMessage,
            LogResponseBody,
            ResponseBody);
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
    begin
        ExecLog.Init();
        ExecLog."Correlation ID" := CorrelationID;
        ExecLog."Service Code" := ServiceCode;
        ExecLog."Operation Code" := OperationCode;
        ExecLog."Provider Code" := ProviderCode;
        ExecLog."Endpoint Code" := EndpointCode;
        ExecLog."Request URL" := RequestURL;
        ExecLog."Started At" := StartedAt;
        ExecLog."Finished At" := FinishedAt;
        ExecLog."Duration (ms)" := DurationMs;
        ExecLog."HTTP Status Code" := HTTPStatusCode;
        ExecLog."Result Type" := ResultType;
        ExecLog."Error Code" := ErrorCode;
        ExecLog."Error Message" := ErrorMessage;
        ExecLog.Insert(true);

        if LogResponseBody then begin
            ExecLog.SetResponseBody(ResponseBody);
            ExecLog.Modify(false);
        end;
    end;
}
