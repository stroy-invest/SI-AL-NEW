codeunit 57139 "SI Prok Process Journal Prep"
{
    // Reuse the verified Stage 1 backend in the Shipment pipeline.
    // The old Sandbox entry point is retained for historical test actions.
    procedure PrepareSandbox(var Fact: Record "SI Prok Production Fact")
    var
        Env: Codeunit "Environment Information";
    begin
        if not Env.IsSandbox() then
            Error('SI Process Production: тестова дія доступна лише в Sandbox.');
        Prepare(Fact);
        Message('SI Process Production: факт %1, документ %2. Підготовлено %3 списань і 1 надходження; проведення не виконано.',
            Fact."Entry No.", Fact."Accounting Document No.", Fact."Accounting Material Lines");
    end;

    procedure Prepare(var Fact: Record "SI Prok Production Fact")
    var
        Setup: Record "SI Prok Journal Setup";
        JournalTemplate: Record "Item Journal Template";
        JournalBatch: Record "Item Journal Batch";
        JournalLine: Record "Item Journal Line";
        Material: Record "SI Prok Prod Fact Material";
        MaterialLocation: Record Location;
        FinishedLocation: Record Location;
        Item: Record Item;
        ItemUoM: Record "Item Unit of Measure";
        Link: Record "SI Prok Journal Link";
        Attempt: Record "SI Prok Posting Attempt";
        Semantics: Codeunit "SI Prok Location Semantics";
        Cleanup: Codeunit "SI Prok Process Jnl Cleanup";
        DocumentNo: Code[20];
        PostingDate: Date;
        NextLine: Integer;
        LinkLine: Integer;
        MaterialCount: Integer;
        MaterialQty: Decimal;
    begin
        Fact.Get(Fact."Entry No.");
        AssertFactReady(Fact);
        if Fact."Accounting Document No." <> '' then
            Error('SI Process Production: факт %1 вже має обліковий документ %2. Стару підготовку не змінюємо.',
                Fact."Entry No.", Fact."Accounting Document No.");
        if Attempt.Get(Fact."Production UUID") then
            Error('SI Process Production: факт %1 має попередню спробу проведення (%2). Спочатку потрібне окреме контрольоване очищення.',
                Fact."Entry No.", Attempt.Status);
        Link.LockTable();
        Link.SetRange("Fact Entry No.", Fact."Entry No.");
        if not Link.IsEmpty() then
            Error('SI Process Production: факт %1 вже має Journal Links. Повторна підготовка заборонена.', Fact."Entry No.");
        Link.Reset();
        Link.SetRange("Production UUID", Fact."Production UUID");
        if not Link.IsEmpty() then
            Error('SI Process Production: UUID %1 вже використаний у журналах.', Fact."Production UUID");

        if not Setup.Get('DEFAULT') then
            Error('SI Process Production: відсутні налаштування журналів Proktek.');
        Setup.TestField("Process Template");
        Setup.TestField("Process Batch");
        Setup.TestField("Process Business Group");
        Setup.TestField("Document No. Series");
        if not JournalTemplate.Get(Setup."Process Template") then
            Error('SI Process Production: шаблон %1 не знайдено.', Setup."Process Template");
        if (JournalTemplate.Type <> JournalTemplate.Type::Item) or JournalTemplate.Recurring then
            Error('SI Process Production: потрібен звичайний шаблон товарного журналу (Item, не recurring).');
        if not JournalBatch.Get(Setup."Process Template", Setup."Process Batch") then
            Error('SI Process Production: пакет %1/%2 не знайдено.', Setup."Process Template", Setup."Process Batch");
        if (JournalBatch."No. Series" <> '') or (JournalBatch."Posting No. Series" <> '') then
            Error('SI Process Production: у пакеті очистіть No. Series та Posting No. Series; документ призначає серія Proktek.');
        // PROC-FIX-001: clear only a verified technical remainder from a
        // previously COMPLETED Process fact. All other rows still block MVP.
        Cleanup.CleanupPriorCompletedRemainder(Setup."Process Template", Setup."Process Batch");
        // Fail closed if another fact is already using the shared MVP batch.
        JournalLine.LockTable();
        JournalLine.SetRange("Journal Template Name", Setup."Process Template");
        JournalLine.SetRange("Journal Batch Name", Setup."Process Batch");
        if not JournalLine.IsEmpty() then
            Error('SI Process Production: пакет %1/%2 не порожній. Для MVP один пакет — один факт.',
                Setup."Process Template", Setup."Process Batch");
        Semantics.ResolveMaterialWarehouse(MaterialLocation);
        Semantics.ResolveFinishedGoodsWarehouse(FinishedLocation);
        PostingDate := ResolvePostingDate(Fact, Setup);
        DocumentNo := AllocateDocumentNo(Setup."Document No. Series", PostingDate);

        // Only accounting metadata is changed on the MES fact. Source evidence
        // (UUID, raw JSON, produced quantity and materials) remains immutable.
        Fact."Accounting Posting Model" := Fact."Accounting Posting Model"::"Process Adjustment";
        Fact."Accounting Document No." := DocumentNo;
        Fact."Accounting Output Qty" := Fact."Produced Quantity M3";
        Fact.Modify(true);

        NextLine := 10000;
        Material.SetRange("Production Fact Entry No.", Fact."Entry No.");
        if Material.FindSet() then
            repeat
                if Material."Actual Base Qty" > 0 then begin
                    Item.Get(Material."Item No.");
                    ItemUoM.Get(Item."No.", Item."Base Unit of Measure");
                    MaterialQty := Round(Material."Actual Base Qty", 0.00001);
                    if MaterialQty <= 0 then
                        Error('SI Process Production: кількість матеріалу %1 менша за точність журналу.', Material."Line No.");
                    CreateJournalLine(JournalLine, Setup, NextLine, PostingDate, DocumentNo,
                        JournalLine."Entry Type"::"Negative Adjmt.", Material."Item No.", Material."Variant Code",
                        MaterialLocation.Code, Item."Base Unit of Measure", MaterialQty);
                    LinkLine += 10000;
                    SaveLink(Fact, LinkLine, Material."Line No.", JournalLine);
                    NextLine += 10000;
                    MaterialCount += 1;
                end;
            until Material.Next() = 0;

        Item.Get(Fact."Item No.");
        if not ItemUoM.Get(Item."No.", 'M3') then
            Error('SI Process Production: для бетону %1 відсутня одиниця M3.', Item."No.");
        ItemUoM.TestField("Qty. per Unit of Measure");
        CreateJournalLine(JournalLine, Setup, NextLine, PostingDate, DocumentNo,
            JournalLine."Entry Type"::"Positive Adjmt.", Fact."Item No.", Fact."Variant Code",
            FinishedLocation.Code, 'M3', Fact."Produced Quantity M3");
        LinkLine += 10000;
        SaveLink(Fact, LinkLine, 0, JournalLine);
        Fact."Accounting Material Lines" := MaterialCount;
        Fact."Accounting Readiness" := Fact."Accounting Readiness"::Ready;
        Fact."Accounting Checked At" := CurrentDateTime();
        Fact."Accounting Diagnostics" := 'SI Process Production: підготовлено непроведені Negative/Positive Adjustment. Потрібна звірка перед проведенням.';
        Fact.Modify(true);
    end;

    local procedure AssertFactReady(Fact: Record "SI Prok Production Fact")
    var
        Material: Record "SI Prok Prod Fact Material";
        Item: Record Item;
        ItemUoM: Record "Item Unit of Measure";
        PositiveCount: Integer;
    begin
        if IsNullGuid(Fact."Production UUID") then
            Error('SI Process Production: Production UUID відсутній.');
        if Fact."Verification Status" <> Fact."Verification Status"::Verified then
            Error('SI Process Production: обсяг виробництва не підтверджено.');
        if Fact."Technical Validation" <> Fact."Technical Validation"::Complete then
            Error('SI Process Production: технічна перевірка не Complete.');
        if Fact."Produced Quantity M3" <= 0 then
            Error('SI Process Production: відсутній додатний обсяг готового бетону.');
        if Fact."Production Date/Time" = 0DT then
            Error('SI Process Production: дата виробництва відсутня.');
        if not Item.Get(Fact."Item No.") then
            Error('SI Process Production: товар бетону %1 не знайдено.', Fact."Item No.");
        if Item.Type <> Item.Type::Inventory then
            Error('SI Process Production: бетон %1 повинен бути складським товаром.', Item."No.");
        if not ItemUoM.Get(Item."No.", 'M3') then
            Error('SI Process Production: у товару %1 немає одиниці M3.', Item."No.");
        ItemUoM.TestField("Qty. per Unit of Measure");

        Material.SetRange("Production Fact Entry No.", Fact."Entry No.");
        if not Material.FindSet() then
            Error('SI Process Production: немає фактичних матеріалів.');
        repeat
            if (not Material."BC Material Resolved") or (Material."Item No." = '') then
                Error('SI Process Production: матеріал %1 не зіставлений із товаром BC.', Material."Line No.");
            if not Material."UoM Normalized" then
                Error('SI Process Production: матеріал %1 має ненормалізовану одиницю.', Material."Line No.");
            if Material."Actual Observed Slot Count" = 0 then
                Error('SI Process Production: для матеріалу %1 відсутні фактичні показники.', Material."Line No.");
            if Material."Actual Base Qty" < 0 then
                Error('SI Process Production: матеріал %1 має від’ємну кількість.', Material."Line No.");
            if not Item.Get(Material."Item No.") then
                Error('SI Process Production: товар матеріалу %1 не знайдено.', Material."Item No.");
            if Item.Type <> Item.Type::Inventory then
                Error('SI Process Production: матеріал %1 повинен бути складським товаром.', Item."No.");
            Item.TestField("Base Unit of Measure");
            if Material."BC Base UoM" <> Item."Base Unit of Measure" then
                Error('SI Process Production: базова ОВ матеріалу %1 не відповідає картці товару.', Material."Line No.");
            if not ItemUoM.Get(Item."No.", Item."Base Unit of Measure") then
                Error('SI Process Production: базова ОВ %1 для товару %2 відсутня.', Item."Base Unit of Measure", Item."No.");
            ItemUoM.TestField("Qty. per Unit of Measure");
            if Material."Actual Base Qty" > 0 then
                PositiveCount += 1;
        until Material.Next() = 0;
        if PositiveCount = 0 then
            Error('SI Process Production: немає жодного матеріалу з додатною фактичною кількістю.');
    end;

    local procedure CreateJournalLine(var Line: Record "Item Journal Line"; Setup: Record "SI Prok Journal Setup";
        LineNo: Integer; PostingDate: Date; DocumentNo: Code[20]; EntryType: Enum "Item Ledger Entry Type";
        ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; UoM: Code[10]; Qty: Decimal)
    begin
        Clear(Line);
        Line.Init();
        Line."Journal Template Name" := Setup."Process Template";
        Line."Journal Batch Name" := Setup."Process Batch";
        Line."Line No." := LineNo;
        Line.Insert(true);
        Line.Validate("Posting Date", PostingDate);
        Line.Validate("Entry Type", EntryType);
        Line.Validate("Item No.", ItemNo);
        Line.Validate("Variant Code", VariantCode);
        Line.Validate("Location Code", LocationCode);
        Line.Validate("Unit of Measure Code", UoM);
        Line.Validate(Quantity, Qty);
        Line.Validate("Gen. Bus. Posting Group", Setup."Process Business Group");
        Line.Validate("Posting Date", PostingDate);
        Line.Validate("Document No.", DocumentNo);
        if Line."Posting No. Series" <> '' then
            Error('SI Process Production: Posting No. Series рядка повинен бути порожнім.');
        if (Line."Entry Type" <> EntryType) or (Line."Location Code" <> LocationCode) or
           (Line."Gen. Bus. Posting Group" <> Setup."Process Business Group") or
           (Line."Posting Date" <> PostingDate) or (Line."Document No." <> DocumentNo) or
           (Line.Quantity <> Qty) then
            Error('SI Process Production: стандартна валідація змінила ключові реквізити рядка %1.', LineNo);
        Line.Modify(true);
    end;

    local procedure SaveLink(Fact: Record "SI Prok Production Fact"; LinkNo: Integer; MaterialLineNo: Integer; Jnl: Record "Item Journal Line")
    var
        Link: Record "SI Prok Journal Link";
    begin
        Link.Init();
        Link."Fact Entry No." := Fact."Entry No.";
        Link."Link Line No." := LinkNo;
        Link."Production UUID" := Fact."Production UUID";
        Link."Material Line No." := MaterialLineNo;
        Link."Journal Template" := Jnl."Journal Template Name";
        Link."Journal Batch" := Jnl."Journal Batch Name";
        Link."Journal Line No." := Jnl."Line No.";
        Link."Journal Line SystemId" := Jnl.SystemId;
        Link."Document No." := Jnl."Document No.";
        Link."Expected Entry Type" := Jnl."Entry Type";
        Link."Expected Item No." := Jnl."Item No.";
        Link."Expected Variant Code" := Jnl."Variant Code";
        Link."Expected Location Code" := Jnl."Location Code";
        Link."Expected Bin Code" := Jnl."Bin Code";
        Link."Expected Quantity" := Jnl.Quantity;
        Link."Expected UoM" := Jnl."Unit of Measure Code";
        Link."Expected Posting Date" := Jnl."Posting Date";
        Link."Expected Gen. Bus. Group" := Jnl."Gen. Bus. Posting Group";
        Link."Expected Order No." := Jnl."Order No.";
        Link."Expected Order Line No." := Jnl."Order Line No.";
        Link."Expected Component Line No." := Jnl."Prod. Order Comp. Line No.";
        Link."Snapshot Available" := true;
        Link."Prepared At" := CurrentDateTime();
        Link."Prepared By" := CopyStr(UserId(), 1, MaxStrLen(Link."Prepared By"));
        Link.Insert(true);
    end;

    local procedure ResolvePostingDate(Fact: Record "SI Prok Production Fact"; Setup: Record "SI Prok Journal Setup"): Date
    var
        PostingDate: Date;
    begin
        case Setup."Posting Date Policy" of
            Setup."Posting Date Policy"::"Production Date":
                PostingDate := DT2Date(Fact."Production Date/Time");
            Setup."Posting Date Policy"::"Work Date":
                PostingDate := WorkDate();
            Setup."Posting Date Policy"::"Specified Date":
                begin
                    Setup.TestField("Specified Posting Date");
                    PostingDate := Setup."Specified Posting Date";
                end;
            else
                Error('SI Process Production: невідома політика дати обліку.');
        end;
        if PostingDate = 0D then
            Error('SI Process Production: дата обліку порожня.');
        exit(PostingDate);
    end;

    local procedure AllocateDocumentNo(SeriesCode: Code[20]; UsageDate: Date): Code[20]
    var
        NoSeries: Codeunit "No. Series";
        Fact: Record "SI Prok Production Fact";
        Link: Record "SI Prok Journal Link";
        Ledger: Record "Item Ledger Entry";
        JournalLine: Record "Item Journal Line";
        DocumentNo: Code[20];
    begin
        NoSeries.TestAutomatic(SeriesCode);
        DocumentNo := NoSeries.GetNextNo(SeriesCode, UsageDate);
        if DocumentNo = '' then
            Error('SI Process Production: серія не повернула номер документа.');
        Fact.SetRange("Accounting Document No.", DocumentNo);
        if not Fact.IsEmpty() then
            Error('SI Process Production: документ %1 вже призначено іншому факту.', DocumentNo);
        Link.SetRange("Document No.", DocumentNo);
        if not Link.IsEmpty() then
            Error('SI Process Production: документ %1 вже має Journal Links.', DocumentNo);
        JournalLine.SetRange("Document No.", DocumentNo);
        if not JournalLine.IsEmpty() then
            Error('SI Process Production: документ %1 вже є в товарному журналі.', DocumentNo);
        Ledger.SetRange("Document No.", DocumentNo);
        if not Ledger.IsEmpty() then
            Error('SI Process Production: документ %1 вже має проведені записи.', DocumentNo);
        exit(DocumentNo);
    end;
}
