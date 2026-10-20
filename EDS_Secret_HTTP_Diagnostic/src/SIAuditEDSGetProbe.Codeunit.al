codeunit 70051 "SI Audit EDS GET Probe"
{
    // Step 3: deliberately ONE request, no batch worker and no BP writes.
    procedure ExecuteOne(var AuditEntry: Record "SI Audit Entry")
    var
        Batch: Record "SI Audit Batch";
        RuntimeParam: Record "SI EDS Runtime Param" temporary;
        ResponseBuffer: Record "SI EDS Response Buffer" temporary;
        LogEntry: Record "SI Audit Request Log";
        EDS: Codeunit "SI EDS Orchestrator";
        BodyStream: InStream;
        Materializer: Codeunit "SI Audit XML Materializer";
        OutStr: OutStream;
        RawBytes: InStream;
        RawOut: OutStream;
    begin
        AuditEntry.TestField("Batch No.");
        AuditEntry.TestField(EDRPOU);
        if AuditEntry."Is FOP" or (AuditEntry."Processing Status" = AuditEntry."Processing Status"::Skipped) then
            Error('Пропущені записи та ФОП не перевіряємо.');
        if StrLen(AuditEntry.EDRPOU) <> 8 then
            Error('ЄДРПОУ має складатися з 8 цифр.');
        if not IsDigits(AuditEntry.EDRPOU) then
            Error('ЄДРПОУ містить нецифрові символи.');
        Batch.Get(AuditEntry."Batch No.");
        Batch.TestField("Provider Code");
        Batch.TestField("EDS Service Code");
        Batch.TestField("EDS Operation Code");
        Batch.TestField("EDS Runtime Key");

        LogEntry.Init();
        LogEntry."Batch No." := AuditEntry."Batch No.";
        LogEntry."Audit Entry No." := AuditEntry."Entry No.";
        LogEntry.EDRPOU := AuditEntry.EDRPOU;
        LogEntry.Code1C := AuditEntry.Code1C;
        LogEntry."Requested At" := CurrentDateTime();
        LogEntry."EDS Provider Code" := Batch."Provider Code";
        LogEntry."EDS Operation Code" := Batch."EDS Operation Code";
        LogEntry."Attempt No." := AuditEntry."Attempt Count" + 1;
        LogEntry."Retrieval Result" := 'STARTED';
        LogEntry.Insert(true);
        Commit(); // keep audit evidence if EDS fails with an AL Error

        RuntimeParam.Add(Batch."EDS Runtime Key", AuditEntry.EDRPOU);
        EDS.ExecuteProviderBody(Batch."EDS Service Code", Batch."EDS Operation Code",
            Batch."Provider Code", RuntimeParam, '', '', 'application/xml', ResponseBuffer);

        LogEntry."Completed At" := CurrentDateTime();
        if ResponseBuffer.FindFirst() then begin
            LogEntry."HTTP Status Code" := ResponseBuffer."HTTP Status Code";
            LogEntry."EDS Provider Code" := ResponseBuffer."Provider Code";
            LogEntry."Request Correlation ID" := Format(ResponseBuffer."Correlation ID");
            LogEntry."Response Message" := CopyStr(ResponseBuffer."Error Message", 1, MaxStrLen(LogEntry."Response Message"));
            LogEntry."Retrieval Result" := CopyStr(UpperCase(Format(ResponseBuffer."Result Type")), 1, MaxStrLen(LogEntry."Retrieval Result"));
            if ResponseBuffer.GetRawHttpBodyStream(RawBytes) then begin
                LogEntry."Raw HTTP Bytes".CreateOutStream(RawOut);
                CopyStream(RawOut, RawBytes);
            end;
            if ResponseBuffer.GetBodyInStream(BodyStream) then begin
                LogEntry."Raw Response".CreateOutStream(OutStr, TextEncoding::UTF8);
                CopyStream(OutStr, BodyStream);
            end;
        end else begin
            LogEntry."Retrieval Result" := 'NO_BUFFER';
            LogEntry."Response Message" := 'EDS не повернув Response Buffer';
        end;
        LogEntry.Modify(true);
        AuditEntry."Attempt Count" += 1;
        AuditEntry."Last Checked At" := LogEntry."Completed At";
        // Do not set Success/Not Found: semantic interpretation comes in Step 4.
        AuditEntry.Modify(true);
        Materializer.Process(AuditEntry, LogEntry);
        Message('GET виконано. Журнал: %1, HTTP: %2, результат: %3.',
            LogEntry."Entry No.", LogEntry."HTTP Status Code", LogEntry."Retrieval Result");
    end;

    local procedure IsDigits(Value: Text): Boolean
    var
        Pos: Integer;
    begin
        for Pos := 1 to StrLen(Value) do
            if not (Value[Pos] in ['0' .. '9']) then
                exit(false);
        exit(true);
    end;
}
