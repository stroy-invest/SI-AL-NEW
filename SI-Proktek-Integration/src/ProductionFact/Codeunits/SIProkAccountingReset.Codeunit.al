codeunit 57138 "SI Prok Accounting Reset"
{
    // PF-02 Sandbox reset: ONLY accounting artifacts for all facts bound to
    // one BC Production Order. MES facts/materials/JSON, order and components
    // are never deleted or changed. No COMMIT; transactional rollback on error.
    procedure ResetOrderSandbox(SelectedFact: Record "SI Prok Production Fact")
    var
        Env: Codeunit "Environment Information";
        Fact: Record "SI Prok Production Fact";
        JournalLine: Record "Item Journal Line";
        Link: Record "SI Prok Journal Link";
        Attempt: Record "SI Prok Posting Attempt";
        AffectedFacts: Integer;
        TotalFacts: Integer;
        LinksToRemove: Integer;
        JournalLinesToRemove: Integer;
        AttemptsToRemove: Integer;
        DeletedLinks: Integer;
        DeletedJournalLines: Integer;
        DeletedAttempts: Integer;
        ResetFacts: Integer;
    begin
        if not Env.IsSandbox() then
            Error('PF-02 RESET: очищення облікової підготовки дозволене лише в Sandbox.');
        SelectedFact.Get(SelectedFact."Entry No.");
        if SelectedFact."Accounting Posting Model" = SelectedFact."Accounting Posting Model"::"Process Adjustment" then
            Error('PF-02 RESET: SI Process Production має окремий обліковий контракт. Старе очищення Production Order заборонено.');
        SelectedFact.TestField("BC Prod. Order No.");
        SelectedFact.TestField("BC Prod. Order Line No.");

        // Phase 1: read-only preflight. Abort if ANY posted ILE exists for a
        // prepared document, or if an attempt is completed/in flight.
        ApplyFactFilter(Fact, SelectedFact);
        if not Fact.FindSet() then
            Error('PF-02 RESET: факти виробничого замовлення %1 не знайдено.', SelectedFact."BC Prod. Order No.");
        repeat
            TotalFacts += 1;
            CheckFactSafe(Fact, LinksToRemove, JournalLinesToRemove, AttemptsToRemove);
            if HasAccountingArtifacts(Fact) then
                AffectedFacts += 1;
        until Fact.Next() = 0;
        if AffectedFacts = 0 then begin
            Message('PF-02 RESET: облікових артефактів для %1 немає.', SelectedFact."BC Prod. Order No.");
            exit;
        end;

        if not Confirm(
            'PF-02 RESET (Sandbox): для виробничого замовлення %1 очистити облікову підготовку %2 фактів? Рядків журналів: %3, зв’язків: %4, спроб: %5. MES-факти, матеріали, JSON, Production Order та його компоненти НЕ зміняться. Проведення НЕ виконується.',
            false, SelectedFact."BC Prod. Order No.", AffectedFacts,
            JournalLinesToRemove, LinksToRemove, AttemptsToRemove) then
            exit;

        // Phase 2: lock, re-check, then delete ONLY provably owned journal rows.
        Fact.LockTable();
        Link.LockTable();
        JournalLine.LockTable();
        Attempt.LockTable();
        ApplyFactFilter(Fact, SelectedFact);
        if Fact.Count() <> TotalFacts then
            Error('PF-02 RESET: кількість фактів замовлення змінилася; повторіть перевірку.');
        if Fact.FindSet(true) then
            repeat
                // Re-check after locks. A later error rolls back earlier deletes.
                CheckFactSafe(Fact, LinksToRemove, JournalLinesToRemove, AttemptsToRemove);
                if HasAccountingArtifacts(Fact) then begin
                    Link.Reset();
                    Link.SetRange("Fact Entry No.", Fact."Entry No.");
                    if Link.FindSet(true) then
                        repeat
                            if JournalLine.Get(Link."Journal Template", Link."Journal Batch", Link."Journal Line No.") then
                                if IsOwnedJournalLine(Link, JournalLine) then begin
                                    // Other facts may share a batch, never a physical line.
                                    AssertNoOtherOwner(Fact, Link, JournalLine);
                                    JournalLine.Delete(true);
                                    DeletedJournalLines += 1;
                                end;
                            // If the slot was reused by another row, leave that row alone.
                            Link.Delete(true);
                            DeletedLinks += 1;
                        until Link.Next() = 0;
                    if Attempt.Get(Fact."Production UUID") then begin
                        Attempt.Delete(true);
                        DeletedAttempts += 1;
                    end;
                    // The ONLY modified fact field is accounting metadata needed
                    // for a new No. Series allocation. Source evidence is immutable.
                    if Fact."Accounting Document No." <> '' then begin
                        Fact."Accounting Document No." := '';
                        Fact.Modify(true);
                    end;
                    ResetFacts += 1;
                end;
            until Fact.Next() = 0;
        Message('PF-02 RESET: облік очищено для %1 фактів замовлення %2. Видалено журналів %3, зв’язків %4, спроб %5. MES-факти та виробниче замовлення збережено. Нові журнали НЕ створювалися.',
            ResetFacts, SelectedFact."BC Prod. Order No.", DeletedJournalLines, DeletedLinks, DeletedAttempts);
    end;

    local procedure ApplyFactFilter(var Fact: Record "SI Prok Production Fact"; Selected: Record "SI Prok Production Fact")
    begin
        Fact.Reset();
        Fact.SetRange("BC Prod. Order No.", Selected."BC Prod. Order No.");
    end;

    local procedure HasAccountingArtifacts(Fact: Record "SI Prok Production Fact"): Boolean
    var
        Link: Record "SI Prok Journal Link";
        Attempt: Record "SI Prok Posting Attempt";
    begin
        if Fact."Accounting Document No." <> '' then
            exit(true);
        if Attempt.Get(Fact."Production UUID") then
            exit(true);
        Link.SetRange("Fact Entry No.", Fact."Entry No.");
        exit(not Link.IsEmpty());
    end;

    local procedure CheckFactSafe(Fact: Record "SI Prok Production Fact"; var LinksCount: Integer; var JournalCount: Integer; var AttemptsCount: Integer)
    var
        Link: Record "SI Prok Journal Link";
        JournalLine: Record "Item Journal Line";
        Attempt: Record "SI Prok Posting Attempt";
    begin
        // Reset by Production Order can span multiple facts. Never delete a
        // Process fact's links/journal even if the selected fact is legacy.
        if Fact."Accounting Posting Model" = Fact."Accounting Posting Model"::"Process Adjustment" then
            Error('PF-02 RESET: замовлення містить SI Process факт %1. Старе очищення всього замовлення заблоковано.', Fact."Entry No.");
        if not HasAccountingArtifacts(Fact) then
            exit;
        if IsNullGuid(Fact."Production UUID") then
            Error('PF-02 RESET: факт %1 без UUID; автоматичне очищення заборонено.', Fact."Entry No.");
        AssertNoPostedEntries(Fact."Accounting Document No.", Fact."Entry No.");
        if Attempt.Get(Fact."Production UUID") then begin
            if Attempt."Fact Entry No." <> Fact."Entry No." then
                Error('PF-02 RESET: спроба UUID %1 належить іншому факту.', Fact."Production UUID");
            if Attempt.Status <> Attempt.Status::Started then
                Error('PF-02 RESET: факт %1 має завершену спробу проведення; очищення заборонено.', Fact."Entry No.");
            if (Attempt."Started At" = 0DT) or (CurrentDateTime() - Attempt."Started At" < 600000) then
                Error('PF-02 RESET: факт %1 — після спроби має пройти 10 хвилин; переконайтеся, що проведення вже завершилося.', Fact."Entry No.");
            AttemptsCount += 1;
        end;
        Link.SetRange("Fact Entry No.", Fact."Entry No.");
        if Link.FindSet() then
            repeat
                if Link."Production UUID" <> Fact."Production UUID" then
                    Error('PF-02 RESET: зв’язок %1 має інший Production UUID.', Link."Link Line No.");
                AssertNoPostedEntries(Link."Document No.", Fact."Entry No.");
                LinksCount += 1;
                if JournalLine.Get(Link."Journal Template", Link."Journal Batch", Link."Journal Line No.") then
                    if IsOwnedJournalLine(Link, JournalLine) then begin
                        AssertNoOtherOwner(Fact, Link, JournalLine);
                        JournalCount += 1;
                    end;
            until Link.Next() = 0;
    end;

    local procedure AssertNoPostedEntries(DocumentNo: Code[20]; FactEntryNo: Integer)
    var
        Ledger: Record "Item Ledger Entry";
    begin
        if DocumentNo = '' then
            exit;
        Ledger.SetRange("Document No.", DocumentNo);
        if not Ledger.IsEmpty() then
            Error('PF-02 RESET: для факту %1 документа %2 вже є Item Ledger Entries. Очищення заблоковано.', FactEntryNo, DocumentNo);
    end;

    local procedure IsOwnedJournalLine(Link: Record "SI Prok Journal Link"; JournalLine: Record "Item Journal Line"): Boolean
    begin
        if not IsNullGuid(Link."Journal Line SystemId") then
            exit(Link."Journal Line SystemId" = JournalLine.SystemId);
        // Legacy links (pre-1.0.0.81): never delete a newer reused line slot.
        if (Link."Prepared At" = 0DT) or (JournalLine.SystemCreatedAt = 0DT) then
            exit(false);
        exit((JournalLine.SystemCreatedAt <= Link."Prepared At") and
             (JournalLine."Document No." = Link."Document No."));
    end;

    local procedure AssertNoOtherOwner(Fact: Record "SI Prok Production Fact"; Link: Record "SI Prok Journal Link"; JournalLine: Record "Item Journal Line")
    var
        OtherLink: Record "SI Prok Journal Link";
    begin
        OtherLink.SetRange("Journal Template", Link."Journal Template");
        OtherLink.SetRange("Journal Batch", Link."Journal Batch");
        OtherLink.SetRange("Journal Line No.", Link."Journal Line No.");
        OtherLink.SetFilter("Fact Entry No.", '<>%1', Fact."Entry No.");
        if OtherLink.FindSet() then
            repeat
                if IsOwnedJournalLine(OtherLink, JournalLine) then
                    Error('PF-02 RESET: рядок журналу %1/%2/%3 також належить факту %4; очищення заблоковано.',
                        Link."Journal Template", Link."Journal Batch", Link."Journal Line No.", OtherLink."Fact Entry No.");
            until OtherLink.Next() = 0;
    end;
}
