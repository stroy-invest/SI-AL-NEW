codeunit 57199 "SI Prok TC01 Output Override"
{
    // Temporary test-only fixture. Never call from production intake or job queue.
    // TC-01 identifies facts by user-selected Order No. + Production ID.
    procedure Apply()
    var
        Env: Codeunit "Environment Information";
        Fact: Record "SI Prok Production Fact";
        FirstFact: Record "SI Prok Production Fact";
        OrderDialog: Page "SI Prok TC01 Order Dialog";
        SelectedOrderNo: Text[150];
        JournalLink: Record "SI Prok Journal Link";
        PostingAttempt: Record "SI Prok Posting Attempt";
        Material: Record "SI Prok Prod Fact Material";
        Ids: array[5] of BigInteger;
        Quantities: array[5] of Decimal;
        PlannedQuantities: array[5] of Decimal;
        I: Integer;
        Total: Decimal;
    begin
        if not Env.IsSandbox() then
            Error('TC-01: тестове коригування дозволено лише в Sandbox.');

        if OrderDialog.RunModal() <> Action::OK then
            exit;
        SelectedOrderNo := OrderDialog.GetOrderNo();
        if SelectedOrderNo = '' then
            Error('TC-01: Order No. не може бути порожнім.');

        Ids[1] := 910001;
        Ids[2] := 910002;
        Ids[3] := 910003;
        Ids[4] := 910004;
        Ids[5] := 910005;
        Quantities[1] := 11.92;
        Quantities[2] := 7.06;
        Quantities[3] := 12.08;
        Quantities[4] := 6.94;
        Quantities[5] := 11.96;
        PlannedQuantities[1] := 12;
        PlannedQuantities[2] := 7;
        PlannedQuantities[3] := 12;
        PlannedQuantities[4] := 7;
        PlannedQuantities[5] := 12;

        // Validate ALL facts before changing ANY record.
        for I := 1 to ArrayLen(Ids) do begin
            FindUniqueFact(SelectedOrderNo, Ids[I], Fact);
            if I = 1 then
                FirstFact := Fact
            else
                if (Fact."Order UUID" <> FirstFact."Order UUID") or
                   (Fact."Prod. Request Entry No." <> FirstFact."Prod. Request Entry No.") then
                    Error('TC-01: Production ID %1 належить іншому замовленню/заявці.', Ids[I]);

            if not Fact.Simulation then
                Error('TC-01: Production ID %1 не позначено як симуляційний.', Ids[I]);
            if (I > 1) and (Fact."BC Prod. Order No." <> FirstFact."BC Prod. Order No.") then
                Error('TC-01: для вибраного Order No. знайдено різні прив’язки до BC Production Order.');
            if IsNullGuid(Fact."Production UUID") then
                Error('TC-01: Production ID %1 має порожній UUID.', Ids[I]);
            if Fact."Ready for Posting" then
                Error('TC-01: Production ID %1 вже позначено готовим до проведення.', Ids[I]);
            if PostingAttempt.Get(Fact."Production UUID") then
                Error('TC-01: для Production ID %1 існує спроба проведення.', Ids[I]);
            JournalLink.SetRange("Fact Entry No.", Fact."Entry No.");
            if not JournalLink.IsEmpty() then
                Error('TC-01: для Production ID %1 вже створено журнали. Спершу потрібна звірка.', Ids[I]);
            Material.SetRange("Production Fact Entry No.", Fact."Entry No.");
            if Material.IsEmpty() then
                Error('TC-01: для Production ID %1 відсутні матеріали.', Ids[I]);
            Total += Quantities[I];
        end;

        if not Confirm(
            'TC-01: встановити тестовий план і факт випуску для Order No. %1 (5 партій, разом %2 м³)? Матеріали та первинний JSON не змінюються.',
            false, SelectedOrderNo, Total) then
            exit;

        for I := 1 to ArrayLen(Ids) do begin
            FindUniqueFact(SelectedOrderNo, Ids[I], Fact);
            Fact."Planned Quantity M3" := PlannedQuantities[I];
            Fact."Produced Quantity M3" := Quantities[I];
            // Explicit TEST verification; this is not a MES measurement.
            Fact."Verification Status" := Fact."Verification Status"::Verified;
            Fact."Verification Message" := 'TC-01: тестовий підтверджений обсяг; не є вимірюванням MES.';
            Fact."Ready for Posting" := false;
            Fact."Accounting Readiness" := Fact."Accounting Readiness"::Outdated;
            Fact."Accounting Output Qty" := 0;
            Fact."Accounting Material Lines" := 0;
            Clear(Fact."Accounting Checked At");
            Fact."Accounting Diagnostics" := 'TC-01: тестовий план/факт оновлено; повторити Accounting Readiness.';
            Fact.Modify(true);
        end;

        Message('TC-01: оновлено план/факт 5 партій, сумарний факт %1 м³. Матеріали не змінено.', Total);
    end;

    local procedure FindUniqueFact(OrderNo: Text[150]; ProductionId: BigInteger; var Fact: Record "SI Prok Production Fact")
    begin
        Fact.Reset();
        Fact.SetRange("Order No.", OrderNo);
        Fact.SetRange("Production ID", ProductionId);
        if Fact.Count() <> 1 then
            Error('TC-01: для Order No. %1 / Production ID %2 знайдено %3 записів (потрібен рівно один).', OrderNo, ProductionId, Fact.Count());
        Fact.FindFirst();
    end;
}
