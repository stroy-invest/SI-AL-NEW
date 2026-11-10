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
        Env: Codeunit "Environment Information";
        Prep: Codeunit "SI Prok Accounting Prep Mgt.";
        DocumentNo: Code[20];
        NextOutputLine: Integer;
        NextConsumptionLine: Integer;
        LinkNo: Integer;
        ConsumptionQty: Decimal;
    begin
        Fact.Get(Fact."Entry No.");
        // Re-run the entire readiness contract immediately before journal insertion.
        Prep.CheckFact(Fact, Fact."Accounting Prep Mode");
        Fact.Get(Fact."Entry No.");
        if Fact."Accounting Readiness" <> Fact."Accounting Readiness"::Ready then
            Error('PF-02.2B: факт не готовий: %1', Fact."Accounting Diagnostics");
        if (Fact."Accounting Prep Mode" = Fact."Accounting Prep Mode"::Simulation) and not Env.IsSandbox() then
            Error('PF-02.2B: Simulation заборонена поза Sandbox.');
        if Fact."Production Date/Time" = 0DT then
            Error('PF-02.2B: дата/час факту відсутні.');
        if IsNullGuid(Fact."Production UUID") then
            Error('PF-02.2B: Production UUID порожній.');

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
        if (Setup."Output Template" = Setup."Consumption Template") and
           (Setup."Output Batch" = Setup."Consumption Batch") then
            Error('PF-02.2B: Output і Consumption повинні використовувати різні пакети.');
        ValidateBatch(Setup."Output Template", Setup."Output Batch", OutputTemplate, OutputBatch);
        ValidateBatch(Setup."Consumption Template", Setup."Consumption Batch", ConsumptionTemplate, ConsumptionBatch);
        ProdOrder.Get(Fact."BC Prod. Order Status", Fact."BC Prod. Order No.");
        ProdOrder.TestField(Status, ProdOrder.Status::Released);
        ProdLine.Get(ProdOrder.Status, ProdOrder."No.", Fact."BC Prod. Order Line No.");
        DocumentNo := CopyStr(StrSubstNo('PRK-%1', Fact."Entry No."), 1, MaxStrLen(DocumentNo));
        AssertNoDocumentCollision(Setup."Output Template", Setup."Output Batch", DocumentNo);
        AssertNoDocumentCollision(Setup."Consumption Template", Setup."Consumption Batch", DocumentNo);
        NextOutputLine := NextLineNo(Setup."Output Template", Setup."Output Batch");
        NextConsumptionLine := NextLineNo(Setup."Consumption Template", Setup."Consumption Batch");

        OutputLine.Init();
        OutputLine."Journal Template Name" := Setup."Output Template";
        OutputLine."Journal Batch Name" := Setup."Output Batch";
        OutputLine."Line No." := NextOutputLine;
        OutputLine.Insert(true);
        OutputLine.Validate("Posting Date", DT2Date(Fact."Production Date/Time"));
        OutputLine.Validate("Document No.", DocumentNo);
        OutputLine.Validate("Entry Type", OutputLine."Entry Type"::Output);
        OutputLine.Validate("Order Type", OutputLine."Order Type"::Production);
        OutputLine.Validate("Order No.", ProdOrder."No.");
        OutputLine.Validate("Order Line No.", ProdLine."Line No.");
        OutputLine.Validate("Item No.", ProdLine."Item No.");
        OutputLine.Validate("Variant Code", ProdLine."Variant Code");
        OutputLine.Validate("Location Code", ProdLine."Location Code");
        OutputLine.Validate("Unit of Measure Code", ProdLine."Unit of Measure Code");
        OutputLine.Validate("Output Quantity", Fact."Accounting Output Qty");
        OutputLine.Modify(true);
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
                if Component."Flushing Method" <> Component."Flushing Method"::Manual then
                    Error('PF-02.2B: компонент %1: Flushing Method повинен бути Manual.', Component."Item No.");
                if not ItemUoM.Get(Material."Item No.", Component."Unit of Measure Code") then
                    Error('PF-02.2B: не знайдено одиницю %1 для %2.', Component."Unit of Measure Code", Material."Item No.");
                ItemUoM.TestField("Qty. per Unit of Measure");
                ConsumptionQty := Material."Actual Base Qty" / ItemUoM."Qty. per Unit of Measure";
                if ConsumptionQty < 0 then
                    Error('PF-02.2B: від’ємна кількість матеріалу %1.', Material."Item No.");
                // Zero actual consumption is evidence, but not a journal transaction.
                if ConsumptionQty > 0 then begin
                    ConsumptionLine.Init();
                    ConsumptionLine."Journal Template Name" := Setup."Consumption Template";
                    ConsumptionLine."Journal Batch Name" := Setup."Consumption Batch";
                    ConsumptionLine."Line No." := NextConsumptionLine;
                    ConsumptionLine.Insert(true);
                    ConsumptionLine.Validate("Posting Date", DT2Date(Fact."Production Date/Time"));
                    ConsumptionLine.Validate("Document No.", DocumentNo);
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
                    ConsumptionLine.Modify(true);
                    LinkNo += 10000;
                    SaveLink(Fact, LinkNo, Material."Line No.", ConsumptionLine);
                    NextConsumptionLine += 10000;
                end;
            until Material.Next() = 0;
        Message('PF-02.2B: підготовлено Output та %1 рядків Consumption. Журнали НЕ проведено.', (LinkNo - 10000) / 10000);
    end;

    local procedure AssertNoDocumentCollision(TemplateCode: Code[10]; BatchCode: Code[10]; DocumentNo: Code[20])
    var
        JournalLine: Record "Item Journal Line";
    begin
        JournalLine.SetRange("Journal Template Name", TemplateCode);
        JournalLine.SetRange("Journal Batch Name", BatchCode);
        JournalLine.SetRange("Document No.", DocumentNo);
        if not JournalLine.IsEmpty() then
            Error('PF-02.2B: у пакеті %1/%2 вже є документ %3.', TemplateCode, BatchCode, DocumentNo);
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
        Link."Document No." := Jnl."Document No.";
        Link."Prepared At" := CurrentDateTime();
        Link."Prepared By" := CopyStr(UserId(), 1, MaxStrLen(Link."Prepared By"));
        Link.Insert(true);
    end;
}
