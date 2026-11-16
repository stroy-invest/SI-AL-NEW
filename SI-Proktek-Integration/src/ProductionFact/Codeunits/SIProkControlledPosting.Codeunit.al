codeunit 57125 "SI Prok Controlled Posting"
{
    // PF-02.3: Sandbox-only, one-shot controlled posting.
    // Each dedicated journal batch must contain ONLY lines of this fact.
    // Any interrupted attempt is terminal until manually investigated.
    procedure PostSandbox(var Fact: Record "SI Prok Production Fact")
    var
        Env: Codeunit "Environment Information";
        Recon: Codeunit "SI Prok Journal Reconciliation";
        Audit: Codeunit "SI Prok Posting Audit";
        Link: Record "SI Prok Journal Link";
        JournalLine: Record "Item Journal Line";
        Attempt: Record "SI Prok Posting Attempt";
        Prep: Codeunit "SI Prok Accounting Prep Mgt.";
        OutTemplate: Code[10];
        OutBatch: Code[10];
        ConsTemplate: Code[10];
        ConsBatch: Code[10];
        TotalLinks: Integer;
    begin
        if not Env.IsSandbox() then
            Error('PF-02.3: ця дія доступна лише в Sandbox.');
        Fact.Get(Fact."Entry No.");
        if Fact."Accounting Posting Model" = Fact."Accounting Posting Model"::"Process Adjustment" then
            Error('PF-02: цей факт використовує SI Process Production. Старе Production Order проведення заборонено.');
        if Attempt.Get(Fact."Production UUID") then
            Error('PF-02.3: для UUID %1 уже була спроба проведення (%2). Автоматичний повтор заборонено.', Fact."Production UUID", Attempt.Status);
        Prep.CheckFact(Fact);
        Fact.Get(Fact."Entry No.");
        if Fact."Accounting Readiness" <> Fact."Accounting Readiness"::Ready then
            Error('PF-02.3: факт не готовий: %1', Fact."Accounting Diagnostics");
        Recon.AssertReady(Fact);
        Audit.AssertGroupNotPosted(Fact, false);
        Audit.AssertGroupNotPosted(Fact, true);
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
        if ConsTemplate = '' then
            Error('PF-02.3: Consumption відсутній; перевірте фактичні матеріали.');
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
        PostBatch(ConsTemplate, ConsBatch);
        Audit.AssertGroupPosted(Fact, false);
        Audit.AssertGroupNotPosted(Fact, true);
        PostBatch(OutTemplate, OutBatch);
        Audit.AssertGroupPosted(Fact, true);
        Attempt.Get(Fact."Production UUID");
        Attempt.Status := Attempt.Status::Completed;
        Attempt."Finished At" := CurrentDateTime();
        Attempt.Modify(true);
        Message('PF-02.3: стандартні журнали проведено. Перевірте Item Ledger Entries та Production Order.');
    end;

    // Explicit recovery for the only automatically recognizable partial state:
    // all consumption entries are posted, no output is posted, and the original
    // output journal line remains intact. Never repeat consumption here.
    procedure RecoverOutputSandbox(var Fact: Record "SI Prok Production Fact")
    var
        Env: Codeunit "Environment Information";
        Attempt: Record "SI Prok Posting Attempt";
        Prep: Codeunit "SI Prok Accounting Prep Mgt.";
        Recon: Codeunit "SI Prok Journal Reconciliation";
        Audit: Codeunit "SI Prok Posting Audit";
        Link: Record "SI Prok Journal Link";
        OutputTemplate: Code[10];
        OutputBatch: Code[10];
    begin
        if not Env.IsSandbox() then
            Error('PF-02.4: відновлення наразі дозволено лише в Sandbox.');
        Fact.Get(Fact."Entry No.");
        if Fact."Accounting Posting Model" = Fact."Accounting Posting Model"::"Process Adjustment" then
            Error('PF-02: відновлення Production Order не застосовується до SI Process Production.');
        if not Attempt.Get(Fact."Production UUID") then
            Error('PF-02.4: немає попередньої спроби проведення.');
        if Attempt.Status <> Attempt.Status::Started then
            Error('PF-02.4: відновлення дозволене лише для незавершеної спроби.');
        Prep.CheckFact(Fact);
        Fact.Get(Fact."Entry No.");
        if Fact."Accounting Readiness" <> Fact."Accounting Readiness"::Ready then
            Error('PF-02.4: факт не готовий: %1', Fact."Accounting Diagnostics");
        Audit.AssertGroupPosted(Fact, false);
        Audit.AssertGroupNotPosted(Fact, true);
        Recon.AssertOutputReady(Fact);
        Link.SetRange("Fact Entry No.", Fact."Entry No.");
        Link.SetRange("Material Line No.", 0);
        if Link.Count() <> 1 then
            Error('PF-02.4: очікується рівно один Output link.');
        Link.FindFirst();
        OutputTemplate := Link."Journal Template";
        OutputBatch := Link."Journal Batch";
        AssertIsolatedBatch(Fact, OutputTemplate, OutputBatch);
        if not Confirm('PF-02.4: Consumption вже проведено, Output відсутній. Провести ТІЛЬКИ Output для факту %1? Повторного списання матеріалів не буде.', false, Fact."Entry No.") then
            exit;
        PostBatch(OutputTemplate, OutputBatch);
        Audit.AssertGroupPosted(Fact, true);
        Attempt.Get(Fact."Production UUID");
        Attempt.Status := Attempt.Status::Completed;
        Attempt."Finished At" := CurrentDateTime();
        Attempt.Modify(true);
        Message('PF-02.4: Output проведено після контрольованого відновлення. Перевірте Item Ledger Entries.');
    end;

    // A failed posting can leave the durable Attempt in Started while neither
    // group was posted (for example insufficient material stock). Only a human
    // can authorize this retry after checking the journal and inventory.
    procedure RecoverUnpostedSandbox(var Fact: Record "SI Prok Production Fact")
    var
        Env: Codeunit "Environment Information";
        Attempt: Record "SI Prok Posting Attempt";
        Prep: Codeunit "SI Prok Accounting Prep Mgt.";
        Recon: Codeunit "SI Prok Journal Reconciliation";
        Audit: Codeunit "SI Prok Posting Audit";
        Link: Record "SI Prok Journal Link";
        OutputTemplate: Code[10];
        OutputBatch: Code[10];
        ConsumptionTemplate: Code[10];
        ConsumptionBatch: Code[10];
    begin
        if not Env.IsSandbox() then
            Error('PF-02.4: відновлення наразі дозволено лише в Sandbox.');
        Fact.Get(Fact."Entry No.");
        if Fact."Accounting Posting Model" = Fact."Accounting Posting Model"::"Process Adjustment" then
            Error('PF-02: відновлення Production Order не застосовується до SI Process Production.');
        Attempt.LockTable();
        if not Attempt.Get(Fact."Production UUID") then
            Error('PF-02.4: немає незавершеної спроби.');
        if Attempt.Status <> Attempt.Status::Started then
            Error('PF-02.4: дозволено лише ручне відновлення Started.');
        if CurrentDateTime() - Attempt."Started At" < 600000 then
            Error('PF-02.4: після початку спроби має пройти щонайменше 10 хвилин; перевірте, що попереднє проведення завершилося.');
        Prep.CheckFact(Fact);
        Fact.Get(Fact."Entry No.");
        if Fact."Accounting Readiness" <> Fact."Accounting Readiness"::Ready then
            Error('PF-02.4: факт не готовий: %1', Fact."Accounting Diagnostics");
        Recon.AssertReady(Fact);
        Audit.AssertGroupNotPosted(Fact, false);
        Audit.AssertGroupNotPosted(Fact, true);
        Link.SetRange("Fact Entry No.", Fact."Entry No.");
        if Link.FindSet() then
            repeat
                if Link."Material Line No." = 0 then begin
                    OutputTemplate := Link."Journal Template";
                    OutputBatch := Link."Journal Batch";
                end else begin
                    ConsumptionTemplate := Link."Journal Template";
                    ConsumptionBatch := Link."Journal Batch";
                end;
            until Link.Next() = 0;
        if (OutputTemplate = '') or (ConsumptionTemplate = '') then
            Error('PF-02.4: не визначено обидва пакети журналів.');
        if (OutputTemplate = ConsumptionTemplate) and (OutputBatch = ConsumptionBatch) then
            Error('PF-02.4: Output і Consumption повинні бути в різних пакетах.');
        AssertIsolatedBatch(Fact, ConsumptionTemplate, ConsumptionBatch);
        AssertIsolatedBatch(Fact, OutputTemplate, OutputBatch);
        if not Confirm('PF-02.4: після звірки складських залишків і відсутності проведених записів повторити Consumption + Output для факту %1? Дія незворотна.', false, Fact."Entry No.") then
            exit;
        PostBatch(ConsumptionTemplate, ConsumptionBatch);
        Audit.AssertGroupPosted(Fact, false);
        Audit.AssertGroupNotPosted(Fact, true);
        PostBatch(OutputTemplate, OutputBatch);
        Audit.AssertGroupPosted(Fact, true);
        Attempt.Get(Fact."Production UUID");
        Attempt.Status := Attempt.Status::Completed;
        Attempt."Finished At" := CurrentDateTime();
        Attempt.Modify(true);
        Message('PF-02.4: відновлене проведення завершено. Перевірте Item Ledger Entries.');
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
