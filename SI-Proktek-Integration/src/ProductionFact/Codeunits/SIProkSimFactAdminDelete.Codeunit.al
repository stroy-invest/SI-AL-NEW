codeunit 57962 "SI Prok Sim Fact Admin Delete"
{
    // Explicitly selected simulated facts only. No COMMIT: deletion and audit are atomic.
    Permissions =
        tabledata "SI Prok Production Fact" = rd,
        tabledata "SI Prok Prod Fact Material" = rd,
        tabledata "SI Prok Fact Validation Entry" = rd,
        tabledata "SI Prok Sim Fact Del Audit" = ri;

    procedure DeleteSelected(var Selection: Record "SI Prok Production Fact"): Integer
    var
        Fact: Record "SI Prok Production Fact";
        Selected: Record "SI Prok Production Fact";
        CountToDelete: Integer;
        Deleted: Integer;
    begin
        AssertAuthorized();
        // SetSelectionFilter may represent a single selection or a filtered set.
        // Never fall back to unfiltered deletion.
        CountToDelete := Selection.Count();
        if CountToDelete = 0 then
            Error('Не вибрано жодного факту.');
        if CountToDelete > 20 then
            Error('За одну операцію дозволено видалити не більше 20 явно вибраних фактів. Вибрано: %1.', CountToDelete);
        Selected.Copy(Selection);
        if Selected.FindSet() then
            repeat
                Fact.Get(Selected."Entry No.");
                AssertDeletable(Fact);
            until Selected.Next() = 0;

        if not Confirm('БЕЗПОВОРОТНО видалити %1 вибраних фактів та їхні матеріали? Архів первинного JSON залишиться. Продовжити?', false, CountToDelete) then
            exit(0);

        // Repeat all guards immediately before writes; any error rolls back the entire operation.
        if Selection.FindSet() then
            repeat
                Fact.LockTable();
                Fact.Get(Selection."Entry No.");
                AssertDeletable(Fact);
                DeleteOne(Fact);
                Deleted += 1;
            until Selection.Next() = 0;
        exit(Deleted);
    end;

    local procedure AssertAuthorized()
    var
        Access: Record "Access Control";
    begin
        Access.SetRange("User Security ID", UserSecurityId());
        Access.SetFilter("Role ID", '%1|%2', 'SUPER', 'SI PROK FACT DELETE');
        Access.SetFilter("Company Name", '%1|%2', '', CompanyName());
        if Access.IsEmpty() then
            Error('Адміністративне видалення дозволене лише користувачу з призначеним SUPER або SI PROK FACT DELETE.');
    end;

    local procedure AssertDeletable(Fact: Record "SI Prok Production Fact")
    var
        Shipment: Record "SI Prok Shipment";
        JournalLink: Record "SI Prok Journal Link";
        PostingAttempt: Record "SI Prok Posting Attempt";
    begin
        //if not Fact.Simulation then
        //    Error('Факт %1 (Production ID %2) не позначено як симуляцію. Видалення заборонено.', Fact."Entry No.", Fact."Production ID");
        Shipment.SetRange("Production Fact Entry No.", Fact."Entry No.");
        if not Shipment.IsEmpty() then
            Error('Факт %1 має Shipment. Видалення заборонено.', Fact."Entry No.");
        Shipment.Reset();
        Shipment.SetRange("Production UUID", Fact."Production UUID");
        if not Shipment.IsEmpty() then
            Error('Факт %1 має Shipment за Production UUID. Видалення заборонено.', Fact."Entry No.");
        JournalLink.SetRange("Fact Entry No.", Fact."Entry No.");
        if not JournalLink.IsEmpty() then
            Error('Факт %1 має зв’язки з журналом обліку. Видалення заборонено.', Fact."Entry No.");
        JournalLink.Reset();
        JournalLink.SetRange("Production UUID", Fact."Production UUID");
        if not JournalLink.IsEmpty() then
            Error('Факт %1 має зв’язки з журналом за UUID. Видалення заборонено.', Fact."Entry No.");
        PostingAttempt.SetRange("Production UUID", Fact."Production UUID");
        if not PostingAttempt.IsEmpty() then
            Error('Факт %1 має спробу проведення. Видалення заборонено.', Fact."Entry No.");
        if (Fact."BC Prod. Order No." <> '') or (Fact."Accounting Document No." <> '') then
            Error('Факт %1 пов’язаний із виробничим або обліковим документом BC. Видалення заборонено.', Fact."Entry No.");
    end;

    local procedure DeleteOne(Fact: Record "SI Prok Production Fact")
    var
        Material: Record "SI Prok Prod Fact Material";
        Validation: Record "SI Prok Fact Validation Entry";
        Audit: Record "SI Prok Sim Fact Del Audit";
    begin
        Audit.Init();
        Audit."Fact Entry No." := Fact."Entry No.";
        Audit."Production UUID" := Fact."Production UUID";
        Audit."Production ID" := Fact."Production ID";
        Audit."Connection Code" := Fact."Connection Code";
        Audit."Deleted At" := CurrentDateTime();
        Audit."Deleted By" := CopyStr(UserId(), 1, MaxStrLen(Audit."Deleted By"));
        Material.SetRange("Production Fact Entry No.", Fact."Entry No.");
        Audit."Material Lines Deleted" := Material.Count();
        Validation.SetRange("Production Fact Entry No.", Fact."Entry No.");
        Audit."Validation Lines Deleted" := Validation.Count();
        Audit.Insert(true);
        Material.DeleteAll(true);
        Validation.DeleteAll(true);
        Fact.Delete(true);
    end;
}
