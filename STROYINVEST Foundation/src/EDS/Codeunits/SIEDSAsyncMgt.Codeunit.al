codeunit 50466 "SI EDS Async Mgt."
{
    Permissions =
        tabledata "SI EDS Async Request" = RIMD,
        tabledata "SI EDS Async Param" = RIMD;

    procedure Enqueue(
        ServiceCode: Code[50];
        OperationCode: Code[50];
        BusinessKey: Text;
        StartedAt: DateTime;
        var RuntimeParam: Record "SI EDS Runtime Param" temporary): Integer
    var
        AsyncRequest: Record "SI EDS Async Request";
        AsyncParam: Record "SI EDS Async Param";
        Operation: Record "SI EDS Operation";
        LineNo: Integer;
    begin
        if not Operation.Get(ServiceCode, OperationCode) then
            Error('EDS operation %1/%2 does not exist.', ServiceCode, OperationCode);

        if Operation."Async Retry Mode" = Operation."Async Retry Mode"::None then
            Error(
                'EDS operation %1/%2 has no safe automatic retry policy. The request was not added to the async queue.',
                ServiceCode,
                OperationCode);

        AsyncRequest.SetRange("Service Code", ServiceCode);
        AsyncRequest.SetRange("Operation Code", OperationCode);
        AsyncRequest.SetRange("Business Key", CopyStr(BusinessKey, 1, MaxStrLen(AsyncRequest."Business Key")));
        AsyncRequest.SetRange(Status, AsyncRequest.Status::Pending);
        if AsyncRequest.FindFirst() then
            exit(AsyncRequest."Entry No.");

        AsyncRequest.Init();
        AsyncRequest."Service Code" := ServiceCode;
        AsyncRequest."Operation Code" := OperationCode;
        AsyncRequest."Business Key" := CopyStr(BusinessKey, 1, MaxStrLen(AsyncRequest."Business Key"));
        AsyncRequest.Status := AsyncRequest.Status::Pending;
        AsyncRequest."Started At" := StartedAt;
        AsyncRequest."Next Attempt At" := CurrentDateTime + 30000;
        AsyncRequest."Expires At" := StartedAt + 3600000;
        AsyncRequest.Insert(true);

        RuntimeParam.Reset();
        if RuntimeParam.FindSet() then
            repeat
                AssertSafeAsyncParameter(ServiceCode, OperationCode, RuntimeParam.Code);
                LineNo += 10000;
                AsyncParam.Init();
                AsyncParam."Request Entry No." := AsyncRequest."Entry No.";
                AsyncParam."Line No." := LineNo;
                AsyncParam.Code := RuntimeParam.Code;
                AsyncParam.Value := RuntimeParam.Value;
                AsyncParam.Insert();
            until RuntimeParam.Next() = 0;

        exit(AsyncRequest."Entry No.");
    end;

    // Fail closed: credential-sourced parameters must be resolved at execution,
    // never copied into the persistent async parameter table.
    local procedure AssertSafeAsyncParameter(ServiceCode: Code[50]; OperationCode: Code[50]; RuntimeCode: Code[50])
    var
        EDSParameter: Record "SI EDS Parameter";
    begin
        EDSParameter.SetRange("Service Code", ServiceCode);
        EDSParameter.SetRange("Operation Code", OperationCode);
        EDSParameter.SetRange(Source, EDSParameter.Source::Credential);
        EDSParameter.SetRange(Enabled, true);
        if EDSParameter.FindSet() then
            repeat
                if (RuntimeCode = EDSParameter.Code) or
                   ((EDSParameter."Credential Code" <> '') and (RuntimeCode = EDSParameter."Credential Code")) then
                    Error('EDS async parameter conflicts with a configured credential. Request not queued.');
            until EDSParameter.Next() = 0;
    end;
}
