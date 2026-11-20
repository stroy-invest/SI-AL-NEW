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
        Safety: Codeunit "SI Prok Prod Safe Guard";
    begin
        Safety.AssertDisabled('Зміна стану звірки журналів');
        AssertRowsComplete(Fact, true);
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
    begin
        AssertRowsComplete(Fact, true);
        AssertLiveLines(Fact, false);
    end;

    // Used only for a manually approved output-only recovery after
    // consumption has been verified in Item Ledger Entry.
    procedure AssertOutputReady(Fact: Record "SI Prok Production Fact")
    begin
        AssertRowsComplete(Fact, true);
        AssertLiveLines(Fact, true);
    end;

    // For a pre-1.0.0.80 prepared fact, require full material/snapshot consistency,
    // but permit the original document number until No. Series migration.
    procedure AssertPreparedForRenumber(Fact: Record "SI Prok Production Fact")
    var
        Link: Record "SI Prok Journal Link";
        JournalLine: Record "Item Journal Line";
    begin
        if Fact."Accounting Document No." <> '' then
            Error('PF-02.2C: номер облікового документа вже призначено.');
        AssertRowsComplete(Fact, false);
        AssertLiveLines(Fact, false);
        Link.SetRange("Fact Entry No.", Fact."Entry No.");
        if Link.FindSet() then
            repeat
                if not JournalLine.Get(Link."Journal Template", Link."Journal Batch", Link."Journal Line No.") then
                    Error('PF-02.2C: рядок журналу %1 відсутній.', Link."Journal Line No.");
                AssertExclusiveJournalLineOwner(Fact, Link, JournalLine);
            until Link.Next() = 0;
    end;

    // Journal Template/Batch/Line No. identifies a SLOT, not a physical journal row.
    // After old test rows are removed BC can reuse line 10000. Historical links
    // must not be mistaken for active ownership of the newly created row.
    procedure AssertExclusiveJournalLineOwner(Fact: Record "SI Prok Production Fact"; Link: Record "SI Prok Journal Link"; JournalLine: Record "Item Journal Line")
    var
        OtherLink: Record "SI Prok Journal Link";
    begin
        if not IsCurrentJournalLine(Link, JournalLine) then
            Error('PF-02.2C: зв’язок %1 факту %2 вказує на інший екземпляр рядка журналу %3/%4/%5.',
                Link."Link Line No.", Fact."Entry No.", Link."Journal Template", Link."Journal Batch", Link."Journal Line No.");
        OtherLink.SetRange("Journal Template", Link."Journal Template");
        OtherLink.SetRange("Journal Batch", Link."Journal Batch");
        OtherLink.SetRange("Journal Line No.", Link."Journal Line No.");
        OtherLink.SetFilter("Fact Entry No.", '<>%1', Fact."Entry No.");
        if OtherLink.FindSet() then
            repeat
                if IsCurrentJournalLine(OtherLink, JournalLine) and
                   (OtherLink."Document No." = JournalLine."Document No.") then
                    Error('PF-02.2C: фізичний рядок журналу %1/%2/%3 одночасно пов’язаний із фактами %4 та %5.',
                        Link."Journal Template", Link."Journal Batch", Link."Journal Line No.",
                        Fact."Entry No.", OtherLink."Fact Entry No.");
            until OtherLink.Next() = 0;
    end;

    local procedure IsCurrentJournalLine(Link: Record "SI Prok Journal Link"; JournalLine: Record "Item Journal Line"): Boolean
    begin
        // New links are pinned to the immutable SystemId of the journal row.
        if not IsNullGuid(Link."Journal Line SystemId") then
            exit(Link."Journal Line SystemId" = JournalLine.SystemId);
        // Pre-1.0.0.81 links lack SystemId. A journal row created AFTER the link
        // cannot be the original row. Do not mistake a reused Line No. for ownership.
        if (Link."Prepared At" = 0DT) or (JournalLine.SystemCreatedAt = 0DT) then
            exit(false);
        exit(JournalLine.SystemCreatedAt <= Link."Prepared At");
    end;

    local procedure AssertLiveLines(Fact: Record "SI Prok Production Fact"; OutputOnly: Boolean)
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
            if not OutputOnly or (Link."Material Line No." = 0) then begin
                Count += 1;
                if not Link."Snapshot Available" then
                    Error('PF-02.2C: рядок зв’язку %1 без контрольного знімка.', Link."Link Line No.");
                if not JournalLine.Get(Link."Journal Template", Link."Journal Batch", Link."Journal Line No.") then
                    Error('PF-02.2C: рядок журналу %1 відсутній; проведення заборонено.', Link."Link Line No.");
                if JournalLine."Document No." <> Link."Document No." then
                    Error('PF-02.2C: документ рядка журналу %1 = %2, у знімку = %3.',
                        Link."Link Line No.", JournalLine."Document No.", Link."Document No.");
                if not IsExactMatch(Link, JournalLine) then
                    Error('PF-02.2C: рядок журналу %1 змінено; проведення заборонено.', Link."Link Line No.");
            end;
        until Link.Next() = 0;
        if Count = 0 then
            Error('PF-02.2C: немає рядків для проведення.');
    end;

    local procedure AssertRowsComplete(Fact: Record "SI Prok Production Fact"; RequireAssignedDocumentNo: Boolean)
    var
        Link: Record "SI Prok Journal Link";
        Material: Record "SI Prok Prod Fact Material";
        Component: Record "Prod. Order Component";
        ProdLine: Record "Prod. Order Line";
        ItemUoM: Record "Item Unit of Measure";
        LocationSemantics: Codeunit "SI Prok Location Semantics";
        ExpectedQty: Decimal;
        CountOutput: Integer;
        CountConsumption: Integer;
        ExpectedConsumption: Integer;
        DocumentNo: Code[20];
    begin
        if Fact."Accounting Posting Model" = Fact."Accounting Posting Model"::"Process Adjustment" then
            Error('PF-02: звірка Production Order не застосовується до SI Process Production.');
        if not ProdLine.Get(Fact."BC Prod. Order Status", Fact."BC Prod. Order No.", Fact."BC Prod. Order Line No.") then
            Error('PF-02.2C: виробничий рядок BC не знайдено.');
        LocationSemantics.AssertFinishedGoods(ProdLine."Location Code");
        if RequireAssignedDocumentNo then
            Fact.TestField("Accounting Document No.");
        Link.SetRange("Fact Entry No.", Fact."Entry No.");
        if not Link.FindSet() then
            Error('PF-02.2C: немає зв’язків для факту %1.', Fact."Entry No.");
        repeat
            if Link."Production UUID" <> Fact."Production UUID" then
                Error('PF-02.2C: UUID у зв’язку %1 не збігається з фактом.', Link."Link Line No.");
            if Link."Document No." = '' then
                Error('PF-02.2C: номер документа відсутній у зв’язку %1.', Link."Link Line No.");
            if DocumentNo = '' then
                DocumentNo := Link."Document No.";
            if Link."Document No." <> DocumentNo then
                Error('PF-02.2C: різні номери документа у зв’язках: %1 і %2 (рядок %3).',
                    DocumentNo, Link."Document No.", Link."Link Line No.");
            if RequireAssignedDocumentNo and (Link."Document No." <> Fact."Accounting Document No.") then
                Error('PF-02.2C: документ у зв’язку %1 = %2, але факту призначено %3.',
                    Link."Link Line No.", Link."Document No.", Fact."Accounting Document No.");
            if (Link."Expected Order No." <> Fact."BC Prod. Order No.") or
               (Link."Expected Order Line No." <> Fact."BC Prod. Order Line No.") then
                Error('PF-02.2C: виробниче замовлення або рядок не збігається у зв’язку %1.', Link."Link Line No.");
            // Posting Date is an accounting date, not necessarily production date or Today.
            if Link."Expected Posting Date" = 0D then
                Error('PF-02.2C: дата обліку відсутня у зв’язку %1.', Link."Link Line No.");
            if not Link."Snapshot Available" then
                Error('PF-02.2C: зв’язок %1 без контрольного знімка.', Link."Link Line No.");
            if Link."Material Line No." = 0 then begin
                CountOutput += 1;
                if (Link."Expected Entry Type" <> Link."Expected Entry Type"::Output) or
                   (Link."Expected Item No." <> Fact."Item No.") or
                   (Link."Expected Variant Code" <> Fact."Variant Code") or
                   (Link."Expected Location Code" <> ProdLine."Location Code") or
                   (Link."Expected UoM" <> ProdLine."Unit of Measure Code") or
                   (Link."Expected Component Line No." <> 0) or
                   (Link."Expected Quantity" <> Fact."Accounting Output Qty") then
                    Error('PF-02.2C: Output не збігається з фактом %1.', Fact."Entry No.");
            end else begin
                CountConsumption += 1;
                if not Material.Get(Fact."Entry No.", Link."Material Line No.") then
                    Error('PF-02.2C: зайвий зв’язок із матеріалом %1.', Link."Material Line No.");
                Component.Reset();
                Component.SetRange(Status, Fact."BC Prod. Order Status");
                Component.SetRange("Prod. Order No.", Fact."BC Prod. Order No.");
                Component.SetRange("Prod. Order Line No.", Fact."BC Prod. Order Line No.");
                Component.SetRange("Item No.", Material."Item No.");
                Component.SetRange("Variant Code", Material."Variant Code");
                if Component.Count() <> 1 then
                    Error('PF-02.2C: немає однозначного компонента для %1.', Material."Item No.");
                Component.FindFirst();
                LocationSemantics.AssertMaterial(Component."Location Code");
                if Component."Flushing Method" <> Component."Flushing Method"::Manual then
                    Error('PF-02.2C: компонент %1 повинен мати Flushing Method Manual.', Component."Item No.");
                if not ItemUoM.Get(Material."Item No.", Component."Unit of Measure Code") then
                    Error('PF-02.2C: немає ОВ матеріалу %1.', Material."Item No.");
                ItemUoM.TestField("Qty. per Unit of Measure");
                ExpectedQty := Round(Material."Actual Base Qty" / ItemUoM."Qty. per Unit of Measure", 0.00001);
                if (Material."Actual Base Qty" <= 0) or
                   (Link."Expected Entry Type" <> Link."Expected Entry Type"::Consumption) or
                   (Link."Expected Item No." <> Material."Item No.") or
                   (Link."Expected Variant Code" <> Material."Variant Code") or
                   (Link."Expected Location Code" <> Component."Location Code") or
                   (Link."Expected Bin Code" <> Component."Bin Code") or
                   (Link."Expected UoM" <> Component."Unit of Measure Code") or
                   (Link."Expected Component Line No." <> Component."Line No.") or
                   (Link."Expected Quantity" <> ExpectedQty) then
                    Error('PF-02.2C: Consumption не відповідає фактичному матеріалу %1.', Material."Line No.");
            end;
        until Link.Next() = 0;
        if CountOutput <> 1 then
            Error('PF-02.2C: очікувався рівно один Output; знайдено %1.', CountOutput);
        Material.SetRange("Production Fact Entry No.", Fact."Entry No.");
        if Material.FindSet() then
            repeat
                if Material."Actual Base Qty" > 0 then begin
                    ExpectedConsumption += 1;
                    Link.Reset();
                    Link.SetRange("Fact Entry No.", Fact."Entry No.");
                    Link.SetRange("Material Line No.", Material."Line No.");
                    if Link.Count() <> 1 then
                        Error('PF-02.2C: матеріал %1 має %2 зв’язків журналу; потрібен один.', Material."Line No.", Link.Count());
                end;
            until Material.Next() = 0;
        if (CountConsumption <> ExpectedConsumption) or (ExpectedConsumption = 0) then
            Error('PF-02.2C: неповний набір Consumption: очікується %1, знайдено %2.', ExpectedConsumption, CountConsumption);
    end;

    local procedure IsExactMatch(Link: Record "SI Prok Journal Link"; Jnl: Record "Item Journal Line"): Boolean
    begin
        exit(IsCurrentJournalLine(Link, Jnl) and
             (Jnl."Document No." = Link."Document No.") and
             (Jnl."Posting No. Series" = '') and
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
