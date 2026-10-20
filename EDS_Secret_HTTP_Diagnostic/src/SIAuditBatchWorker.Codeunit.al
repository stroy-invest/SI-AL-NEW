codeunit 70054 "SI Audit Batch Worker"
{
    // Lab-only batch execution. Uses the proven direct RAW GET, never production BP.
    procedure RunSlice(BatchNo: Code[20])
    var
        Batch: Record "SI Audit Batch";
        Entry: Record "SI Audit Entry";
        Processed: Integer;
        Limit: Integer;
        Remaining: Boolean;
    begin
        Batch.Get(BatchNo);
        if Batch.Status = Batch.Status::Stopped then
            exit;
        if Batch.Status = Batch.Status::Completed then
            exit;
        if Batch.Status <> Batch.Status::Ready then
            Error('Пакет %1 має бути у стані Готовий. Якщо попередній запуск перервався, зупиніть і відновіть пакет.', BatchNo);
        Batch.TestField("Batch Size");
        if (Batch."Batch Size" < 1) or (Batch."Batch Size" > 20) then
            Error('Запитів за запуск має бути від 1 до 20.');
        if (Batch."Request Interval Sec." < 1) or (Batch."Request Interval Sec." > 300) then
            Error('Інтервал між запитами має бути від 1 до 300 секунд.');
        Limit := Batch."Batch Size";
        Batch.Status := Batch.Status::Running;
        Batch.Modify(true);
        Commit();

        Entry.Reset();
        Entry.SetRange("Batch No.", BatchNo);
        Entry.SetRange("Processing Status", Entry."Processing Status"::Pending);
        if Entry.FindSet() then
            repeat
                if (Entry."Next Attempt At" = 0DT) or (Entry."Next Attempt At" <= CurrentDateTime()) then begin
                    if not Entry."Is FOP" then begin
                        // A stop requested between requests is honored.
                        Batch.Get(BatchNo);
                        if Batch.Status = Batch.Status::Stopped then
                            exit;
                        if Processed > 0 then
                            Sleep(Batch."Request Interval Sec." * 1000);
                        ProcessEntry(Entry);
                        Processed += 1;
                    end;
                end;
            until (Entry.Next() = 0) or (Processed >= Limit);

        Entry.Reset();
        Entry.SetRange("Batch No.", BatchNo);
        Entry.SetRange("Processing Status", Entry."Processing Status"::Pending);
        Remaining := not Entry.IsEmpty();
        Batch.Get(BatchNo);
        if Batch.Status = Batch.Status::Stopped then
            exit;
        if Remaining then
            Batch.Status := Batch.Status::Ready
        else
            Batch.Status := Batch.Status::Completed;
        Batch.Modify(true);
    end;

    local procedure ProcessEntry(var Entry: Record "SI Audit Entry")
    var
        Log: Record "SI Audit Request Log";
        Response: HttpResponseMessage;
        InS: InStream;
        OutS: OutStream;
        Headers: HttpHeaders;
        Values: List of [Text];
        Value: Text;
        ContentType: Text;
        Success: Boolean;
        Code: Integer;
    begin
        if (StrLen(Entry.EDRPOU) <> 8) or (not IsDigits(Entry.EDRPOU)) then begin
            Entry."Processing Status" := Entry."Processing Status"::Failed;
            Entry."Result Code" := 'INVALID_EDRPOU';
            Entry."Result Details" := 'Очікується 8-значний цифровий ЄДРПОУ.';
            Entry.Modify(true);
            exit;
        end;
        Log.Init();
        Log."Batch No." := Entry."Batch No.";
        Log."Audit Entry No." := Entry."Entry No.";
        Log.EDRPOU := Entry.EDRPOU;
        Log.Code1C := Entry.Code1C;
        Log."Requested At" := CurrentDateTime();
        Log."EDS Provider Code" := 'ADM-TOOLS';
        Log."EDS Operation Code" := 'BATCH-RAW-GET';
        Log."Attempt No." := Entry."Attempt Count" + 1;
        Log."Retrieval Result" := 'STARTED';
        Log.Insert(true);
        Entry."Attempt Count" += 1;
        Entry.Modify(true);
        Commit();

        Clear(Response);
        Success := TryGetRaw(Entry.EDRPOU, Response);
        Log."Completed At" := CurrentDateTime();
        Entry."Last Checked At" := Log."Completed At";
        if not Success then begin
            Log."Retrieval Result" := 'TRANSPORT_ERROR';
            Log."Response Message" := CopyStr(GetLastErrorText(), 1, MaxStrLen(Log."Response Message"));
            Log.Modify(true);
            RetryOrFail(Entry, 'TRANSPORT_ERROR', Log."Response Message");
            exit;
        end;
        Code := Response.HttpStatusCode();
        Log."HTTP Status Code" := Code;
        Response.Content.GetHeaders(Headers);
        if Headers.GetValues('Content-Type', Values) then
            foreach Value in Values do
                ContentType += Value + ' ';
        Log."Response Content Type" := CopyStr(ContentType, 1, MaxStrLen(Log."Response Content Type"));
        if not Response.Content.ReadAs(InS) then begin
            Log."Retrieval Result" := 'READ_FAILED';
            Log.Modify(true);
            RetryOrFail(Entry, 'READ_FAILED', 'Не вдалося отримати HTTP-потік.');
            exit;
        end;
        Log."Raw HTTP Bytes".CreateOutStream(OutS);
        CopyStream(OutS, InS);
        Log."Retrieval Result" := 'RAW_CAPTURED';
        Log.Modify(true);
        Commit(); // Preserve raw evidence even if XML parsing later fails.
        if Code = 429 then begin
            RetryOrFail(Entry, 'HTTP_429', 'Ліміт запитів API; повторити пізніше.');
            exit;
        end;
        if Code >= 500 then begin
            RetryOrFail(Entry, 'HTTP_SERVER_ERROR', StrSubstNo('HTTP %1', Code));
            exit;
        end;
        if not TryMaterialize(Entry, Log) then begin
            Log.Get(Log."Entry No.");
            Log."Verification Result" := 'PARSER_ERROR';
            Log."Response Message" := CopyStr(GetLastErrorText(), 1, MaxStrLen(Log."Response Message"));
            Log.Modify(true);
            RetryOrFail(Entry, 'PARSER_ERROR', Log."Response Message");
        end;
    end;

    [TryFunction]
    local procedure TryGetRaw(EDRPOU: Code[8]; var Response: HttpResponseMessage)
    var
        Client: HttpClient;
    begin
        if not Client.Get('https://adm.tools/action/gov/api/?egrpou=' + EDRPOU, Response) then
            Error('HttpClient.Get повернув false.');
    end;

    [TryFunction]
    local procedure TryMaterialize(var Entry: Record "SI Audit Entry"; var Log: Record "SI Audit Request Log")
    var
        Materializer: Codeunit "SI Audit XML Materializer";
    begin
        Materializer.Process(Entry, Log);
    end;

    local procedure RetryOrFail(var Entry: Record "SI Audit Entry"; ResultCode: Code[30]; Details: Text)
    begin
        Entry."Result Code" := ResultCode;
        Entry."Result Details" := CopyStr(Details, 1, MaxStrLen(Entry."Result Details"));
        if Entry."Attempt Count" >= 3 then begin
            Entry."Processing Status" := Entry."Processing Status"::Failed;
            Entry."Next Attempt At" := 0DT;
        end else begin
            Entry."Processing Status" := Entry."Processing Status"::Pending;
            Entry."Next Attempt At" := CurrentDateTime() + (60 * 1000 * Entry."Attempt Count");
        end;
        Entry.Modify(true);
    end;

    local procedure IsDigits(Value: Text): Boolean
    var I: Integer;
    begin
        for I := 1 to StrLen(Value) do
            if not (Value[I] in ['0' .. '9']) then
                exit(false);
        exit(true);
    end;
}
