codeunit 57146 "SI Prok Process Jnl Cleanup"
{
    // PROC-FIX-001: remove ONLY provably empty technical journal lines
    // left by standard Item Jnl.-Post Batch for a FULLY posted Process fact.
    // Never touch Item Ledger Entries, Journal Links or any unposted business line.
    // No COMMIT; the caller owns the transaction.

    procedure CleanupAfterCompleted(Fact: Record "SI Prok Production Fact"): Integer
    var
        Link: Record "SI Prok Journal Link";
        Safety: Codeunit "SI Prok Prod Safe Guard";
    begin
        Safety.AssertDisabled('Очищення проведеного журналу');
        Link.SetRange("Fact Entry No.", Fact."Entry No.");
        if not Link.FindFirst() then
            exit(-1);
        exit(CleanupCompletedBatch(Fact, Link."Journal Template", Link."Journal Batch"));
    end;

    // Defense in depth: if BC/UI recreates the blank line after posting,
    // the NEXT fact's preparation can clear it, but only with proof that
    // the previous document belongs to a COMPLETED Process fact.
    procedure CleanupPriorCompletedRemainder(TemplateName: Code[10]; BatchName: Code[10]): Integer
    var
        JournalLine: Record "Item Journal Line";
        Link: Record "SI Prok Journal Link";
        Fact: Record "SI Prok Production Fact";
        Safety: Codeunit "SI Prok Prod Safe Guard";
    begin
        Safety.AssertDisabled('Очищення залишків журналу');
        JournalLine.SetRange("Journal Template Name", TemplateName);
        JournalLine.SetRange("Journal Batch Name", BatchName);
        if not JournalLine.FindFirst() then
            exit(0);
        if JournalLine."Document No." = '' then
            exit(0);

        Link.SetRange("Journal Template", TemplateName);
        Link.SetRange("Journal Batch", BatchName);
        Link.SetRange("Document No.", JournalLine."Document No.");
        if not Link.FindFirst() then
            exit(0);
        if not Fact.Get(Link."Fact Entry No.") then
            exit(0);

        exit(CleanupCompletedBatch(Fact, TemplateName, BatchName));
    end;

    local procedure CleanupCompletedBatch(Fact: Record "SI Prok Production Fact"; TemplateName: Code[10]; BatchName: Code[10]): Integer
    var
        Attempt: Record "SI Prok Posting Attempt";
        Link: Record "SI Prok Journal Link";
        JournalLine: Record "Item Journal Line";
        Control: Codeunit "SI Prok Process Control";
        PostedGroups: Integer;
        MissingGroups: Integer;
        DeletedLines: Integer;
        ExpectedDate: Date;
    begin
        // A Started / partial / unknown attempt must NEVER be cleaned.
        if not Attempt.Get(Fact."Production UUID") then
            exit(-1);
        if (Attempt."Fact Entry No." <> Fact."Entry No.") or
           (Attempt.Status <> Attempt.Status::Completed) then
            exit(-1);
        if Fact."Accounting Document No." = '' then
            exit(-1);

        Link.SetRange("Fact Entry No.", Fact."Entry No.");
        Link.SetRange("Journal Template", TemplateName);
        Link.SetRange("Journal Batch", BatchName);
        Link.SetRange("Document No.", Fact."Accounting Document No.");
        if not Link.FindFirst() then
            exit(-1);
        if (Link."Production UUID" <> Fact."Production UUID") or (not Link."Snapshot Available") then
            exit(-1);
        ExpectedDate := Link."Expected Posting Date";

        // Independent read-only proof that ALL expected ILE groups are posted.
        if Control.LedgerStatus(Fact, PostedGroups, MissingGroups) <> 1 then
            exit(-1);
        if (PostedGroups = 0) or (MissingGroups <> 0) then
            exit(-1);

        JournalLine.LockTable();
        JournalLine.SetRange("Journal Template Name", TemplateName);
        JournalLine.SetRange("Journal Batch Name", BatchName);
        if not JournalLine.FindSet() then
            exit(0); // Standard BC removed every row already.

        // Two passes: if even ONE line is meaningful or foreign, delete NONE.
        repeat
            if not IsSafeTechnicalRemainder(JournalLine, Fact."Accounting Document No.", ExpectedDate) then
                exit(-1);
        until JournalLine.Next() = 0;

        if JournalLine.FindSet(true) then
            repeat
                // Fail closed if a record changed between validation and delete.
                if not IsSafeTechnicalRemainder(JournalLine, Fact."Accounting Document No.", ExpectedDate) then
                    Error('SI Process: рядок журналу змінився під час очищення; операцію скасовано.');
                JournalLine.Delete(true);
                DeletedLines += 1;
            until JournalLine.Next() = 0;
        exit(DeletedLines);
    end;

    local procedure IsSafeTechnicalRemainder(Line: Record "Item Journal Line"; DocumentNo: Code[20]; ExpectedDate: Date): Boolean
    begin
        // Document identity is mandatory. Do NOT classify by Quantity=0 alone.
        exit((Line."Document No." = DocumentNo) and
             (Line."Posting Date" = ExpectedDate) and
             (Line."Item No." = '') and
             (Line.Quantity = 0) and
             (Line."Quantity (Base)" = 0) and
             (Line.Description = '') and
             (Line."Variant Code" = '') and
             (Line."Location Code" = '') and
             (Line."Bin Code" = '') and
             (Line."Unit of Measure Code" = '') and
             (Line."External Document No." = '') and
             (Line."Gen. Bus. Posting Group" = '') and
             (Line."Gen. Prod. Posting Group" = '') and
             (Line."Inventory Posting Group" = '') and
             (Line."Posting No. Series" = '') and
             (Line."Order No." = '') and
             (Line."Order Line No." = 0) and
             (Line."Prod. Order Comp. Line No." = 0) and
             (Line."Dimension Set ID" = 0));
    end;
}
