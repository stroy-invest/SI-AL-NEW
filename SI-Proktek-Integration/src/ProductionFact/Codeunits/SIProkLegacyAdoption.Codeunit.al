codeunit 57127 "SI Prok Legacy Adoption"
{
    // Sandbox-only migration of pre-PF-02.2C links. No journals are created or posted.
    // Baseline is accepted only after independently reconstructing expected rows
    // from the Production Fact and the Released Production Order.
    procedure AdoptSandbox(var Fact: Record "SI Prok Production Fact")
    var
        Env: Codeunit "Environment Information";
        Link: Record "SI Prok Journal Link";
        OtherLink: Record "SI Prok Journal Link";
        Jnl: Record "Item Journal Line";
        Ledger: Record "Item Ledger Entry";
        Attempt: Record "SI Prok Posting Attempt";
        Material: Record "SI Prok Prod Fact Material";
        Component: Record "Prod. Order Component";
        ProdLine: Record "Prod. Order Line";
        ItemUoM: Record "Item Unit of Measure";
        Prep: Codeunit "SI Prok Accounting Prep Mgt.";
        Recon: Codeunit "SI Prok Journal Reconciliation";
        ExpectedQty: Decimal;
        ExpectedCount: Integer;
        LinkCount: Integer;
        OutputCount: Integer;
        MaterialCount: Integer;
    begin
        if not Env.IsSandbox() then
            Error('PF-02.3 Legacy: прийняття дозволено лише у Sandbox.');
        Fact.Get(Fact."Entry No.");
        if Fact."Accounting Prep Mode" <> Fact."Accounting Prep Mode"::Simulation then
            Error('PF-02.3 Legacy: потрібен режим Simulation.');
        if IsNullGuid(Fact."Production UUID") then
            Error('PF-02.3 Legacy: Production UUID відсутній.');
        if Attempt.Get(Fact."Production UUID") then
            Error('PF-02.3 Legacy: для UUID вже є спроба проведення.');
        Prep.CheckFact(Fact, Fact."Accounting Prep Mode"::Simulation);
        Fact.Get(Fact."Entry No.");
        if Fact."Accounting Readiness" <> Fact."Accounting Readiness"::Ready then
            Error('PF-02.3 Legacy: факт не готовий: %1', Fact."Accounting Diagnostics");
        ProdLine.Get(Fact."BC Prod. Order Status", Fact."BC Prod. Order No.", Fact."BC Prod. Order Line No.");
        Link.LockTable();
        Link.SetRange("Fact Entry No.", Fact."Entry No.");
        if not Link.FindSet(true) then
            Error('PF-02.3 Legacy: зв’язків журналів немає.');
        repeat
            LinkCount += 1;
            if Link."Production UUID" <> Fact."Production UUID" then
                Error('PF-02.3 Legacy: UUID не збігається у зв’язку %1.', Link."Link Line No.");
            if Link."Snapshot Available" then
                Error('PF-02.3 Legacy: зв’язок %1 уже має знімок; змішане або повторне прийняття заборонено.', Link."Link Line No.");
            if not Jnl.Get(Link."Journal Template", Link."Journal Batch", Link."Journal Line No.") then
                Error('PF-02.3 Legacy: рядок журналу %1 відсутній.', Link."Link Line No.");
            if Jnl."Document No." <> CopyStr(StrSubstNo('PRK-%1', Fact."Entry No."), 1, MaxStrLen(Jnl."Document No.")) then
                Error('PF-02.3 Legacy: невірний номер документа у зв’язку %1.', Link."Link Line No.");
            if Jnl."Document No." <> Link."Document No." then
                Error('PF-02.3 Legacy: документ журналу і зв’язку не збігається.');
            if (Jnl."Order Type" <> Jnl."Order Type"::Production) or
               (Jnl."Order No." <> Fact."BC Prod. Order No.") or
               (Jnl."Order Line No." <> Fact."BC Prod. Order Line No.") or
               (Jnl."Posting Date" <> DT2Date(Fact."Production Date/Time")) then
                Error('PF-02.3 Legacy: виробничий контекст не збігається у зв’язку %1.', Link."Link Line No.");
            if Jnl."Unit of Measure Code" = '' then
                Error('PF-02.3 Legacy: ОВ відсутня у зв’язку %1.', Link."Link Line No.");
            // No matching posted ledger entry may already exist for this document/order.
            Ledger.Reset();
            Ledger.SetRange("Document No.", Jnl."Document No.");
            Ledger.SetRange("Order No.", Jnl."Order No.");
            if not Ledger.IsEmpty() then
                Error('PF-02.3 Legacy: існують Item Ledger Entries для документа %1 та замовлення %2. Потрібна ручна перевірка.', Jnl."Document No.", Jnl."Order No.");
            OtherLink.Reset();
            OtherLink.SetRange("Journal Template", Link."Journal Template");
            OtherLink.SetRange("Journal Batch", Link."Journal Batch");
            OtherLink.SetRange("Journal Line No.", Link."Journal Line No.");
            OtherLink.SetFilter("Fact Entry No.", '<>%1', Fact."Entry No.");
            if not OtherLink.IsEmpty() then
                Error('PF-02.3 Legacy: рядок журналу %1 пов’язаний з іншим фактом.', Link."Journal Line No.");
            if Link."Material Line No." = 0 then begin
                OutputCount += 1;
                if (Jnl."Entry Type" <> Jnl."Entry Type"::Output) or
                   (Jnl."Item No." <> ProdLine."Item No.") or
                   (Jnl."Variant Code" <> ProdLine."Variant Code") or
                   (Jnl."Location Code" <> ProdLine."Location Code") or
                   (Jnl."Unit of Measure Code" <> ProdLine."Unit of Measure Code") or
                   (Jnl.Quantity <> Fact."Accounting Output Qty") or
                   (Jnl."Prod. Order Comp. Line No." <> 0) then
                    Error('PF-02.3 Legacy: Output не відповідає виробничому замовленню або факту.');
            end else begin
                if not Material.Get(Fact."Entry No.", Link."Material Line No.") then
                    Error('PF-02.3 Legacy: матеріал %1 не знайдено.', Link."Material Line No.");
                Component.Reset();
                Component.SetRange(Status, Fact."BC Prod. Order Status");
                Component.SetRange("Prod. Order No.", Fact."BC Prod. Order No.");
                Component.SetRange("Prod. Order Line No.", Fact."BC Prod. Order Line No.");
                Component.SetRange("Item No.", Material."Item No.");
                Component.SetRange("Variant Code", Material."Variant Code");
                if Component.Count() <> 1 then
                    Error('PF-02.3 Legacy: компонент %1 неоднозначний.', Material."Item No.");
                Component.FindFirst();
                if Component."Flushing Method" <> Component."Flushing Method"::Manual then
                    Error('PF-02.3 Legacy: компонент %1 не Manual.', Component."Item No.");
                ItemUoM.Get(Material."Item No.", Component."Unit of Measure Code");
                ItemUoM.TestField("Qty. per Unit of Measure");
                ExpectedQty := Material."Actual Base Qty" / ItemUoM."Qty. per Unit of Measure";
                if (ExpectedQty <= 0) or
                   (Jnl."Entry Type" <> Jnl."Entry Type"::Consumption) or
                   (Jnl."Item No." <> Component."Item No.") or
                   (Jnl."Variant Code" <> Component."Variant Code") or
                   (Jnl."Location Code" <> Component."Location Code") or
                   (Jnl."Bin Code" <> Component."Bin Code") or
                   (Jnl."Unit of Measure Code" <> Component."Unit of Measure Code") or
                   (Jnl."Prod. Order Comp. Line No." <> Component."Line No.") or
                   (Jnl.Quantity <> ExpectedQty) then
                    Error('PF-02.3 Legacy: Consumption не відповідає факту та компоненту %1.', Material."Item No.");
                MaterialCount += 1;
            end;
        until Link.Next() = 0;
        if OutputCount <> 1 then
            Error('PF-02.3 Legacy: очікується один Output; знайдено %1.', OutputCount);
        Material.Reset();
        Material.SetRange("Production Fact Entry No.", Fact."Entry No.");
        if Material.FindSet() then
            repeat
                if Material."Actual Base Qty" > 0 then begin
                    ExpectedCount += 1;
                    Link.Reset();
                    Link.SetRange("Fact Entry No.", Fact."Entry No.");
                    Link.SetRange("Material Line No.", Material."Line No.");
                    if Link.Count() <> 1 then
                        Error('PF-02.3 Legacy: для матеріалу %1 потрібен рівно один зв’язок.', Material."Line No.");
                end;
            until Material.Next() = 0;
        if (MaterialCount <> ExpectedCount) or (LinkCount <> ExpectedCount + 1) then
            Error('PF-02.3 Legacy: кількість рядків не збігається з фактичними матеріалами.');
        if not Confirm('PF-02.3 Legacy: прийняти %1 старих рядків для факту %2? Лише Sandbox. Проведення НЕ виконується.', false, LinkCount, Fact."Entry No.") then
            exit;
        // Re-check journal values in the same transaction before persisting snapshots.
        Link.Reset();
        Link.SetRange("Fact Entry No.", Fact."Entry No.");
        if Link.FindSet(true) then
            repeat
                Jnl.Get(Link."Journal Template", Link."Journal Batch", Link."Journal Line No.");
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
                Link."Reconciliation Details" := 'Legacy baseline прийнято в Sandbox після звіряння з Production Fact і Released Production Order.';
                Link.Modify(true);
            until Link.Next() = 0;
        Recon.AssertReady(Fact);
        Message('PF-02.3 Legacy: прийнято %1 контрольних знімків. Тепер виконайте PF-02.2C. Проведення НЕ виконувалося.', LinkCount);
    end;
}
