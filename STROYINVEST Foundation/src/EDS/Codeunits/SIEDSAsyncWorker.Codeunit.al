codeunit 50467 "SI EDS Async Worker"
{
    Permissions =
        tabledata "SI EDS Async Request" = RIMD,
        tabledata "SI EDS Async Param" = R;

    trigger OnRun()
    begin
        // Standard Job Queue recurrence is minute-based. Running this worker every minute
        // and making a second pass after 30 seconds gives the agreed 30-second cadence.
        ProcessDue();
        Sleep(30000);
        ProcessDue();
    end;

    procedure ProcessDue()
    var
        AsyncRequest: Record "SI EDS Async Request";
        NowAt: DateTime;
    begin
        NowAt := CurrentDateTime;
        AsyncRequest.SetRange(Status, AsyncRequest.Status::Pending);
        AsyncRequest.SetFilter("Next Attempt At", '<=%1', NowAt);
        if AsyncRequest.FindSet() then
            repeat
                ProcessOne(AsyncRequest."Entry No.");
            until AsyncRequest.Next() = 0;
    end;

    local procedure ProcessOne(EntryNo: Integer)
    var
        AsyncRequest: Record "SI EDS Async Request";
    begin
        if not AsyncRequest.Get(EntryNo) then
            exit;
        if AsyncRequest.Status <> AsyncRequest.Status::Pending then
            exit;

        if CurrentDateTime >= AsyncRequest."Expires At" then begin
            AsyncRequest.Status := AsyncRequest.Status::"Timed Out";
            AsyncRequest."Next Attempt At" := 0DT;
            AsyncRequest."Error Message" := 'EDS async request exceeded the configured 1-hour provider timeout.';
            AsyncRequest.Modify();
            exit;
        end;

        if not TryExecute(AsyncRequest) then begin
            AsyncRequest.Get(EntryNo);
            AsyncRequest.Status := AsyncRequest.Status::Error;
            AsyncRequest."Next Attempt At" := 0DT;
            AsyncRequest."Error Message" := CopyStr(GetLastErrorText(), 1, MaxStrLen(AsyncRequest."Error Message"));
            AsyncRequest.Modify();
        end;
    end;

    [TryFunction]
    local procedure TryExecute(var AsyncRequest: Record "SI EDS Async Request")
    var
        AsyncParam: Record "SI EDS Async Param";
        RuntimeParam: Record "SI EDS Runtime Param" temporary;
        ResponseBuffer: Record "SI EDS Response Buffer" temporary;
        EDSOrchestrator: Codeunit "SI EDS Orchestrator";
        AgeMs: Duration;
        EDSOperation: Record "SI EDS Operation";
        MaxAttempts: Integer;
    begin
        if not EDSOperation.Get(AsyncRequest."Service Code", AsyncRequest."Operation Code") then
            Error(
                'EDS operation %1/%2 no longer exists. Async retry was stopped before an HTTP request was sent.',
                AsyncRequest."Service Code",
                AsyncRequest."Operation Code");

        if EDSOperation."Async Retry Mode" <> EDSOperation."Async Retry Mode"::"Repeat Same Operation" then
            Error(
                'Automatic retry after HTTP 202 is not allowed for EDS operation %1/%2. Configure an explicit async retry policy before enabling the worker for this operation.',
                AsyncRequest."Service Code",
                AsyncRequest."Operation Code");

        MaxAttempts := EDSOperation."Async Max Attempts";
        if MaxAttempts <= 0 then
            MaxAttempts := 10;

        if AsyncRequest."Attempt Count" >= MaxAttempts then
            Error(
                'EDS async request reached the configured maximum of %1 background attempts. No further HTTP request was sent.',
                MaxAttempts);

        AsyncParam.SetRange("Request Entry No.", AsyncRequest."Entry No.");
        if AsyncParam.FindSet() then
            repeat
                RuntimeParam.Add(AsyncParam.Code, AsyncParam.Value);
            until AsyncParam.Next() = 0;

        EDSOrchestrator.Execute(
            AsyncRequest."Service Code",
            AsyncRequest."Operation Code",
            RuntimeParam,
            ResponseBuffer);

        if not ResponseBuffer.FindFirst() then
            Error('EDS did not return Response Buffer.');

        AsyncRequest."Attempt Count" += 1;
        AsyncRequest."Last Attempt At" := CurrentDateTime;
        AsyncRequest."Provider Code" := ResponseBuffer."Provider Code";
        AsyncRequest."HTTP Status Code" := ResponseBuffer."HTTP Status Code";
        AsyncRequest."HTTP Reason Phrase" := ResponseBuffer."HTTP Reason Phrase";
        AsyncRequest."Error Message" := CopyStr(ResponseBuffer."Error Message", 1, MaxStrLen(AsyncRequest."Error Message"));

        case ResponseBuffer."HTTP Status Code" of
            200:
                begin
                    AsyncRequest.SetResponseBody(ResponseBuffer.GetBodyText());
                    AsyncRequest.Status := AsyncRequest.Status::Completed;
                    AsyncRequest."Completed At" := CurrentDateTime;
                    AsyncRequest."Next Attempt At" := 0DT;
                end;
            202:
                begin
                    if AsyncRequest."Attempt Count" >= MaxAttempts then begin
                        AsyncRequest.Status := AsyncRequest.Status::Error;
                        AsyncRequest."Next Attempt At" := 0DT;
                        AsyncRequest."Error Message" :=
                            CopyStr(
                                StrSubstNo(
                                    'HTTP 202 persisted for %1 background attempts. Retry limit reached; automatic requests were stopped.',
                                    MaxAttempts),
                                1,
                                MaxStrLen(AsyncRequest."Error Message"));
                    end else
                        if CurrentDateTime >= AsyncRequest."Expires At" then begin
                            AsyncRequest.Status := AsyncRequest.Status::"Timed Out";
                            AsyncRequest."Next Attempt At" := 0DT;
                        end else begin
                            AgeMs := CurrentDateTime - AsyncRequest."Started At";
                            if AgeMs < 600000 then
                                AsyncRequest."Next Attempt At" := CurrentDateTime + 30000
                            else
                                AsyncRequest."Next Attempt At" := CurrentDateTime + 120000;
                        end;
                end;
            else
                begin
                    AsyncRequest.Status := AsyncRequest.Status::Error;
                    AsyncRequest."Next Attempt At" := 0DT;
                    if AsyncRequest."Error Message" = '' then
                        AsyncRequest."Error Message" :=
                            CopyStr(
                                StrSubstNo('Unexpected HTTP status %1 %2.', ResponseBuffer."HTTP Status Code", ResponseBuffer."HTTP Reason Phrase"),
                                1,
                                MaxStrLen(AsyncRequest."Error Message"));
                end;
        end;
        AsyncRequest.Modify();
    end;

}
