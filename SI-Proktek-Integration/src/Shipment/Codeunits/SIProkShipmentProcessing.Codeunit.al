codeunit 57149 "SI Prok Shipment Processing"
{
    procedure AcceptFirstPrint(ShipmentEntryNo: Integer)
    var
        Shipment: Record "SI Prok Shipment";
        Fact: Record "SI Prok Production Fact";
        Setup: Record "SI Prok Operations Setup";
        Attempt: Record "SI Prok Posting Attempt";
        ShipmentMgt: Codeunit "SI Prok Shipment Mgt.";
        ConfirmedQuantity: Decimal;
    begin
        // A previously created Open Shipment can contain an outdated quantity.
        // Persist the verified MES quantity and release locks before Confirm.
        ShipmentMgt.TryRefreshOpenQuantityFromFact(ShipmentEntryNo);
        Commit();
        Shipment.Get(ShipmentEntryNo);
        AssertShipmentReady(Shipment, Fact);
        ConfirmedQuantity := Fact."Produced Quantity M3";
        if not Setup.Get(Shipment."Connection Code") then
            Error('Немає операційних налаштувань для профілю %1.', Shipment."Connection Code");
        if not Confirm(
            'Підтвердити відвантаження №%1 (%2 м³)?\Друк RDL-пакета ще не підключено. Після підтвердження документ буде закрито; режим обліку: %3.',
            false, Shipment."Entry No.", ConfirmedQuantity, Setup."Processing Mode") then
            exit;

        // Recheck after user confirmation under a lock: the confirmed volume
        // must still match the fact and the Open Shipment being closed.
        Shipment.LockTable();
        Shipment.Get(ShipmentEntryNo);
        AssertShipmentReady(Shipment, Fact);
        if Fact."Produced Quantity M3" <> ConfirmedQuantity then
            Error('Підтверджений обсяг факту змінився під час підтвердження. Повторіть дію «Надрукувати».');

        // Must persist before ANY journal preparation or standard posting.
        // A later posting error must never undo the physical shipment event.
        Shipment.CloseAfterPrint();
        Commit();

        // Legacy manually posted facts may already have an Attempt. Close the
        // physical shipment without ever starting a second posting attempt.
        if Attempt.Get(Fact."Production UUID") then begin
            Message('Відвантаження %1 зафіксовано. Для факту вже є облікова спроба (%2); нове проведення не запускалося.',
                Shipment."Entry No.", Attempt.Status);
            exit;
        end;

        case Setup."Processing Mode" of
            Setup."Processing Mode"::Manual:
                RunManual(Shipment);
            Setup."Processing Mode"::Automatic:
                RunWorker(Shipment);
        end;
    end;

    procedure ContinueAccounting(ShipmentEntryNo: Integer)
    var
        Shipment: Record "SI Prok Shipment";
        Setup: Record "SI Prok Operations Setup";
        Fact: Record "SI Prok Production Fact";
        Attempt: Record "SI Prok Posting Attempt";
    begin
        Shipment.Get(ShipmentEntryNo);
        if Shipment.Status <> Shipment.Status::Closed then
            Error('Продовжити облік можна лише після фіксації відвантаження.');
        if not Fact.Get(Shipment."Production Fact Entry No.") then
            Error('Факт виробництва не знайдено.');
        if Attempt.Get(Fact."Production UUID") then
            Error('Для факту вже існує спроба проведення (%1). Використайте аудит або контрольоване відновлення.', Attempt.Status);
        if not Setup.Get(Shipment."Connection Code") then
            Error('Немає операційних налаштувань для профілю %1.', Shipment."Connection Code");
        if Setup."Processing Mode" = Setup."Processing Mode"::Manual then
            RunManual(Shipment)
        else begin
            if not Confirm('Запустити облікову обробку закритого документа %1? Відвантаження повторно не фіксується.',
                false, Shipment."Entry No.") then
                exit;
            RunWorker(Shipment);
        end;
    end;

    procedure RecoverAccounting(ShipmentEntryNo: Integer)
    var
        Shipment: Record "SI Prok Shipment";
        Fact: Record "SI Prok Production Fact";
        Posting: Codeunit "SI Prok Process Posting";
    begin
        Shipment.Get(ShipmentEntryNo);
        if Shipment.Status <> Shipment.Status::Closed then
            Error('Відновлення можливе лише для закритого Shipment.');
        Fact.Get(Shipment."Production Fact Entry No.");
        Posting.RecoverControlled(Fact);
    end;

    local procedure AssertShipmentReady(Shipment: Record "SI Prok Shipment"; var Fact: Record "SI Prok Production Fact")
    begin
        if Shipment.Status <> Shipment.Status::Open then
            Error('Shipment %1 вже закрито.', Shipment."Entry No.");
        if IsNullGuid(Shipment."Production UUID") then
            Error('Shipment не має Production UUID.');
        Shipment.TestField("Production Fact Entry No.");
        if not Fact.Get(Shipment."Production Fact Entry No.") then
            Error('Факт виробництва %1 не знайдено.', Shipment."Production Fact Entry No.");
        if Fact."Production UUID" <> Shipment."Production UUID" then
            Error('UUID Shipment і факту виробництва не збігаються.');
        if Fact."Connection Code" <> Shipment."Connection Code" then
            Error('Профіль Proktek Shipment і факту не збігається.');
        if Fact."Verification Status" <> Fact."Verification Status"::Verified then
            Error('Фактичний обсяг виробництва ще не підтверджено.');
        if Fact."Technical Validation" <> Fact."Technical Validation"::Complete then
            Error('Технічна перевірка факту ще не завершена.');
        if Fact."Produced Quantity M3" <= 0 then
            Error('Підтверджений обсяг виробництва має бути більшим за нуль.');
        if Shipment."Quantity M3" <> Fact."Produced Quantity M3" then
            Error('Обсяг Shipment не відповідає підтвердженому обсягу факту.');
        if (Fact."Item No." = '') or (Shipment."Item No." <> Fact."Item No.") or
           (Shipment."Variant Code" <> Fact."Variant Code") then
            Error('Продукт/варіант Shipment не відповідає виробничому факту.');
        if Shipment."Shipment Date/Time" = 0DT then
            Error('Дата/час виробництва у Shipment відсутні.');
    end;

    local procedure RunManual(Shipment: Record "SI Prok Shipment")
    var
        Fact: Record "SI Prok Production Fact";
        Attempt: Record "SI Prok Posting Attempt";
        Control: Codeunit "SI Prok Process Control";
        Link: Record "SI Prok Journal Link";
        LineCount: Integer;
    begin
        Fact.Get(Shipment."Production Fact Entry No.");
        if Attempt.Get(Fact."Production UUID") then
            Error('Проведення вже запускалося (%1). Повтор заборонено.', Attempt.Status);
        Commit();
        ClearLastError();
        if not Codeunit.Run(Codeunit::"SI Prok Shipment Prep Worker", Shipment) then begin
            ReportAccountingError(Shipment, GetLastErrorText());
            exit;
        end;
        Fact.Get(Fact."Entry No.");
        LineCount := Control.AssertPrepared(Fact);
        // Journal preview is the existing read-only Journal Links page.
        Link.SetRange("Fact Entry No.", Fact."Entry No.");
        Page.RunModal(Page::"SI Prok Journal Links", Link);
        if not Confirm('Провести %1 рядків стандартного товарного журналу для документа %2? Відмова залишить журнал підготовленим.',
            false, LineCount, Fact."Accounting Document No.") then begin
            Message('Shipment %1 закрито. Журнал %2 підготовлено, але не проведено. Облік можна продовжити окремою дією.',
                Shipment."Entry No.", Fact."Accounting Document No.");
            exit;
        end;
        RunWorker(Shipment);
    end;

    local procedure RunWorker(Shipment: Record "SI Prok Shipment")
    var
        Fact: Record "SI Prok Production Fact";
        ErrorText: Text;
    begin
        // Codeunit.Run(Boolean) is an error boundary: posting may partially
        // commit ILEs, so we NEVER retry automatically after failure.
        Commit();
        ClearLastError();
        if not Codeunit.Run(Codeunit::"SI Prok Shipment Post Worker", Shipment) then begin
            ErrorText := GetLastErrorText();
            ReportAccountingError(Shipment, ErrorText);
            exit;
        end;
        Message('Відвантаження %1 зафіксовано. Облік факту %2 проведено стандартним BC.',
            Shipment."Entry No.", Shipment."Production Fact Entry No.");
    end;

    local procedure ReportAccountingError(Shipment: Record "SI Prok Shipment"; ErrorText: Text)
    var
        Fact: Record "SI Prok Production Fact";
    begin
        if ErrorText = '' then
            ErrorText := 'Невідома помилка облікового процесу.';
        if Fact.Get(Shipment."Production Fact Entry No.") then begin
            Fact."Accounting Diagnostics" := CopyStr(StrSubstNo('R2.1: %1', ErrorText),
                1, MaxStrLen(Fact."Accounting Diagnostics"));
            Fact."Accounting Checked At" := CurrentDateTime();
            Fact.Modify(true);
        end;
        Message('Відвантаження %1 зафіксовано. Облік НЕ підтверджено: %2\Перед повтором перевірте Posting Attempt та ILE.',
            Shipment."Entry No.", ErrorText);
    end;

    local procedure IsNullGuid(Value: Guid): Boolean
    begin
        exit(Value = '00000000-0000-0000-0000-000000000000');
    end;
}
