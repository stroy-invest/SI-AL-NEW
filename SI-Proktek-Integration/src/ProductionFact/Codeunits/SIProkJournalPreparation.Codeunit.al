codeunit 57122 "SI Prok Journal Preparation"
{
    // PF-02.2B: creates UNPOSTED standard Item Journal Lines. Never posts.
    // Entire preparation is one BC transaction: any error rolls back lines and links.
    procedure Prepare(var Fact: Record "SI Prok Production Fact")
    var
        Setup: Record "SI Prok Journal Setup";
        Link: Record "SI Prok Journal Link";
        ProdOrder: Record "Production Order";
        ProdLine: Record "Prod. Order Line";
        Material: Record "SI Prok Prod Fact Material";
        Component: Record "Prod. Order Component";
        OutputTemplate: Record "Item Journal Template";
        ConsumptionTemplate: Record "Item Journal Template";
        OutputBatch: Record "Item Journal Batch";
        ConsumptionBatch: Record "Item Journal Batch";
        OutputLine: Record "Item Journal Line";
        ConsumptionLine: Record "Item Journal Line";
        ItemUoM: Record "Item Unit of Measure";
        Prep: Codeunit "SI Prok Accounting Prep Mgt.";
        LocationSemantics: Codeunit "SI Prok Location Semantics";
        Attempt: Record "SI Prok Posting Attempt";
        DocumentNo: Code[20];
        NextOutputLine: Integer;
        NextConsumptionLine: Integer;
        LinkNo: Integer;
        ConsumptionQty: Decimal;
        PostingDate: Date;
        Safety: Codeunit "SI Prok Prod Safe Guard";
    begin
        Safety.AssertDisabled('Підготовка Output/Consumption');
        Fact.Get(Fact."Entry No.");
        if Fact."Accounting Posting Model" = Fact."Accounting Posting Model"::"Process Adjustment" then
            Error('PF-02: факт використовує SI Process Production. Стару Production Order підготовку заборонено.');
        // Re-run the entire readiness contract immediately before journal insertion.
        Prep.CheckFact(Fact);
        Fact.Get(Fact."Entry No.");
        if Fact."Accounting Readiness" <> Fact."Accounting Readiness"::Ready then
            Error('PF-02.2B: факт не готовий: %1', Fact."Accounting Diagnostics");
        if Fact."Production Date/Time" = 0DT then
            Error('PF-02.2B: дата/час факту відсутні.');
        if IsNullGuid(Fact."Production UUID") then
            Error('PF-02.2B: Production UUID порожній.');
        if Attempt.Get(Fact."Production UUID") then
            Error('PF-02.2B: для цього UUID вже існує спроба проведення; потрібна облікова звірка.');
        if Fact."Accounting Document No." <> '' then
            Error('PF-02.2B: номер облікового документа %1 вже призначено факту %2; повторна підготовка заборонена.',
                Fact."Accounting Document No.", Fact."Entry No.");

        // Strict idempotency: even a deleted or posted journal line cannot cause recreation.
        Link.LockTable();
        Link.SetRange("Production UUID", Fact."Production UUID");
        if not Link.IsEmpty() then
            Error('PF-02.2B: для Production UUID %1 уже є зв’язки журналів. Повторне створення заборонено.', Fact."Production UUID");
        Link.Reset();
        Link.SetRange("Fact Entry No.", Fact."Entry No.");
        if not Link.IsEmpty() then
            Error('PF-02.2B: журнали для факту %1 вже готувалися.', Fact."Entry No.");

        if not Setup.Get('DEFAULT') then
            Error('PF-02.2B: заповніть сторінку «Налаштування виробничих журналів Proktek».');
        Setup.TestField("Output Template");
        Setup.TestField("Output Batch");
        Setup.TestField("Consumption Template");
        Setup.TestField("Consumption Batch");
        Setup.TestField("Document No. Series");
        if (Setup."Output Template" = Setup."Consumption Template") and
           (Setup."Output Batch" = Setup."Consumption Batch") then
            Error('PF-02.2B: Output і Consumption повинні використовувати різні пакети.');
        ValidateBatch(Setup."Output Template", Setup."Output Batch", OutputTemplate, OutputBatch);
        ValidateBatch(Setup."Consumption Template", Setup."Consumption Batch", ConsumptionTemplate, ConsumptionBatch);
        PostingDate := ResolvePostingDate(Fact, Setup);
        ProdOrder.Get(Fact."BC Prod. Order Status", Fact."BC Prod. Order No.");
        ProdOrder.TestField(Status, ProdOrder.Status::Released);
        ProdLine.Get(ProdOrder.Status, ProdOrder."No.", Fact."BC Prod. Order Line No.");
        LocationSemantics.AssertFinishedGoods(ProdLine."Location Code");
        DocumentNo := AllocateDocumentNo(Setup."Document No. Series", PostingDate);
        if DocumentNo = ProdOrder."No." then
            Error('PF-02.2B: серія номерів повернула номер виробничого замовлення %1. Налаштуйте окрему серію.', DocumentNo);
        Fact."Accounting Document No." := DocumentNo;
        Fact.Modify(true);
        NextOutputLine := NextLineNo(Setup."Output Template", Setup."Output Batch");
        NextConsumptionLine := NextLineNo(Setup."Consumption Template", Setup."Consumption Batch");

        OutputLine.Init();
        OutputLine."Journal Template Name" := Setup."Output Template";
        OutputLine."Journal Batch Name" := Setup."Output Batch";
        OutputLine."Line No." := NextOutputLine;
        OutputLine.Insert(true);
        OutputLine.Validate("Posting Date", PostingDate);
        OutputLine.Validate("Entry Type", OutputLine."Entry Type"::Output);
        OutputLine.Validate("Order Type", OutputLine."Order Type"::Production);
        OutputLine.Validate("Order No.", ProdOrder."No.");
        OutputLine.Validate("Order Line No.", ProdLine."Line No.");
        OutputLine.Validate("Item No.", ProdLine."Item No.");
        OutputLine.Validate("Variant Code", ProdLine."Variant Code");
        OutputLine.Validate("Location Code", ProdLine."Location Code");
        OutputLine.Validate("Unit of Measure Code", ProdLine."Unit of Measure Code");
        OutputLine.Validate("Output Quantity", Fact."Accounting Output Qty");
        // Production validations may alter dates and numbers; enforce the chosen
        // accounting date and the allocated No. Series document number last.
        OutputLine.Validate("Posting Date", PostingDate);
        OutputLine.Validate("Document No.", DocumentNo);
        if OutputLine."Posting No. Series" <> '' then
            Error('PF-02.2B: Output має Posting No. Series; BC може змінити номер під час проведення.');
        OutputLine.Modify(true);
        if OutputLine."Posting Date" <> PostingDate then
            Error('PF-02.2B: дата Output %1 відрізняється від налаштованої %2.', OutputLine."Posting Date", PostingDate);
        SaveLink(Fact, 10000, 0, OutputLine);

        LinkNo := 10000;
        Material.SetRange("Production Fact Entry No.", Fact."Entry No.");
        if Material.FindSet() then
            repeat
                Component.Reset();
                Component.SetRange(Status, ProdOrder.Status);
                Component.SetRange("Prod. Order No.", ProdOrder."No.");
                Component.SetRange("Prod. Order Line No.", ProdLine."Line No.");
                Component.SetRange("Item No.", Material."Item No.");
                Component.SetRange("Variant Code", Material."Variant Code");
                if Component.Count() <> 1 then
                    Error('PF-02.2B: компонент %1 має неоднозначне зіставлення.', Material."Item No.");
                Component.FindFirst();
                LocationSemantics.AssertMaterial(Component."Location Code");
                if Component."Flushing Method" <> Component."Flushing Method"::Manual then
                    Error('PF-02.2B: компонент %1: Flushing Method повинен бути Manual.', Component."Item No.");
                if not ItemUoM.Get(Material."Item No.", Component."Unit of Measure Code") then
                    Error('PF-02.2B: не знайдено одиницю %1 для %2.', Component."Unit of Measure Code", Material."Item No.");
                ItemUoM.TestField("Qty. per Unit of Measure");
                ConsumptionQty := Round(Material."Actual Base Qty" / ItemUoM."Qty. per Unit of Measure", 0.00001);
                if ConsumptionQty < 0 then
                    Error('PF-02.2B: від’ємна кількість матеріалу %1.', Material."Item No.");
                if (Material."Actual Base Qty" > 0) and (ConsumptionQty = 0) then
                    Error('PF-02.2B: фактична кількість матеріалу %1 менша за точність журналу.', Material."Item No.");
                // Zero actual consumption is evidence, but not a journal transaction.
                if ConsumptionQty > 0 then begin
                    ConsumptionLine.Init();
                    ConsumptionLine."Journal Template Name" := Setup."Consumption Template";
                    ConsumptionLine."Journal Batch Name" := Setup."Consumption Batch";
                    ConsumptionLine."Line No." := NextConsumptionLine;
                    ConsumptionLine.Insert(true);
                    ConsumptionLine.Validate("Posting Date", PostingDate);
                    ConsumptionLine.Validate("Entry Type", ConsumptionLine."Entry Type"::Consumption);
                    ConsumptionLine.Validate("Order Type", ConsumptionLine."Order Type"::Production);
                    ConsumptionLine.Validate("Order No.", ProdOrder."No.");
                    ConsumptionLine.Validate("Order Line No.", ProdLine."Line No.");
                    ConsumptionLine.Validate("Prod. Order Comp. Line No.", Component."Line No.");
                    ConsumptionLine.Validate("Item No.", Component."Item No.");
                    ConsumptionLine.Validate("Variant Code", Component."Variant Code");
                    ConsumptionLine.Validate("Location Code", Component."Location Code");
                    ConsumptionLine.Validate("Bin Code", Component."Bin Code");
                    ConsumptionLine.Validate("Unit of Measure Code", Component."Unit of Measure Code");
                    ConsumptionLine.Validate(Quantity, ConsumptionQty);
                    ConsumptionLine.Validate("Posting Date", PostingDate);
                    ConsumptionLine.Validate("Document No.", DocumentNo);
                    if ConsumptionLine."Posting No. Series" <> '' then
                        Error('PF-02.2B: Consumption має Posting No. Series; BC може змінити номер під час проведення.');
                    ConsumptionLine.Modify(true);
                    if ConsumptionLine."Posting Date" <> PostingDate then
                        Error('PF-02.2B: дата Consumption %1 відрізняється від налаштованої %2.', ConsumptionLine."Posting Date", PostingDate);
                    LinkNo += 10000;
                    SaveLink(Fact, LinkNo, Material."Line No.", ConsumptionLine);
                    NextConsumptionLine += 10000;
                end;
            until Material.Next() = 0;
        Message('PF-02.2B: підготовлено Output та %1 рядків Consumption. Журнали НЕ проведено.', (LinkNo - 10000) / 10000);
    end;

    // Only the configured accounting date changes. Production Date/Time is evidence
    // from MES and must never be rewritten to satisfy inventory posting.
    local procedure ResolvePostingDate(Fact: Record "SI Prok Production Fact"; Setup: Record "SI Prok Journal Setup"): Date
    var
        PostingDate: Date;
    begin
        case Setup."Posting Date Policy" of
            Setup."Posting Date Policy"::"Production Date":
                begin
                    if Fact."Production Date/Time" = 0DT then
                        Error('PF-02: дата виробництва відсутня.');
                    PostingDate := DT2Date(Fact."Production Date/Time");
                end;
            Setup."Posting Date Policy"::"Work Date":
                PostingDate := WorkDate();
            Setup."Posting Date Policy"::"Specified Date":
                begin
                    Setup.TestField("Specified Posting Date");
                    PostingDate := Setup."Specified Posting Date";
                end;
            else
                Error('PF-02: невідома політика дати обліку.');
        end;
        if PostingDate = 0D then
            Error('PF-02: дата бухгалтерського проведення порожня.');
        exit(PostingDate);
    end;

    // PF-02: explicit Sandbox repair for already prepared, fully UNPOSTED journals.
    // A Started attempt is allowed ONLY when both ledger groups are still zero.
    // The durable attempt is deliberately preserved; posting resumes through
    // RecoverUnpostedSandbox, never through PostSandbox.
    procedure RedatePreparedSandbox(var Fact: Record "SI Prok Production Fact")
    var
        Env: Codeunit "Environment Information";
        Setup: Record "SI Prok Journal Setup";
        Attempt: Record "SI Prok Posting Attempt";
        Link: Record "SI Prok Journal Link";
        JournalLine: Record "Item Journal Line";
        Recon: Codeunit "SI Prok Journal Reconciliation";
        Audit: Codeunit "SI Prok Posting Audit";
        PostingDate: Date;
        OriginalDate: Date;
        DocumentNo: Code[20];
        Changed: Integer;
        StartedAttempt: Boolean;
        Safety: Codeunit "SI Prok Prod Safe Guard";
    begin
        Safety.AssertDisabled('Зміна дати журналу');
        if not Env.IsSandbox() then
            Error('PF-02: зміна дати підготовлених журналів дозволена лише в Sandbox.');
        Fact.Get(Fact."Entry No.");
        Fact.TestField("Accounting Document No.");
        if not Setup.Get('DEFAULT') then
            Error('PF-02: відсутні налаштування виробничих журналів Proktek.');
        PostingDate := ResolvePostingDate(Fact, Setup);
        if Attempt.Get(Fact."Production UUID") then begin
            if Attempt.Status <> Attempt.Status::Started then
                Error('PF-02: спроба проведення вже завершена; змінювати дату заборонено.');
            StartedAttempt := true;
        end;
        // A full live/snapshot check and the posting audit MUST precede any mutation.
        Recon.AssertReady(Fact);
        Audit.AssertGroupNotPosted(Fact, false);
        Audit.AssertGroupNotPosted(Fact, true);
        Link.SetRange("Fact Entry No.", Fact."Entry No.");
        if not Link.FindSet() then
            Error('PF-02: немає підготовлених журналів.');
        repeat
            if OriginalDate = 0D then
                OriginalDate := Link."Expected Posting Date";
            if Link."Expected Posting Date" <> OriginalDate then
                Error('PF-02: у рядків факту різні початкові дати проведення.');
        until Link.Next() = 0;
        if PostingDate = OriginalDate then begin
            Message('PF-02: дата журналів уже %1. Нічого не змінено.', PostingDate);
            exit;
        end;
        if not Confirm('PF-02: змінити Posting Date для всіх журналів факту %1 з %2 на %3? Дата виробництва та номер документа не зміняться.',
            false, Fact."Entry No.", OriginalDate, PostingDate) then
            exit;
        Link.Reset();
        Link.SetRange("Fact Entry No.", Fact."Entry No.");
        if Link.FindSet(true) then
            repeat
                if not JournalLine.Get(Link."Journal Template", Link."Journal Batch", Link."Journal Line No.") then
                    Error('PF-02: рядок журналу %1 відсутній.', Link."Link Line No.");
                DocumentNo := Link."Document No.";
                JournalLine.Validate("Posting Date", PostingDate);
                // Keep the No. Series document identity even if BC field validation
                // changes the journal Document No. as a side effect.
                JournalLine.Validate("Document No.", DocumentNo);
                JournalLine.Modify(true);
                if (JournalLine."Posting Date" <> PostingDate) or
                   (JournalLine."Document No." <> DocumentNo) then
                    Error('PF-02: BC змінив дату або номер документа рядка %1.', Link."Link Line No.");
                Link."Expected Posting Date" := PostingDate;
                Link."Reconciliation Status" := Link."Reconciliation Status"::NotChecked;
                Link."Reconciliation Details" := 'Дата проведення змінена за налаштованою політикою; потрібна повторна звірка.';
                Link."Reconciled At" := 0DT;
                Link.Modify(true);
                Changed += 1;
            until Link.Next() = 0;
        // If date validation altered any other accounting field, this assertion
        // aborts the entire transaction, rolling back every journal/link change.
        Recon.AssertReady(Fact);
        Audit.AssertGroupNotPosted(Fact, false);
        Audit.AssertGroupNotPosted(Fact, true);
        if StartedAttempt then
            Message('PF-02: дату змінено на %1 у %2 рядках. Спроба Started збережена; наступна дія — «Відновити непроведену спробу (Sandbox)». Проведення НЕ виконувалося.',
                PostingDate, Changed)
        else
            Message('PF-02: дату змінено на %1 у %2 рядках. Проведення НЕ виконувалося.', PostingDate, Changed);
    end;

    // One standard BC No. Series number for the whole physical Production Fact.
    // All mutations (series, Fact, journal lines, links) stay in one transaction.
    local procedure AllocateDocumentNo(SeriesCode: Code[20]; UsageDate: Date): Code[20]
    var
        NoSeries: Codeunit "No. Series";
        DocumentNo: Code[20];
    begin
        NoSeries.TestAutomatic(SeriesCode);
        DocumentNo := NoSeries.GetNextNo(SeriesCode, UsageDate);
        if DocumentNo = '' then
            Error('PF-02.2B: серія %1 не повернула номер документа.', SeriesCode);
        AssertDocumentNoUnused(DocumentNo);
        exit(DocumentNo);
    end;

    local procedure AssertDocumentNoUnused(DocumentNo: Code[20])
    var
        JournalLine: Record "Item Journal Line";
        Link: Record "SI Prok Journal Link";
        FactWithNumber: Record "SI Prok Production Fact";
        Ledger: Record "Item Ledger Entry";
    begin
        JournalLine.SetRange("Document No.", DocumentNo);
        if not JournalLine.IsEmpty() then
            Error('PF-02.2B: документ %1 вже використано в журналі товарів.', DocumentNo);
        Link.SetRange("Document No.", DocumentNo);
        if not Link.IsEmpty() then
            Error('PF-02.2B: документ %1 вже використано в зв’язках фактів.', DocumentNo);
        FactWithNumber.SetRange("Accounting Document No.", DocumentNo);
        if not FactWithNumber.IsEmpty() then
            Error('PF-02.2B: документ %1 вже призначено іншому факту.', DocumentNo);
        Ledger.SetRange("Document No.", DocumentNo);
        if not Ledger.IsEmpty() then
            Error('PF-02.2B: документ %1 вже має проведені Item Ledger Entries.', DocumentNo);
    end;

    // Migrates already prepared 1.0.0.79 lines (including TC-01) in Sandbox.
    // It does NOT recreate, delete or post anything; existing snapshots must match.
    procedure RenumberPreparedSandbox(var Fact: Record "SI Prok Production Fact")
    var
        Env: Codeunit "Environment Information";
        Setup: Record "SI Prok Journal Setup";
        Attempt: Record "SI Prok Posting Attempt";
        Link: Record "SI Prok Journal Link";
        JournalLine: Record "Item Journal Line";
        Ledger: Record "Item Ledger Entry";
        Recon: Codeunit "SI Prok Journal Reconciliation";
        OldDocumentNo: Code[20];
        NewDocumentNo: Code[20];
        UsageDate: Date;
        LinkCount: Integer;
        Safety: Codeunit "SI Prok Prod Safe Guard";
    begin
        Safety.AssertDisabled('Перенумерація журналу');
        if not Env.IsSandbox() then
            Error('PF-02.2B: перенумерація підготовлених журналів дозволена лише в Sandbox.');
        Fact.Get(Fact."Entry No.");
        if Fact."Accounting Document No." <> '' then
            Error('PF-02.2B: факту вже призначено документ %1. Повторна перенумерація заборонена.', Fact."Accounting Document No.");
        if Attempt.Get(Fact."Production UUID") then
            Error('PF-02.2B: для UUID уже була спроба проведення. Перенумерацію заборонено.');
        if not Setup.Get('DEFAULT') then
            Error('PF-02.2B: відсутні налаштування виробничих журналів Proktek.');
        Setup.TestField("Document No. Series");
        // Verifies all seven current journal rows against immutable snapshots and
        // source materials without assuming a hardcoded document number or date.
        Recon.AssertPreparedForRenumber(Fact);
        Link.LockTable();
        Link.SetRange("Fact Entry No.", Fact."Entry No.");
        Link.SetRange("Material Line No.", 0);
        if Link.Count() <> 1 then
            Error('PF-02.2B: для перенумерації потрібен один Output link.');
        Link.FindFirst();
        OldDocumentNo := Link."Document No.";
        UsageDate := Link."Expected Posting Date";
        if (OldDocumentNo = '') or (UsageDate = 0D) then
            Error('PF-02.2B: старий номер документа або дата журналу відсутні.');
        Ledger.SetRange("Document No.", OldDocumentNo);
        Ledger.SetRange("Order No.", Fact."BC Prod. Order No.");
        if not Ledger.IsEmpty() then
            Error('PF-02.2B: за документом %1 вже є проведені записи виробничого замовлення. Перенумерація заборонена.', OldDocumentNo);
        NewDocumentNo := AllocateDocumentNo(Setup."Document No. Series", UsageDate);
        if NewDocumentNo = Fact."BC Prod. Order No." then
            Error('PF-02.2B: серія номерів повернула номер виробничого замовлення. Налаштуйте окрему серію.');
        Fact."Accounting Document No." := NewDocumentNo;
        Fact.Modify(true);
        Link.Reset();
        Link.SetRange("Fact Entry No.", Fact."Entry No.");
        if Link.FindSet(true) then
            repeat
                if not JournalLine.Get(Link."Journal Template", Link."Journal Batch", Link."Journal Line No.") then
                    Error('PF-02.2B: відсутній рядок журналу %1.', Link."Link Line No.");
                JournalLine.Validate("Document No.", NewDocumentNo);
                JournalLine.Modify(true);
                Link."Document No." := NewDocumentNo;
                // Anchor the migrated link to the actual BC journal record instance.
                Link."Journal Line SystemId" := JournalLine.SystemId;
                Link."Reconciliation Status" := Link."Reconciliation Status"::NotChecked;
                Link."Reconciliation Details" := 'Номер документа призначено через стандартну No. Series; потрібна повторна звірка.';
                Link.Modify(true);
                LinkCount += 1;
            until Link.Next() = 0;
        Recon.AssertReady(Fact);
        Message('PF-02.2B: номер %1 призначено факту %2; оновлено %3 рядків і зв’язків. Проведення НЕ виконувалося.',
            NewDocumentNo, Fact."Entry No.", LinkCount);
    end;

    local procedure ValidateBatch(TemplateCode: Code[10]; BatchCode: Code[10]; var Template: Record "Item Journal Template"; var Batch: Record "Item Journal Batch")
    begin
        if not Template.Get(TemplateCode) then
            Error('PF-02.2B: шаблон %1 не знайдено.', TemplateCode);
        if Template.Type <> Template.Type::Item then
            Error('PF-02.2B: шаблон %1 повинен мати тип Item.', TemplateCode);
        if Template.Recurring then
            Error('PF-02.2B: recurring journal заборонено.');
        if not Batch.Get(TemplateCode, BatchCode) then
            Error('PF-02.2B: пакет %1/%2 не знайдено.', TemplateCode, BatchCode);
        if (Batch."No. Series" <> '') or (Batch."Posting No. Series" <> '') then
            Error('PF-02.2B: у пакеті %1/%2 очистіть No. Series та Posting No. Series. Номер для всього факту призначає налаштована серія Proktek.',
                TemplateCode, BatchCode);
    end;

    local procedure NextLineNo(TemplateCode: Code[10]; BatchCode: Code[10]): Integer
    var
        Jnl: Record "Item Journal Line";
    begin
        Jnl.LockTable();
        Jnl.SetRange("Journal Template Name", TemplateCode);
        Jnl.SetRange("Journal Batch Name", BatchCode);
        if Jnl.FindLast() then
            exit(Jnl."Line No." + 10000);
        exit(10000);
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
        Link."Expected Order No." := Jnl."Order No.";
        Link."Expected Order Line No." := Jnl."Order Line No.";
        Link."Expected Component Line No." := Jnl."Prod. Order Comp. Line No.";
        Link."Snapshot Available" := true;
        Link."Prepared At" := CurrentDateTime();
        Link."Prepared By" := CopyStr(UserId(), 1, MaxStrLen(Link."Prepared By"));
        Link.Insert(true);
    end;
}
