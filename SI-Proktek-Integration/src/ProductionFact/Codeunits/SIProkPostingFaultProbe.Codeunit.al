codeunit 57151 "SI Prok Posting Fault Probe"
{
    // TEMPORARY Sandbox/SUPER UAT tool. Remove from the clean baseline after
    // the 4/7 and Started/7/7 recovery scenarios are verified.
    // Always uses standard BC item journal posting; never writes ILE directly.

    procedure PostFourOfSeven(FactEntryNo: Integer)
    var
        Fact: Record "SI Prok Production Fact";
        Link: Record "SI Prok Journal Link";
        JournalLine: Record "Item Journal Line";
        StandardPostLine: Codeunit "Item Jnl.-Post Line";
        Control: Codeunit "SI Prok Process Control";
        Posted: Integer;
        Missing: Integer;
        CountPosted: Integer;
    begin
        AssertTestReady(FactEntryNo, Fact, Link);
        if not Confirm(
            'УВАГА — SANDBOX. Реально провести стандартним BC рівно 4 із 7 рядків документа %1?\Створимо Posting Attempt = Started; решта 3 залишаться непроведеними. Recovery ОБОВ''ЯЗКОВО має відмовити. Продовжити?',
            false, Fact."Accounting Document No.") then
            exit;
        BeginStartedAttempt(Fact, 'UAT-PARTIAL-4OF7');

        // Four separate BC posting operations with a durable Commit per line:
        // this is a REAL partial ledger state, not a fake counter or ILE insert.
        Link.Reset();
        Link.SetRange("Fact Entry No.", Fact."Entry No.");
        if Link.FindSet() then
            repeat
                if CountPosted < 4 then begin
                    if Link."Material Line No." = 0 then
                        Error('UAT: перші 4 рядки мають бути списаннями матеріалів. Спроба залишиться Started.');
                    if not JournalLine.Get(Link."Journal Template", Link."Journal Batch", Link."Journal Line No.") then
                        Error('UAT: рядок %1 зник. Спроба залишиться Started.', Link."Link Line No.");
                    if not StandardPostLine.RunWithCheck(JournalLine) then
                        Error('UAT: BC не провів рядок %1. Перевірте Started/ILE.', Link."Link Line No.");
                    // Codeunit 22 posts one line but does not run Batch cleanup.
                    // Remove precisely the posted source line so nobody can
                    // accidentally post it again from the item journal UI.
                    if JournalLine.Get(Link."Journal Template", Link."Journal Batch", Link."Journal Line No.") then begin
                        if JournalLine.SystemId <> Link."Journal Line SystemId" then
                            Error('UAT: після проведення змінено SystemId рядка %1. Потрібен аудит.', Link."Link Line No.");
                        JournalLine.Delete(true);
                    end;
                    Commit();
                    CountPosted += 1;
                end;
            until Link.Next() = 0;
        if (Control.LedgerStatus(Fact, Posted, Missing) <> 2) or
           (Posted <> 4) or (Missing <> 3) then
            Error('UAT: очікували 4/7, фактично %1/%2. Дані вже можуть бути проведені; не повторювати!', Posted, Missing);
        Message('UAT 4/7 створено: факт %1, документ %2, Posting Attempt = Started, ILE-груп 4 проведено / 3 відсутні.\Наступне: аудит; після 10 хв Recovery має бути заблоковано. Потім очистіть 3 залишкові рядки тесту окремою дією.',
            Fact."Entry No.", Fact."Accounting Document No.");
    end;

    procedure PostAllLeaveStarted(FactEntryNo: Integer)
    var
        Fact: Record "SI Prok Production Fact";
        Link: Record "SI Prok Journal Link";
        JournalLine: Record "Item Journal Line";
        Control: Codeunit "SI Prok Process Control";
        Posted: Integer;
        Missing: Integer;
    begin
        AssertTestReady(FactEntryNo, Fact, Link);
        if not Confirm(
            'УВАГА — SANDBOX. Провести ВСІ 7 рядків стандартним BC, але навмисно залишити Posting Attempt = Started для документа %1?\Після 10 хв Recovery має лише завершити спробу без повторного проведення. Продовжити?',
            false, Fact."Accounting Document No.") then
            exit;
        BeginStartedAttempt(Fact, 'UAT-ALL-7OF7');
        if not JournalLine.Get(Link."Journal Template", Link."Journal Batch", Link."Journal Line No.") then
            Error('UAT: перший рядок журналу зник після створення Started.');
        Codeunit.Run(Codeunit::"Item Jnl.-Post Batch", JournalLine);
        if (Control.LedgerStatus(Fact, Posted, Missing) <> 1) or (Posted <> 7) or (Missing <> 0) then
            Error('UAT: очікували Started/7/7; фактичні ILE %1 проведено / %2 відсутні.', Posted, Missing);
        // Deliberately DO NOT call MarkCompleted. This recreates the crashed
        // session after all standard BC ledger operations have committed.
        Commit();
        Message('UAT Started/7/7 створено: факт %1, документ %2. Облік фізично проведено; Attempt залишено Started.\Після 10 хв Recovery повинно лише позначити Completed.',
            Fact."Entry No.", Fact."Accounting Document No.");
    end;

    procedure ClearPartialProbeRemainder(FactEntryNo: Integer)
    var
        Fact: Record "SI Prok Production Fact";
        Attempt: Record "SI Prok Posting Attempt";
        Link: Record "SI Prok Journal Link";
        JournalLine: Record "Item Journal Line";
        EnvironmentInfo: Codeunit "Environment Information";
        UserPermissions: Codeunit "User Permissions";
        Control: Codeunit "SI Prok Process Control";
        Posted: Integer;
        Missing: Integer;
        Removed: Integer;
        LineIndex: Integer;
    begin
        if not EnvironmentInfo.IsSandbox() or not UserPermissions.IsSuper(UserSecurityId()) then
            Error('UAT: очистити залишок може тільки SUPER у Sandbox.');
        Fact.Get(FactEntryNo);
        if CopyStr(Fact."Accounting Diagnostics", 1, 16) <> 'UAT-PARTIAL-4OF7' then
            Error('UAT: факт не позначений як тестовий 4/7. Чужі журнали не чіпаємо.');
        if not Attempt.Get(Fact."Production UUID") then
            Error('UAT: Posting Attempt відсутній.');
        if (Attempt."Fact Entry No." <> Fact."Entry No.") or (Attempt.Status <> Attempt.Status::Started) then
            Error('UAT: очікується Started для поточного факту.');
        if (Control.LedgerStatus(Fact, Posted, Missing) <> 2) or (Posted <> 4) or (Missing <> 3) then
            Error('UAT: ILE більше не мають стану 4/7. Ніяких видалень.');
        Link.SetRange("Fact Entry No.", Fact."Entry No.");
        if Link.Count() <> 7 then
            Error('UAT: Journal Links було змінено. Ніяких видалень.');
        if not Link.FindFirst() then
            Error('UAT: немає Journal Links.');
        JournalLine.SetRange("Journal Template Name", Link."Journal Template");
        JournalLine.SetRange("Journal Batch Name", Link."Journal Batch");
        if JournalLine.Count() <> 3 then
            Error('UAT: у спільному пакеті не рівно 3 залишкові рядки. Ручний аудит.');
        if Link.FindSet() then
            repeat
                LineIndex += 1;
                if LineIndex > 4 then begin
                    if not JournalLine.Get(Link."Journal Template", Link."Journal Batch", Link."Journal Line No.") then
                        Error('UAT: залишковий рядок %1 відсутній.', Link."Link Line No.");
                    if (JournalLine.SystemId <> Link."Journal Line SystemId") or
                       (JournalLine."Document No." <> Fact."Accounting Document No.") or
                       (JournalLine."Item No." <> Link."Expected Item No.") or
                       (JournalLine.Quantity <> Link."Expected Quantity") then
                        Error('UAT: залишковий рядок %1 змінений. Ніяких видалень.', Link."Link Line No.");
                end;
            until Link.Next() = 0;
        if not Confirm('UAT: після перевірки Recovery видалити ТІЛЬКИ 3 непроведені рядки документа %1?\4 проведені ILE, Journal Links, Fact і Started залишаться без змін.',
            false, Fact."Accounting Document No.") then
            exit;
        // Lock and re-check the facts of the fixture before destructive cleanup.
        JournalLine.LockTable();
        if (Control.LedgerStatus(Fact, Posted, Missing) <> 2) or (Posted <> 4) or (Missing <> 3) then
            Error('UAT: ILE змінилися під час підтвердження.');
        JournalLine.Reset();
        JournalLine.SetRange("Journal Template Name", Link."Journal Template");
        JournalLine.SetRange("Journal Batch Name", Link."Journal Batch");
        if JournalLine.Count() <> 3 then
            Error('UAT: вміст пакета змінився під час підтвердження.');
        LineIndex := 0;
        if Link.FindSet() then
            repeat
                LineIndex += 1;
                if LineIndex > 4 then begin
                    JournalLine.Get(Link."Journal Template", Link."Journal Batch", Link."Journal Line No.");
                    if (JournalLine.SystemId <> Link."Journal Line SystemId") or
                       (JournalLine."Document No." <> Fact."Accounting Document No.") or
                       (JournalLine."Item No." <> Link."Expected Item No.") or
                       (JournalLine.Quantity <> Link."Expected Quantity") then
                        Error('UAT: рядок %1 змінився перед видаленням.', Link."Link Line No.");
                    JournalLine.Delete(true);
                    Removed += 1;
                end;
            until Link.Next() = 0;
        Message('UAT: видалено %1 непроведених рядки тесту. ILE 4/7 і Posting Attempt = Started НЕ змінено.', Removed);
    end;

    local procedure AssertTestReady(FactEntryNo: Integer; var Fact: Record "SI Prok Production Fact"; var FirstLink: Record "SI Prok Journal Link")
    var
        EnvironmentInfo: Codeunit "Environment Information";
        UserPermissions: Codeunit "User Permissions";
        ConcreteGuard: Codeunit "SI Prok Concrete Identity";
        Control: Codeunit "SI Prok Process Control";
        Shipment: Record "SI Prok Shipment";
        Attempt: Record "SI Prok Posting Attempt";
        Link: Record "SI Prok Journal Link";
        Seen: Dictionary of [Text, Boolean];
        GroupKey: Text;
        Posted: Integer;
        Missing: Integer;
        GroupCount: Integer;
    begin
        if not EnvironmentInfo.IsSandbox() then
            Error('UAT Fault Probe доступний тільки в Sandbox.');
        if not UserPermissions.IsSuper(UserSecurityId()) then
            Error('UAT Fault Probe доступний тільки користувачу SUPER.');
        Fact.Get(FactEntryNo);
        Shipment.SetRange("Production UUID", Fact."Production UUID");
        if not Shipment.FindFirst() then
            Error('UAT: Shipment не знайдено.');
        if (Shipment.Status <> Shipment.Status::Closed) or
           (Shipment."Production Fact Entry No." <> Fact."Entry No.") then
            Error('UAT: тестувати можна лише закрите відвантаження поточного факту.');
        ConcreteGuard.AssertShipment(Shipment, Fact);
        if Attempt.Get(Fact."Production UUID") then
            Error('UAT: Posting Attempt уже існує (%1). Повторне проведення заборонено.', Attempt.Status);
        if Control.AssertPrepared(Fact) <> 7 then
            Error('UAT: потрібен рівно один підготовлений документ із 7 рядків.');
        if Control.LedgerStatus(Fact, Posted, Missing) <> 0 then
            Error('UAT: за документом уже є ILE. Повторне проведення заборонено.');

        Link.SetRange("Fact Entry No.", Fact."Entry No.");
        if not Link.FindSet() then
            Error('UAT: Journal Links відсутні.');
        FirstLink := Link;
        repeat
            GroupKey := StrSubstNo('%1|%2|%3|%4|%5|%6',
                Format(Link."Expected Entry Type"), Link."Expected Item No.",
                Link."Expected Variant Code", Link."Expected Location Code",
                Format(Link."Expected Posting Date"), Link."Expected UoM");
            if Seen.ContainsKey(GroupKey) then
                Error('UAT: два Journal Links мають одну ILE-групу. Для точного тесту 4/7 потрібні 7 різних груп.');
            Seen.Add(GroupKey, true);
            GroupCount += 1;
            if (GroupCount <= 4) and (Link."Material Line No." = 0) then
                Error('UAT: для 4/7 перші чотири зв’язки повинні бути списаннями.');
        until Link.Next() = 0;
        if GroupCount <> 7 then
            Error('UAT: очікували 7 унікальних груп, знайдено %1.', GroupCount);
    end;

    local procedure BeginStartedAttempt(Fact: Record "SI Prok Production Fact"; ProbeKind: Text[30])
    var
        Attempt: Record "SI Prok Posting Attempt";
        Control: Codeunit "SI Prok Process Control";
        Posted: Integer;
        Missing: Integer;
    begin
        Attempt.LockTable();
        if Attempt.Get(Fact."Production UUID") then
            Error('UAT: інший сеанс уже створив Posting Attempt.');
        Control.AssertPrepared(Fact);
        if Control.LedgerStatus(Fact, Posted, Missing) <> 0 then
            Error('UAT: стан ILE змінився до початку тесту.');
        Attempt.Init();
        Attempt."Production UUID" := Fact."Production UUID";
        Attempt."Fact Entry No." := Fact."Entry No.";
        Attempt.Status := Attempt.Status::Started;
        Attempt."Started At" := CurrentDateTime();
        Attempt.Insert(true);
        Fact.Get(Fact."Entry No.");
        Fact."Accounting Diagnostics" := CopyStr(ProbeKind, 1, MaxStrLen(Fact."Accounting Diagnostics"));
        Fact.Modify(true);
        Commit();
    end;
}
