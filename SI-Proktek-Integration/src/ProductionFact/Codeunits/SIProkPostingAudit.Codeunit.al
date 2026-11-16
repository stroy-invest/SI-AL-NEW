codeunit 57128 "SI Prok Posting Audit"
{
    // A Production UUID has its own PRK document number, even when many
    // UUIDs post to the same Released Production Order.
    // Ledger quantities are in base UoM; consumption entries have negative sign.
    procedure GroupStatus(Fact: Record "SI Prok Production Fact"; IsOutput: Boolean): Integer
    var
        Link: Record "SI Prok Journal Link";
        OtherLink: Record "SI Prok Journal Link";
        Ledger: Record "Item Ledger Entry";
        ItemUoM: Record "Item Unit of Measure";
        Seen: Dictionary of [Text, Boolean];
        GroupKey: Text;
        ExpectedBase: Decimal;
        PostedBase: Decimal;
        QtyPer: Decimal;
        FoundPosted: Boolean;
        FoundMissing: Boolean;
        GroupCount: Integer;
    begin
        if Fact."Accounting Posting Model" = Fact."Accounting Posting Model"::"Process Adjustment" then
            Error('PF-02: аудит Production Order не застосовується до SI Process Production.');
        Fact.TestField("Accounting Document No.");
        AssertLedgerIdentity(Fact);
        Link.SetRange("Fact Entry No.", Fact."Entry No.");
        if not Link.FindSet() then
            Error('PF-02.4: немає контрольних зв’язків журналів факту %1.', Fact."Entry No.");
        repeat
            if (Link."Material Line No." = 0) = IsOutput then begin
                if Link."Document No." <> Fact."Accounting Document No." then
                    Error('PF-02.4: номер документа зв’язку %1 не збігається з фактом.', Link."Link Line No.");
                if not Link."Snapshot Available" then
                    Error('PF-02.4: рядок %1 без контрольного знімка.', Link."Link Line No.");
                GroupKey := StrSubstNo('%1|%2|%3|%4|%5|%6',
                    Format(Link."Expected Entry Type"), Link."Expected Item No.",
                    Link."Expected Variant Code", Link."Expected Location Code",
                    Format(Link."Expected Posting Date"), Link."Expected UoM");
                if not Seen.ContainsKey(GroupKey) then begin
                    Seen.Add(GroupKey, true);
                    GroupCount += 1;
                    ExpectedBase := 0;
                    OtherLink.Reset();
                    OtherLink.SetRange("Fact Entry No.", Fact."Entry No.");
                    OtherLink.SetRange("Expected Entry Type", Link."Expected Entry Type");
                    OtherLink.SetRange("Expected Item No.", Link."Expected Item No.");
                    OtherLink.SetRange("Expected Variant Code", Link."Expected Variant Code");
                    OtherLink.SetRange("Expected Location Code", Link."Expected Location Code");
                    OtherLink.SetRange("Expected Posting Date", Link."Expected Posting Date");
                    OtherLink.SetRange("Expected UoM", Link."Expected UoM");
                    if OtherLink.FindSet() then
                        repeat
                            if (OtherLink."Material Line No." = 0) = IsOutput then
                                ExpectedBase += OtherLink."Expected Quantity";
                        until OtherLink.Next() = 0;
                    if not ItemUoM.Get(Link."Expected Item No.", Link."Expected UoM") then
                        Error('PF-02.4: відсутня ОВ %1 для %2.',
                            Link."Expected UoM", Link."Expected Item No.");
                    QtyPer := ItemUoM."Qty. per Unit of Measure";
                    if QtyPer <= 0 then
                        Error('PF-02.4: некоректна ОВ матеріалу %1.', Link."Expected Item No.");
                    ExpectedBase := Round(ExpectedBase * QtyPer, 0.00001);
                    if not IsOutput then
                        ExpectedBase := -ExpectedBase;

                    Ledger.Reset();
                    Ledger.SetRange("Document No.", Link."Document No.");
                    Ledger.SetRange("Order No.", Link."Expected Order No.");
                    Ledger.SetRange("Order Line No.", Link."Expected Order Line No.");
                    Ledger.SetRange("Entry Type", Link."Expected Entry Type");
                    Ledger.SetRange("Item No.", Link."Expected Item No.");
                    Ledger.SetRange("Variant Code", Link."Expected Variant Code");
                    Ledger.SetRange("Location Code", Link."Expected Location Code");
                    Ledger.SetRange("Posting Date", Link."Expected Posting Date");
                    PostedBase := 0;
                    if Ledger.FindSet() then
                        repeat
                            if Ledger."Unit of Measure Code" <> Link."Expected UoM" then
                                Error('PF-02.4: ОВ проведеного запису %1 не збігається зі знімком.', Ledger."Entry No.");
                            PostedBase += Ledger.Quantity;
                        until Ledger.Next() = 0;
                    PostedBase := Round(PostedBase, 0.00001);
                    if PostedBase = 0 then
                        FoundMissing := true
                    else
                        if PostedBase = ExpectedBase then
                            FoundPosted := true
                        else
                            Error('PF-02.4: проведено %1, очікується %2 (товар %3, документ %4). Необхідний ручний розбір.',
                                PostedBase, ExpectedBase, Link."Expected Item No.", Link."Document No.");
                end;
            end;
        until Link.Next() = 0;
        if GroupCount = 0 then
            exit(0);
        if FoundPosted and FoundMissing then
            exit(2);
        if FoundPosted then
            exit(1);
        exit(0);
    end;

    procedure AssertGroupPosted(Fact: Record "SI Prok Production Fact"; IsOutput: Boolean)
    begin
        if GroupStatus(Fact, IsOutput) <> 1 then
            Error('PF-02.4: %1 проведено не повністю; подальші операції заблоковано.', GroupName(IsOutput));
    end;

    procedure AssertGroupNotPosted(Fact: Record "SI Prok Production Fact"; IsOutput: Boolean)
    begin
        if GroupStatus(Fact, IsOutput) <> 0 then
            Error('PF-02.4: %1 уже частково або повністю проведено; повтор заборонено.', GroupName(IsOutput));
    end;

    // Read-only PF-02 diagnosis. This does NOT change journals, attempts,
    // source MES facts, production orders, or posted entries.
    // Reconciliation snapshots deliberately do not include posting groups,
    // so verify the live journal's accounting classification separately.
    procedure DiagnosePostingGroups(Fact: Record "SI Prok Production Fact")
    var
        Link: Record "SI Prok Journal Link";
        JournalLine: Record "Item Journal Line";
        Item: Record Item;
        PostingSetup: Record "Inventory Posting Setup";
        Result: TextBuilder;
        MasterGroup: Code[20];
        StatusText: Text;
        LineCount: Integer;
        ProblemCount: Integer;
    begin
        Result.AppendLine(StrSubstNo('PF-02 Posting Group DIAG. Fact %1. READ ONLY.', Fact."Entry No."));
        Result.AppendLine('Entry | Item | Location | Journal group | Item group | Status');
        Link.SetRange("Fact Entry No.", Fact."Entry No.");
        if not Link.FindSet() then
            Error('PF-02 DIAG: для факту %1 немає підготовлених Journal Links.', Fact."Entry No.");
        repeat
            LineCount += 1;
            if not JournalLine.Get(Link."Journal Template", Link."Journal Batch", Link."Journal Line No.") then begin
                ProblemCount += 1;
                Result.AppendLine(StrSubstNo('Link %1: MISSING JOURNAL LINE', Link."Link Line No."));
            end else begin
                StatusText := 'OK';
                MasterGroup := '';
                if (not IsNullGuid(Link."Journal Line SystemId")) and
                   (JournalLine.SystemId <> Link."Journal Line SystemId") then begin
                    StatusText := 'WRONG JOURNAL SYSTEMID';
                    ProblemCount += 1;
                end;
                if not Item.Get(JournalLine."Item No.") then begin
                    StatusText := StatusText + ' ITEM NOT FOUND';
                    ProblemCount += 1;
                end else begin
                    MasterGroup := Item."Inventory Posting Group";
                    if JournalLine."Inventory Posting Group" <> MasterGroup then begin
                        StatusText := StatusText + ' JOURNAL <> ITEM';
                        ProblemCount += 1;
                    end;
                end;
                if not PostingSetup.Get(JournalLine."Location Code", JournalLine."Inventory Posting Group") then begin
                    StatusText := StatusText + ' MISSING POSTING SETUP';
                    ProblemCount += 1;
                end;
                Result.AppendLine(StrSubstNo('%1 | %2 | %3 | %4 | %5 | %6',
                    Format(JournalLine."Entry Type"), JournalLine."Item No.", JournalLine."Location Code",
                    JournalLine."Inventory Posting Group", MasterGroup, StatusText));
            end;
        until Link.Next() = 0;
        Result.AppendLine(StrSubstNo('Checked: %1. Flags: %2. No posting or data changes.', LineCount, ProblemCount));
        Message('%1', Result.ToText());
    end;

    procedure Review(Fact: Record "SI Prok Production Fact")
    var
        Attempt: Record "SI Prok Posting Attempt";
        AttemptText: Text;
        Cons: Integer;
        Output: Integer;
    begin
        Cons := GroupStatus(Fact, false);
        Output := GroupStatus(Fact, true);
        AttemptText := 'немає';
        if Attempt.Get(Fact."Production UUID") then
            AttemptText := Format(Attempt.Status);
        Message('PF-02.4, факт %1, UUID %2. Спроба: %3. Consumption: %4. Output: %5. 0 = не проведено; 1 = проведено повністю; 2 = частково. Відновлення не запускається автоматично.',
            Fact."Entry No.", Fact."Production UUID", AttemptText, Cons, Output);
    end;

    local procedure AssertLedgerIdentity(Fact: Record "SI Prok Production Fact")
    var
        Ledger: Record "Item Ledger Entry";
        Link: Record "SI Prok Journal Link";
        Matched: Boolean;
        DocumentNo: Code[20];
    begin
        Fact.TestField("Accounting Document No.");
        DocumentNo := Fact."Accounting Document No.";
        Ledger.SetRange("Document No.", DocumentNo);
        if Ledger.FindSet() then
            repeat
                if (Ledger."Order No." <> Fact."BC Prod. Order No.") or
                   (Ledger."Order Line No." <> Fact."BC Prod. Order Line No.") or
                   (Ledger."Order Type" <> Ledger."Order Type"::Production) then
                    Error('PF-02.4: документ %1 має сторонній проведений запис %2.', DocumentNo, Ledger."Entry No.");
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
                    Error('PF-02.4: запис Item Ledger %1 не відповідає жодному матеріалу/випуску факту %2.', Ledger."Entry No.", Fact."Entry No.");
            until Ledger.Next() = 0;
    end;

    local procedure GroupName(IsOutput: Boolean): Text
    begin
        if IsOutput then
            exit('Output');
        exit('Consumption');
    end;
}
