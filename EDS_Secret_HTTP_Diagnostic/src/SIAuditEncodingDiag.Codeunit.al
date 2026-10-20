codeunit 70053 "SI Audit Encoding Diag"
{
    // Isolated direct HTTP GET. Does not invoke Foundation EDS or write BP.
    procedure Probe(var AuditEntry: Record "SI Audit Entry")
    var
        Client: HttpClient;
        Response: HttpResponseMessage;
        Headers: HttpHeaders;
        Values: List of [Text];
        ContentType: Text;
        HeaderValue: Text;
        Url: Text;
        RawIn: InStream;
        RawOut: OutStream;
        DownloadIn: InStream;
        DownloadName: Text;
        LogNo: Integer;
        LogEntry: Record "SI Audit Request Log";
        Sent: Boolean;
        Materializer: Codeunit "SI Audit XML Materializer";
    begin
        AuditEntry.TestField(EDRPOU);
        if (StrLen(AuditEntry.EDRPOU) <> 8) or (not IsDigits(AuditEntry.EDRPOU)) then
            Error('Очікується 8-значний цифровий ЄДРПОУ.');
        if AuditEntry."Is FOP" or
           (AuditEntry."Processing Status" = AuditEntry."Processing Status"::Skipped) then
            Error('ФОП і пропущені записи не перевіряємо.');

        // This is intentionally the known public ADM-TOOLS URL, not EDS URL resolution.
        // It tests the server's original HTTP payload independently of Foundation.
        Url := 'https://adm.tools/action/gov/api/?egrpou=' + AuditEntry.EDRPOU;
        LogEntry.Init();
        LogEntry."Batch No." := AuditEntry."Batch No.";
        LogEntry."Audit Entry No." := AuditEntry."Entry No.";
        LogEntry.EDRPOU := AuditEntry.EDRPOU;
        LogEntry.Code1C := AuditEntry.Code1C;
        LogEntry."Requested At" := CurrentDateTime();
        LogEntry."EDS Provider Code" := 'ADM-TOOLS';
        LogEntry."EDS Operation Code" := 'RAW-DIAGNOSTIC';
        LogEntry."Retrieval Result" := 'STARTED';
        LogEntry.Insert(true);
        Commit();

        Sent := Client.Get(Url, Response);
        if not Sent then begin
            LogEntry."Retrieval Result" := 'SEND_FAILED';
            LogEntry."Completed At" := CurrentDateTime();
            LogEntry.Modify(true);
            Error('Прямий HTTP GET не виконався. Перевір Allow HttpClient Requests для лабораторної PTE.');
        end;

        LogEntry."HTTP Status Code" := Response.HttpStatusCode();
        LogEntry."Completed At" := CurrentDateTime();
        Response.Content.GetHeaders(Headers);
        if Headers.GetValues('Content-Type', Values) then
            foreach HeaderValue in Values do
                ContentType += HeaderValue + ' ';
        LogEntry."Response Content Type" := CopyStr(ContentType, 1, MaxStrLen(LogEntry."Response Content Type"));
        LogEntry."Retrieval Result" := 'RAW_CAPTURED';
        if not Response.Content.ReadAs(RawIn) then begin
            LogEntry."Retrieval Result" := 'READ_FAILED';
            LogEntry.Modify(true);
            Error('Не вдалося отримати потік байтів HTTP-відповіді.');
        end;
        LogEntry."Raw HTTP Bytes".CreateOutStream(RawOut);
        CopyStream(RawOut, RawIn);
        LogEntry.Modify(true);

        // Verify the persisted BLOB by re-reading the record from the database.
        LogNo := LogEntry."Entry No.";
        Clear(LogEntry);
        if not LogEntry.Get(LogNo) then
            Error('Журнал № %1 не знайдено після збереження RAW-відповіді.', LogNo);
        LogEntry.CalcFields("Raw HTTP Bytes");
        if not LogEntry."Raw HTTP Bytes".HasValue() then
            Error('RAW HTTP BLOB порожній після запису журналу № %1. Перевірте збереження потоку.', LogNo);

        // Materialize ONLY lab tables from the verified original bytes.
        // The raw diagnostic remains GET-only and never writes production BP.
        Materializer.Process(AuditEntry, LogEntry);

        // Download immediately from the verified record, avoiding selection of a stale log row.
        LogEntry."Raw HTTP Bytes".CreateInStream(DownloadIn);
        DownloadName := StrSubstNo('adm_tools_%1_log_%2.bin', AuditEntry.EDRPOU, LogNo);
        DownloadFromStream(DownloadIn, 'Оригінальна HTTP-відповідь', '', 'Binary files (*.bin)|*.bin', DownloadName);
        Message('RAW GET: HTTP %1; Content-Type: %2; журнал № %3. BLOB збережено та перевірено.',
            LogEntry."HTTP Status Code", LogEntry."Response Content Type", LogNo);
    end;

    local procedure IsDigits(Value: Text): Boolean
    var
        I: Integer;
    begin
        for I := 1 to StrLen(Value) do
            if not (Value[I] in ['0' .. '9']) then
                exit(false);
        exit(true);
    end;
}
