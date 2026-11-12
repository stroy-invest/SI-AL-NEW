codeunit 57124 "SI Prok Journal Reconciliation"
{
    // PF-02.2C: conservative, read-only accounting inspection.
    // A missing journal line is NEVER interpreted as posted without a verified
    // immutable posting correlation. No automatic recreation or posting here.
    procedure ReconcileFact(Fact: Record "SI Prok Production Fact")
    var
        Link: Record "SI Prok Journal Link";
        JournalLine: Record "Item Journal Line";
        ReadyCount: Integer;
        MissingCount: Integer;
        MismatchCount: Integer;
        LegacyCount: Integer;
    begin
        Link.SetRange("Fact Entry No.", Fact."Entry No.");
        if not Link.FindSet(true) then
            Error('PF-02.2C: для факту %1 немає зв’язків журналів.', Fact."Entry No.");
        repeat
            Clear(Link."Reconciliation Details");
            if not Link."Snapshot Available" then begin
                Link."Reconciliation Status" := Link."Reconciliation Status"::Legacy;
                Link."Reconciliation Details" := 'Зв’язок створено до PF-02.2C. Автоматична звірка без контрольного знімка заборонена.';
                LegacyCount += 1;
            end else
                if not JournalLine.Get(Link."Journal Template", Link."Journal Batch", Link."Journal Line No.") then begin
                    Link."Reconciliation Status" := Link."Reconciliation Status"::Missing;
                    Link."Reconciliation Details" := 'Рядок відсутній. Не можна відрізнити видалення від проведення без достовірного облікового підтвердження.';
                    MissingCount += 1;
                end else
                    if not IsExactMatch(Link, JournalLine) then begin
                        Link."Reconciliation Status" := Link."Reconciliation Status"::Mismatch;
                        Link."Reconciliation Details" := 'Облікові реквізити рядка відрізняються від знімка під час підготовки. Проведення заблоковано.';
                        MismatchCount += 1;
                    end else begin
                        Link."Reconciliation Status" := Link."Reconciliation Status"::Ready;
                        Link."Reconciliation Details" := 'Рядок присутній; облікові реквізити збігаються зі знімком.';
                        ReadyCount += 1;
                    end;
            Link."Reconciled At" := CurrentDateTime();
            Link.Modify(true);
        until Link.Next() = 0;
        Message('PF-02.2C: готові %1; змінені %2; відсутні %3; без знімка %4. Проведення не виконувалося.', ReadyCount, MismatchCount, MissingCount, LegacyCount);
    end;

    procedure AssertReady(Fact: Record "SI Prok Production Fact")
    var
        Link: Record "SI Prok Journal Link";
        JournalLine: Record "Item Journal Line";
        Count: Integer;
    begin
        // Must be called immediately before controlled posting (PF-02.3).
        // Re-check live lines: previously persisted Ready is not authorization.
        Link.SetRange("Fact Entry No.", Fact."Entry No.");
        if not Link.FindSet() then
            Error('PF-02.2C: не знайдено зв’язків журналів.');
        repeat
            Count += 1;
            if not Link."Snapshot Available" then
                Error('PF-02.2C: рядок зв’язку %1 без контрольного знімка.', Link."Link Line No.");
            if not JournalLine.Get(Link."Journal Template", Link."Journal Batch", Link."Journal Line No.") then
                Error('PF-02.2C: рядок журналу %1 відсутній; автоматичне проведення заборонено.', Link."Link Line No.");
            if not IsExactMatch(Link, JournalLine) then
                Error('PF-02.2C: рядок журналу %1 змінено; автоматичне проведення заборонено.', Link."Link Line No.");
        until Link.Next() = 0;
        if Count = 0 then
            Error('PF-02.2C: немає рядків для проведення.');
    end;

    local procedure IsExactMatch(Link: Record "SI Prok Journal Link"; Jnl: Record "Item Journal Line"): Boolean
    begin
        exit((Jnl."Document No." = Link."Document No.") and
             (Jnl."Entry Type" = Link."Expected Entry Type") and
             (Jnl."Item No." = Link."Expected Item No.") and
             (Jnl."Variant Code" = Link."Expected Variant Code") and
             (Jnl."Location Code" = Link."Expected Location Code") and
             (Jnl."Bin Code" = Link."Expected Bin Code") and
             (Jnl.Quantity = Link."Expected Quantity") and
             (Jnl."Unit of Measure Code" = Link."Expected UoM") and
             (Jnl."Posting Date" = Link."Expected Posting Date") and
             (Jnl."Order Type" = Jnl."Order Type"::Production) and
             (Jnl."Order No." = Link."Expected Order No.") and
             (Jnl."Order Line No." = Link."Expected Order Line No.") and
             (Jnl."Prod. Order Comp. Line No." = Link."Expected Component Line No."));
    end;
}
