codeunit 57140 "SI Prok Process Control"
{
    // SI Process Production Stage 2. READ-ONLY checks and ledger audit.
    // No Production Order, Assembly, WIP or cost allocation.
    // Journal Link snapshots from 1.0.0.84 are reused without migration.

    procedure CheckReady(Fact: Record "SI Prok Production Fact")
    var
        Attempt: Record "SI Prok Posting Attempt";
        CountLines: Integer;
        Posted: Integer;
        Missing: Integer;
    begin
        if Attempt.Get(Fact."Production UUID") then
            Error('SI Process: вже існує спроба проведення (%1). Використайте діагностику, не запускайте нове проведення.', Attempt.Status);
        if LedgerStatus(Fact, Posted, Missing) <> 0 then
            Error('SI Process: за документом уже є проведені записи. Повторне проведення заборонено.');
        CountLines := AssertPrepared(Fact);
        Message('SI Process: факт %1, документ %2. Перевірено %3 непроведених рядків; проведених записів немає. Жодних змін не виконано.',
            Fact."Entry No.", Fact."Accounting Document No.", CountLines);
    end;

    // Must be called again immediately before posting, not only on a prior UI check.
    procedure AssertPrepared(Fact: Record "SI Prok Production Fact"): Integer
    var
        Setup: Record "SI Prok Journal Setup";
        Template: Record "Item Journal Template";
        Batch: Record "Item Journal Batch";
        Link: Record "SI Prok Journal Link";
        OtherLink: Record "SI Prok Journal Link";
        JournalLine: Record "Item Journal Line";
        Material: Record "SI Prok Prod Fact Material";
        Item: Record Item;
        ItemUoM: Record "Item Unit of Measure";
        InventorySetup: Record "Inventory Posting Setup";
        GeneralSetup: Record "General Posting Setup";
        Semantics: Codeunit "SI Prok Location Semantics";
        MaterialCount: Integer;
        OutputCount: Integer;
        ExpectedMaterialCount: Integer;
        LinkCount: Integer;
    begin
        AssertProcessIdentity(Fact);
        if Fact."Accounting Readiness" <> Fact."Accounting Readiness"::Ready then
            Error('SI Process: факт %1 не має статусу Ready.', Fact."Entry No.");
        if Fact."Accounting Output Qty" <> Fact."Produced Quantity M3" then
            Error('SI Process: підготовлений обсяг відрізняється від факту MES.');
        if not Setup.Get('DEFAULT') then
            Error('SI Process: налаштування журналів Proktek відсутні.');
        Setup.TestField("Process Template");
        Setup.TestField("Process Batch");
        Setup.TestField("Process Business Group");
        if not Template.Get(Setup."Process Template") then
            Error('SI Process: шаблон журналу %1 не знайдено.', Setup."Process Template");
        if (Template.Type <> Template.Type::Item) or Template.Recurring then
            Error('SI Process: потрібен звичайний Item Journal, не виробничий і не recurring.');
        if not Batch.Get(Setup."Process Template", Setup."Process Batch") then
            Error('SI Process: пакет %1/%2 не знайдено.', Setup."Process Template", Setup."Process Batch");
        if (Batch."No. Series" <> '') or (Batch."Posting No. Series" <> '') then
            Error('SI Process: пакет має використовувати номер документа, призначений Proktek; No. Series у пакеті повинні бути порожні.');

        OtherLink.SetRange("Document No.", Fact."Accounting Document No.");
        OtherLink.SetFilter("Fact Entry No.", '<>%1', Fact."Entry No.");
        if not OtherLink.IsEmpty() then
            Error('SI Process: номер документа використано іншим виробничим фактом.');
        Link.SetRange("Fact Entry No.", Fact."Entry No.");
        if not Link.FindSet() then
            Error('SI Process: для факту %1 немає Journal Links.', Fact."Entry No.");
        repeat
            LinkCount += 1;
            if not Link."Snapshot Available" then
                Error('SI Process: зв’язок %1 не має контрольного знімка.', Link."Link Line No.");
            if (Link."Production UUID" <> Fact."Production UUID") or
               (Link."Document No." <> Fact."Accounting Document No.") then
                Error('SI Process: UUID/номер документа не збігається у зв’язку %1.', Link."Link Line No.");
            if (Link."Journal Template" <> Setup."Process Template") or
               (Link."Journal Batch" <> Setup."Process Batch") then
                Error('SI Process: зв’язок %1 належить іншому пакету.', Link."Link Line No.");
            if Link."Expected Gen. Bus. Group" <> Setup."Process Business Group" then
                Error('SI Process: бізнес-групу змінено після підготовки (зв’язок %1).', Link."Link Line No.");
            if (Link."Expected Order No." <> '') or (Link."Expected Order Line No." <> 0) or
               (Link."Expected Component Line No." <> 0) then
                Error('SI Process: зв’язок %1 не повинен посилатися на Production Order.', Link."Link Line No.");
            if IsNullGuid(Link."Journal Line SystemId") then
                Error('SI Process: зв’язок %1 не має SystemId фізичного рядка.', Link."Link Line No.");
            if not JournalLine.Get(Link."Journal Template", Link."Journal Batch", Link."Journal Line No.") then
                Error('SI Process: рядок журналу %1 відсутній. Проведення заблоковано.', Link."Link Line No.");
            if not IsExactJournalMatch(Link, JournalLine) then
                Error('SI Process: рядок журналу %1 змінено після підготовки. Проведення заблоковано.', Link."Link Line No.");
            if not Item.Get(Link."Expected Item No.") then
                Error('SI Process: товар %1 не знайдено.', Link."Expected Item No.");
            if Item.Type <> Item.Type::Inventory then
                Error('SI Process: товар %1 не є складським.', Item."No.");
            if (JournalLine."Inventory Posting Group" <> Item."Inventory Posting Group") or
               (JournalLine."Gen. Prod. Posting Group" <> Item."Gen. Prod. Posting Group") then
                Error('SI Process: облікові групи товару %1 змінилися після підготовки.', Item."No.");
            if not InventorySetup.Get(JournalLine."Location Code", JournalLine."Inventory Posting Group") then
                Error('SI Process: немає Inventory Posting Setup для %1 + %2.',
                    JournalLine."Location Code", JournalLine."Inventory Posting Group");
            if not GeneralSetup.Get(JournalLine."Gen. Bus. Posting Group", JournalLine."Gen. Prod. Posting Group") then
                Error('SI Process: немає General Posting Setup для %1 + %2.',
                    JournalLine."Gen. Bus. Posting Group", JournalLine."Gen. Prod. Posting Group");
            GeneralSetup.TestField("Inventory Adjmt. Account");
            if not ItemUoM.Get(Item."No.", Link."Expected UoM") then
                Error('SI Process: для товару %1 відсутня ОВ %2.', Item."No.", Link."Expected UoM");
            ItemUoM.TestField("Qty. per Unit of Measure");
            if Link."Material Line No." = 0 then begin
                Semantics.AssertFinishedGoods(Link."Expected Location Code");
                OutputCount += 1;
                if (Link."Expected Entry Type" <> Link."Expected Entry Type"::"Positive Adjmt.") or
                   (Link."Expected Item No." <> Fact."Item No.") or
                   (Link."Expected Variant Code" <> Fact."Variant Code") or
                   ((Link."Expected UoM" <> 'M3') and (Link."Expected UoM" <> 'М3')) or
                   (Link."Expected Quantity" <> Fact."Produced Quantity M3") then
                    Error('SI Process: рядок надходження не відповідає фактичному випуску.');
            end else begin
                Semantics.AssertMaterial(Link."Expected Location Code");
                MaterialCount += 1;
                if not Material.Get(Fact."Entry No.", Link."Material Line No.") then
                    Error('SI Process: матеріал %1 не знайдено у факті.', Link."Material Line No.");
                if (Link."Expected Entry Type" <> Link."Expected Entry Type"::"Negative Adjmt.") or
                   (Link."Expected Item No." <> Material."Item No.") or
                   (Link."Expected Variant Code" <> Material."Variant Code") or
                   (Link."Expected UoM" <> Item."Base Unit of Measure") or
                   (Link."Expected Quantity" <> Round(Material."Actual Base Qty", 0.00001)) or
                   (Material."Actual Base Qty" <= 0) then
                    Error('SI Process: списання матеріалу %1 не відповідає факту MES.', Material."Line No.");
            end;
        until Link.Next() = 0;
        if OutputCount <> 1 then
            Error('SI Process: очікується одне надходження; знайдено %1.', OutputCount);
        Material.SetRange("Production Fact Entry No.", Fact."Entry No.");
        if Material.FindSet() then
            repeat
                if Material."Actual Base Qty" > 0 then begin
                    ExpectedMaterialCount += 1;
                    Link.Reset();
                    Link.SetRange("Fact Entry No.", Fact."Entry No.");
                    Link.SetRange("Material Line No.", Material."Line No.");
                    if Link.Count() <> 1 then
                        Error('SI Process: матеріал %1 повинен мати рівно один Journal Link.', Material."Line No.");
                end;
            until Material.Next() = 0;
        if (ExpectedMaterialCount = 0) or (MaterialCount <> ExpectedMaterialCount) or
           (Fact."Accounting Material Lines" <> MaterialCount) then
            Error('SI Process: неповний набір матеріалів: %1/%2.', MaterialCount, ExpectedMaterialCount);
        JournalLine.Reset();
        JournalLine.SetRange("Journal Template Name", Setup."Process Template");
        JournalLine.SetRange("Journal Batch Name", Setup."Process Batch");
        if JournalLine.Count() <> LinkCount then
            Error('SI Process: пакет %1/%2 містить сторонні або відсутні рядки (журнал %3, зв’язки %4).',
                Setup."Process Template", Setup."Process Batch", JournalLine.Count(), LinkCount);
        exit(LinkCount);
    end;

    // 0 = no posted ledger entries, 1 = fully posted, 2 = partially posted.
    // Any foreign or quantitatively inconsistent ledger entry causes an error,
    // NEVER an automatic retry or an optimistic "posted" status.
    procedure LedgerStatus(Fact: Record "SI Prok Production Fact"; var PostedGroups: Integer; var MissingGroups: Integer): Integer
    var
        Link: Record "SI Prok Journal Link";
        OtherLink: Record "SI Prok Journal Link";
        Ledger: Record "Item Ledger Entry";
        ItemUoM: Record "Item Unit of Measure";
        Seen: Dictionary of [Text, Boolean];
        GroupKey: Text;
        ExpectedBase: Decimal;
        PostedBase: Decimal;
    begin
        PostedGroups := 0;
        MissingGroups := 0;
        AssertProcessIdentity(Fact);
        AssertNoForeignLedger(Fact);
        Link.SetRange("Fact Entry No.", Fact."Entry No.");
        if not Link.FindSet() then
            Error('SI Process: немає контрольних Journal Links для аудиту.');
        repeat
            AssertLinkIdentity(Fact, Link);
            GroupKey := StrSubstNo('%1|%2|%3|%4|%5|%6',
                Format(Link."Expected Entry Type"), Link."Expected Item No.",
                Link."Expected Variant Code", Link."Expected Location Code",
                Format(Link."Expected Posting Date"), Link."Expected UoM");
            if not Seen.ContainsKey(GroupKey) then begin
                Seen.Add(GroupKey, true);
                if not ItemUoM.Get(Link."Expected Item No.", Link."Expected UoM") then
                    Error('SI Process: відсутня ОВ %1 для товару %2.', Link."Expected UoM", Link."Expected Item No.");
                ItemUoM.TestField("Qty. per Unit of Measure");
                OtherLink.Reset();
                OtherLink.SetRange("Fact Entry No.", Fact."Entry No.");
                OtherLink.SetRange("Expected Entry Type", Link."Expected Entry Type");
                OtherLink.SetRange("Expected Item No.", Link."Expected Item No.");
                OtherLink.SetRange("Expected Variant Code", Link."Expected Variant Code");
                OtherLink.SetRange("Expected Location Code", Link."Expected Location Code");
                OtherLink.SetRange("Expected Posting Date", Link."Expected Posting Date");
                OtherLink.SetRange("Expected UoM", Link."Expected UoM");
                ExpectedBase := 0;
                if OtherLink.FindSet() then
                    repeat
                        AssertLinkIdentity(Fact, OtherLink);
                        ExpectedBase += OtherLink."Expected Quantity";
                    until OtherLink.Next() = 0;
                ExpectedBase := Round(ExpectedBase * ItemUoM."Qty. per Unit of Measure", 0.00001);
                if Link."Expected Entry Type" = Link."Expected Entry Type"::"Negative Adjmt." then
                    ExpectedBase := -ExpectedBase;
                Ledger.Reset();
                Ledger.SetRange("Document No.", Fact."Accounting Document No.");
                Ledger.SetRange("Entry Type", Link."Expected Entry Type");
                Ledger.SetRange("Item No.", Link."Expected Item No.");
                Ledger.SetRange("Variant Code", Link."Expected Variant Code");
                Ledger.SetRange("Location Code", Link."Expected Location Code");
                Ledger.SetRange("Posting Date", Link."Expected Posting Date");
                PostedBase := 0;
                if Ledger.FindSet() then
                    repeat
                        if Ledger."Unit of Measure Code" <> Link."Expected UoM" then
                            Error('SI Process: одиниця проведеного запису %1 відрізняється від знімка.', Ledger."Entry No.");
                        PostedBase += Ledger.Quantity;
                    until Ledger.Next() = 0;
                PostedBase := Round(PostedBase, 0.00001);
                if PostedBase = 0 then
                    MissingGroups += 1
                else
                    if PostedBase = ExpectedBase then
                        PostedGroups += 1
                    else
                        Error('SI Process: неоднозначне проведення %1: фактично %2, очікується %3. Автоматичне відновлення заборонено.',
                            Link."Expected Item No.", PostedBase, ExpectedBase);
            end;
        until Link.Next() = 0;
        if PostedGroups = 0 then
            exit(0);
        if MissingGroups = 0 then
            exit(1);
        exit(2);
    end;

    procedure Review(Fact: Record "SI Prok Production Fact")
    var
        Attempt: Record "SI Prok Posting Attempt";
        Posted: Integer;
        Missing: Integer;
        State: Integer;
        AttemptText: Text;
    begin
        State := LedgerStatus(Fact, Posted, Missing);
        AttemptText := 'немає';
        if Attempt.Get(Fact."Production UUID") then
            AttemptText := Format(Attempt.Status);
        Message('SI Process Audit: факт %1, документ %2. Спроба: %3. Проведено груп: %4, відсутні: %5. Стан: %6 (0 = нічого, 1 = повністю, 2 = частково). Нічого не змінено.',
            Fact."Entry No.", Fact."Accounting Document No.", AttemptText, Posted, Missing, State);
    end;

    local procedure AssertProcessIdentity(Fact: Record "SI Prok Production Fact")
    begin
        if Fact."Accounting Posting Model" <> Fact."Accounting Posting Model"::"Process Adjustment" then
            Error('SI Process: факт %1 належить до попередньої моделі Production Order.', Fact."Entry No.");
        if IsNullGuid(Fact."Production UUID") then
            Error('SI Process: Production UUID відсутній.');
        Fact.TestField("Accounting Document No.");
    end;

    local procedure AssertLinkIdentity(Fact: Record "SI Prok Production Fact"; Link: Record "SI Prok Journal Link")
    begin
        if (Link."Production UUID" <> Fact."Production UUID") or
           (Link."Document No." <> Fact."Accounting Document No.") or
           (not Link."Snapshot Available") then
            Error('SI Process: зв’язок %1 має недостовірний UUID/документ/знімок.', Link."Link Line No.");
        if Link."Material Line No." = 0 then begin
            if Link."Expected Entry Type" <> Link."Expected Entry Type"::"Positive Adjmt." then
                Error('SI Process: рядок випуску %1 повинен бути Positive Adjustment.', Link."Link Line No.");
        end else
            if Link."Expected Entry Type" <> Link."Expected Entry Type"::"Negative Adjmt." then
                Error('SI Process: рядок матеріалу %1 повинен бути Negative Adjustment.', Link."Link Line No.");
        if (Link."Expected Quantity" <= 0) or (Link."Expected Posting Date" = 0D) then
            Error('SI Process: некоректна кількість/дата у зв’язку %1.', Link."Link Line No.");
        if (Link."Expected Order No." <> '') or (Link."Expected Order Line No." <> 0) or
           (Link."Expected Component Line No." <> 0) then
            Error('SI Process: зв’язок %1 має Production Order identity.', Link."Link Line No.");
    end;

    local procedure IsExactJournalMatch(Link: Record "SI Prok Journal Link"; Line: Record "Item Journal Line"): Boolean
    begin
        exit((Line.SystemId = Link."Journal Line SystemId") and
             (Line."Document No." = Link."Document No.") and
             (Line."Posting No. Series" = '') and
             (Line."Entry Type" = Link."Expected Entry Type") and
             (Line."Item No." = Link."Expected Item No.") and
             (Line."Variant Code" = Link."Expected Variant Code") and
             (Line."Location Code" = Link."Expected Location Code") and
             (Line."Bin Code" = Link."Expected Bin Code") and
             (Line.Quantity = Link."Expected Quantity") and
             (Line."Unit of Measure Code" = Link."Expected UoM") and
             (Line."Posting Date" = Link."Expected Posting Date") and
             (Line."Gen. Bus. Posting Group" = Link."Expected Gen. Bus. Group") and
             (Line."Order No." = '') and
             (Line."Order Line No." = 0) and
             (Line."Prod. Order Comp. Line No." = 0));
    end;

    local procedure AssertNoForeignLedger(Fact: Record "SI Prok Production Fact")
    var
        Ledger: Record "Item Ledger Entry";
        Link: Record "SI Prok Journal Link";
        OtherLink: Record "SI Prok Journal Link";
        Matched: Boolean;
    begin
        OtherLink.SetRange("Document No.", Fact."Accounting Document No.");
        OtherLink.SetFilter("Fact Entry No.", '<>%1', Fact."Entry No.");
        if not OtherLink.IsEmpty() then
            Error('SI Process: номер документа %1 використовується іншим фактом.', Fact."Accounting Document No.");
        Ledger.SetRange("Document No.", Fact."Accounting Document No.");
        if Ledger.FindSet() then
            repeat
                if (Ledger."Order No." <> '') or (Ledger."Order Line No." <> 0) then
                    Error('SI Process: сторонній виробничий запис Item Ledger %1.', Ledger."Entry No.");
                Matched := false;
                Link.Reset();
                Link.SetRange("Fact Entry No.", Fact."Entry No.");
                if Link.FindSet() then
                    repeat
                        if (Link."Expected Entry Type" = Ledger."Entry Type") and
                           (Link."Expected Item No." = Ledger."Item No.") and
                           (Link."Expected Variant Code" = Ledger."Variant Code") and
                           (Link."Expected Location Code" = Ledger."Location Code") and
                           (Link."Expected Posting Date" = Ledger."Posting Date") and
                           (Link."Expected UoM" = Ledger."Unit of Measure Code") then
                            Matched := true;
                    until (Link.Next() = 0) or Matched;
                if not Matched then
                    Error('SI Process: сторонній запис Item Ledger %1 у документі %2. Ручний розбір.',
                        Ledger."Entry No.", Fact."Accounting Document No.");
            until Ledger.Next() = 0;
    end;
}
