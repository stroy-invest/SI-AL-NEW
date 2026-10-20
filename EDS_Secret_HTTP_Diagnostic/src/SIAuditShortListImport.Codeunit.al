codeunit 70050 "SI Audit ShortList Import"
{
    // Step 2: source-only staging. No registry HTTP calls and no BP materialization.
    procedure ImportBatch(var Batch: Record "SI Audit Batch")
    var
        ExcelBuf: Record "Excel Buffer" temporary;
        Entry: Record "SI Audit Entry";
        FileName: Text;
        InputStream: InStream;
        LastRow: Integer;
        RowNo: Integer;
        Imported: Integer;
        Skipped: Integer;
        Pending: Integer;
        Code1C: Text;
        EDRPOU: Text;
        FirmName: Text;
        LegalForm: Text;
        LegalFormShort: Text;
        WorkName: Text;
        IPN: Text;
        FOP: Boolean;
        Reason: Text[500];
    begin
        Batch.TestField("No.");
        if Batch.Status <> Batch.Status::Draft then
            Error('Імпорт дозволено лише для пакета в стані Чернетка.');
        Entry.SetRange("Batch No.", Batch."No.");
        if not Entry.IsEmpty() then
            Error('Пакет %1 вже має записи. Повторний імпорт заборонено.', Batch."No.");

        if not UploadIntoStream('Excel (*.xlsx)|*.xlsx', InputStream) then
            exit;

        ExcelBuf.OpenBookStream(InputStream, 'ShortList');
        ExcelBuf.ReadSheet();
        ValidateHeaders(ExcelBuf);
        ExcelBuf.Reset();
        if ExcelBuf.FindLast() then
            LastRow := ExcelBuf."Row No.";

        for RowNo := 2 to LastRow do begin
            Code1C := Cell(ExcelBuf, RowNo, 2);
            EDRPOU := Cell(ExcelBuf, RowNo, 4);
            IPN := Cell(ExcelBuf, RowNo, 3);
            FirmName := Cell(ExcelBuf, RowNo, 5);
            LegalForm := Cell(ExcelBuf, RowNo, 6);
            LegalFormShort := Cell(ExcelBuf, RowNo, 7);
            WorkName := Cell(ExcelBuf, RowNo, 8);

            if (Code1C <> '') or (EDRPOU <> '') or (FirmName <> '') or (WorkName <> '') then begin
                if StrLen(Code1C) > 8 then
                    Error('Рядок %1: Code1C довший за 8 символів.', RowNo);
                if StrLen(EDRPOU) > 8 then begin
                    // Longer identifiers must not be truncated or sent to the legal-entity endpoint.
                    if StrLen(EDRPOU) > 50 then
                        Error('Рядок %1: значення ЄДРПОУ надто довге.', RowNo);
                end;
                Entry.Init();
                Entry."Batch No." := Batch."No.";
                Entry."Entry No." := RowNo - 1;
                Entry.Code1C := CopyStr(Code1C, 1, MaxStrLen(Entry.Code1C));
                Entry.EDRPOU := CopyStr(EDRPOU, 1, MaxStrLen(Entry.EDRPOU));
                Entry."Source IPN" := CopyStr(IPN, 1, MaxStrLen(Entry."Source IPN"));
                Entry."Source Name" := CopyStr(FirmName, 1, MaxStrLen(Entry."Source Name"));
                Entry."Source Legal Form" := CopyStr(LegalForm, 1, MaxStrLen(Entry."Source Legal Form"));
                Entry."Source Legal Form Short" := CopyStr(LegalFormShort, 1, MaxStrLen(Entry."Source Legal Form Short"));
                Entry."Source Work Name" := CopyStr(WorkName, 1, MaxStrLen(Entry."Source Work Name"));
                Entry."Source Role" := CopyStr(Cell(ExcelBuf, RowNo, 1), 1, MaxStrLen(Entry."Source Role"));
                Entry."Source Filia Name" := CopyStr(Cell(ExcelBuf, RowNo, 9), 1, MaxStrLen(Entry."Source Filia Name"));
                Entry."Source Group" := CopyStr(Cell(ExcelBuf, RowNo, 10), 1, MaxStrLen(Entry."Source Group"));
                Entry."Source VAT Payer" := CopyStr(Cell(ExcelBuf, RowNo, 11), 1, MaxStrLen(Entry."Source VAT Payer"));
                Entry."Source VAT Rate" := CopyStr(Cell(ExcelBuf, RowNo, 12), 1, MaxStrLen(Entry."Source VAT Rate"));
                Entry."Source Excel Row" := RowNo;
                Entry."Source EDRPOU Raw" := CopyStr(EDRPOU, 1, MaxStrLen(Entry."Source EDRPOU Raw"));

                FOP := IsFOP(LegalForm, LegalFormShort, FirmName, WorkName);
                Entry."Is FOP" := FOP;
                Reason := '';
                if FOP then
                    Reason := 'ФОП: виключено з поточного етапу'
                else
                    if not IsEightDigits(EDRPOU) then
                        Reason := 'Немає коректного 8-значного ЄДРПОУ'
                    else
                        if not IsEightDigits(Code1C) then
                            Reason := 'Code1C не містить рівно 8 цифр';
                if Reason <> '' then begin
                    Entry."Processing Status" := Entry."Processing Status"::Skipped;
                    Entry."Result Code" := 'SOURCE_SKIPPED';
                    Entry."Result Details" := Reason;
                    Skipped += 1;
                end else begin
                    Entry."Processing Status" := Entry."Processing Status"::Pending;
                    Pending += 1;
                end;
                Entry.Insert();
                Imported += 1;
            end;
        end;
        if Imported = 0 then
            Error('У ShortList немає записів для імпорту.');
        Batch.Status := Batch.Status::Ready;
        Batch.Modify();
        Message('Імпорт завершено. Пакет %1: %2 записів, очікують %3, пропущено %4.',
            Batch."No.", Imported, Pending, Skipped);
    end;

    local procedure ValidateHeaders(var ExcelBuf: Record "Excel Buffer" temporary)
    begin
        RequireHeader(ExcelBuf, 1, 'Role');
        RequireHeader(ExcelBuf, 2, 'Code1C');
        RequireHeader(ExcelBuf, 3, 'IPN');
        RequireHeader(ExcelBuf, 4, 'EDRPOU');
        RequireHeader(ExcelBuf, 5, 'FirmName');
        RequireHeader(ExcelBuf, 6, 'LegalFormName');
        RequireHeader(ExcelBuf, 7, 'Legal Form Short');
        RequireHeader(ExcelBuf, 8, 'WorkName');
        RequireHeader(ExcelBuf, 9, 'FiliaName');
        RequireHeader(ExcelBuf, 10, 'Група контрагента');
        RequireHeader(ExcelBuf, 11, 'Платник ПДВ');
        RequireHeader(ExcelBuf, 12, 'Ставка ПДВ');
    end;

    local procedure RequireHeader(var ExcelBuf: Record "Excel Buffer" temporary; ColumnNo: Integer; Expected: Text)
    var
        Actual: Text;
    begin
        Actual := Cell(ExcelBuf, 1, ColumnNo);
        if Actual <> Expected then
            Error('ShortList: колонка %1: очікується "%2", отримано "%3".', ColumnNo, Expected, Actual);
    end;

    local procedure Cell(var ExcelBuf: Record "Excel Buffer" temporary; RowNo: Integer; ColumnNo: Integer): Text
    begin
        if ExcelBuf.Get(RowNo, ColumnNo) then
            exit(DelChr(ExcelBuf."Cell Value as Text", '<>', ' '));
        exit('');
    end;

    local procedure IsEightDigits(Value: Text): Boolean
    var
        i: Integer;
        Ch: Char;
    begin
        if StrLen(Value) <> 8 then
            exit(false);
        for i := 1 to 8 do begin
            Ch := Value[i];
            if (Ch < '0') or (Ch > '9') then
                exit(false);
        end;
        exit(true);
    end;

    local procedure IsFOP(LegalForm: Text; ShortForm: Text; FirmName: Text; WorkName: Text): Boolean
    var
        Combined: Text;
    begin
        Combined := UpperCase(LegalForm + ' ' + ShortForm + ' ' + FirmName + ' ' + WorkName);
        exit((StrPos(Combined, 'ФОП') > 0) or
             (StrPos(Combined, 'ФІЗИЧНА ОСОБА-ПІДПРИЄМЕЦЬ') > 0) or
             (StrPos(Combined, 'ФІЗИЧНА ОСОБА ПІДПРИЄМЕЦЬ') > 0));
    end;
}
