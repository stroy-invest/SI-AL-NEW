codeunit 57125 "SI Prok Controlled Posting"
{
    // PF-02.3: Sandbox-only, one-shot controlled posting.
    // Each dedicated journal batch must contain ONLY lines of this fact.
    // Any interrupted attempt is terminal until manually investigated.
    procedure PostSandbox(var Fact: Record "SI Prok Production Fact")
    var
        Env: Codeunit "Environment Information";
        Recon: Codeunit "SI Prok Journal Reconciliation";
        Link: Record "SI Prok Journal Link";
        OtherLink: Record "SI Prok Journal Link";
        JournalLine: Record "Item Journal Line";
        Attempt: Record "SI Prok Posting Attempt";
        Prep: Codeunit "SI Prok Accounting Prep Mgt.";
        OutTemplate: Code[10];
        OutBatch: Code[10];
        ConsTemplate: Code[10];
        ConsBatch: Code[10];
        DocumentNo: Code[20];
        TotalLinks: Integer;
    begin
        if not Env.IsSandbox() then
            Error('PF-02.3: ця дія доступна лише в Sandbox.');
        Fact.Get(Fact."Entry No.");
        if Fact."Accounting Prep Mode" <> Fact."Accounting Prep Mode"::Simulation then
            Error('PF-02.3: потрібен режим Simulation.');
        if Attempt.Get(Fact."Production UUID") then
            Error('PF-02.3: для UUID %1 уже була спроба проведення (%2). Автоматичний повтор заборонено.', Fact."Production UUID", Attempt.Status);
        Prep.CheckFact(Fact, Fact."Accounting Prep Mode"::Simulation);
        Fact.Get(Fact."Entry No.");
        if Fact."Accounting Readiness" <> Fact."Accounting Readiness"::Ready then
            Error('PF-02.3: факт не готовий: %1', Fact."Accounting Diagnostics");
        Recon.AssertReady(Fact);
        Link.SetRange("Fact Entry No.", Fact."Entry No.");
        if not Link.FindSet() then
            Error('PF-02.3: немає зв’язків журналів.');
        repeat
            TotalLinks += 1;
            if Link."Material Line No." = 0 then begin
                if OutTemplate <> '' then
                    Error('PF-02.3: знайдено більше одного Output.');
                OutTemplate := Link."Journal Template";
                OutBatch := Link."Journal Batch";
            end else begin
                if ConsTemplate = '' then begin
                    ConsTemplate := Link."Journal Template";
                    ConsBatch := Link."Journal Batch";
                end else
                    if (ConsTemplate <> Link."Journal Template") or (ConsBatch <> Link."Journal Batch") then
                        Error('PF-02.3: Consumption розподілено між кількома пакетами.');
            end;
        until Link.Next() = 0;
        if OutTemplate = '' then
            Error('PF-02.3: Output відсутній.');
        if (OutTemplate = ConsTemplate) and (OutBatch = ConsBatch) then
            Error('PF-02.3: Output і Consumption не можуть бути в одному пакеті.');
        AssertIsolatedBatch(Fact, OutTemplate, OutBatch);
        if ConsTemplate <> '' then
            AssertIsolatedBatch(Fact, ConsTemplate, ConsBatch);
        if not Confirm('PF-02.3: провести %1 рядків для факту %2 у Sandbox? Операція незворотна; повторна спроба автоматично блокується.', false, TotalLinks, Fact."Entry No.") then
            exit;
        // Persist a durable one-shot fence BEFORE calling standard posting.
        // A crash/partial posting must never permit an automatic second run.
        Attempt.Init();
        Attempt."Production UUID" := Fact."Production UUID";
        Attempt."Fact Entry No." := Fact."Entry No.";
        Attempt.Status := Attempt.Status::Started;
        Attempt."Started At" := CurrentDateTime();
        Attempt.Insert(true);
        Commit();
        // Post consumption first; if it succeeds but output fails, a retry remains blocked.
        // Standard BC posting may commit internally; never assume cross-batch atomicity.
        if ConsTemplate <> '' then
            PostBatch(ConsTemplate, ConsBatch);
        PostBatch(OutTemplate, OutBatch);
        Attempt.Get(Fact."Production UUID");
        Attempt.Status := Attempt.Status::Completed;
        Attempt."Finished At" := CurrentDateTime();
        Attempt.Modify(true);
        Message('PF-02.3: стандартні журнали проведено. Перевірте Item Ledger Entries та Production Order.');
    end;

    local procedure AssertIsolatedBatch(Fact: Record "SI Prok Production Fact"; TemplateCode: Code[10]; BatchCode: Code[10])
    var
        JournalLine: Record "Item Journal Line";
        Link: Record "SI Prok Journal Link";
    begin
        JournalLine.SetRange("Journal Template Name", TemplateCode);
        JournalLine.SetRange("Journal Batch Name", BatchCode);
        if not JournalLine.FindSet() then
            Error('PF-02.3: пакет %1/%2 порожній.', TemplateCode, BatchCode);
        repeat
            Link.SetRange("Fact Entry No.", Fact."Entry No.");
            Link.SetRange("Journal Template", TemplateCode);
            Link.SetRange("Journal Batch", BatchCode);
            Link.SetRange("Journal Line No.", JournalLine."Line No.");
            if Link.IsEmpty() then
                Error('PF-02.3: пакет %1/%2 містить сторонній рядок %3. Проведення заблоковано.', TemplateCode, BatchCode, JournalLine."Line No.");
        until JournalLine.Next() = 0;
    end;

    local procedure PostBatch(TemplateCode: Code[10]; BatchCode: Code[10])
    var
        JournalLine: Record "Item Journal Line";
    begin
        JournalLine.SetRange("Journal Template Name", TemplateCode);
        JournalLine.SetRange("Journal Batch Name", BatchCode);
        if not JournalLine.FindFirst() then
            Error('PF-02.3: пакет %1/%2 порожній перед проведенням.', TemplateCode, BatchCode);
        // Standard BC posting, not direct Item Ledger Entry insertion.
        Codeunit.Run(Codeunit::"Item Jnl.-Post Batch", JournalLine);
    end;
}
