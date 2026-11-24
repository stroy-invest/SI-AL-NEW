codeunit 57260 "SI Prok Plan Completion Mgt."
{
    // PO-01B: completed imported physical batches, not MES order status or produced volume.
    // Does not finish/post the standard BC Production Order.
    procedure UpdateForFact(FactEntryNo: Integer)
    var
        Fact: Record "SI Prok Production Fact";
        Revision: Record "SI Concrete Recipe Revision";
        BatchRevision: Record "SI Concrete Recipe Revision";
        Plan: Record "SI Prok Production Plan";
        Batch: Record "SI Prok Production Fact";
        Missing: Integer;
        Total: Decimal;
        Reason: Text;
    begin
        if not Fact.Get(FactEntryNo) then
            exit;
        if not Revision.Get(Fact."Recipe No.", Fact."Recipe Revision No.") then
            exit;
        if Revision."Recipe Purpose" <> Revision."Recipe Purpose"::Commercial then
            exit;
        if Fact."Prod. Request Entry No." = 0 then
            exit;
        if not Plan.Get(Fact."Prod. Request Entry No.") then
            exit;
        if Plan."BC Prod. Order No." = '' then
            exit;

        Batch.SetRange("Prod. Request Entry No.", Plan."Prod. Request Entry No.");
        if Batch.FindSet() then
            repeat
                // One row per physical Production UUID: enforced by unique table key.
                // A fact with a non-empty Order UUID must belong to this request.
                if BatchRevision.Get(Batch."Recipe No.", Batch."Recipe Revision No.") and
                    (BatchRevision."Recipe Purpose" = BatchRevision."Recipe Purpose"::Commercial) and
                    (not IsNullGuid(Batch."Order UUID")) and
                    (Batch."Order UUID" = Fact."Order UUID") and
                   (Batch."BC Prod. Order No." = Plan."BC Prod. Order No.") then begin
                    if Batch."Planned Quantity M3" = 0 then
                        TrySnapshotBatchPlan(Batch);
                    if Batch."Planned Quantity M3" > 0 then
                        Total += Batch."Planned Quantity M3"
                    else
                        Missing += 1;
                end;
            until Batch.Next() = 0;

        Plan."Completed Planned Qty. M3" := Total;
        if Missing > 0 then
            Reason := StrSubstNo('Не визначено план %1 партій. Підсумок неповний.', Missing)
        else
            Reason := '';
        // Conservative: never mark completed while any linked batch is unresolved.
        if (Missing = 0) and (Total >= Plan."Planned Quantity") and
           (Plan."Planned Quantity" > 0) then begin
            Plan."Production Plan Completed" := true;
            if Plan."Plan Completed At" = 0DT then
                Plan."Plan Completed At" := CurrentDateTime();
        end;
        Plan."Plan Completion Diagnostics" := CopyStr(Reason, 1, MaxStrLen(Plan."Plan Completion Diagnostics"));
        Plan.Modify(true);
    end;

    local procedure TrySnapshotBatchPlan(var Fact: Record "SI Prok Production Fact")
    var
        Mapping: Record "SI Prok Vehicle Mapping";
        VehicleMgt: Codeunit "SI Vehicle Management";
        Quantity: Decimal;
        UoMCode: Code[10];
        Reason: Text;
        VehicleNo: Code[20];
        MixerUuid: Guid;
    begin
        if Fact."Planned Quantity M3" > 0 then
            exit; // Immutable snapshot: never re-read a changed vehicle capacity.
        if Fact."Connection Code" = '' then
            Reason := 'Не задано Connection Code.'
        else begin
            Mapping.SetRange("Connection Code", Fact."Connection Code");
            if (Fact."Truck UUID" <> '') and Evaluate(MixerUuid, Fact."Truck UUID") and
               (not IsNullGuid(MixerUuid)) then
                Mapping.SetRange("External Mixer UUID", MixerUuid)
            else
                Mapping.SetRange("External Mixer Code", CopyStr(Fact."Truck Code", 1, 50));
            if (Fact."Truck UUID" = '') and (Fact."Truck Code" = '') then
                Reason := 'У факті відсутній ідентифікатор автоміксера.'
            else
                if Mapping.Count() <> 1 then
                    Reason := 'Не знайдено однозначної відповідності автоміксера в SI Prok Vehicle Mapping.'
                else begin
                    Mapping.FindFirst();
                    VehicleNo := Mapping."Vehicle No.";
                    if not VehicleMgt.GetActualCharacteristicValue(VehicleNo, 'DRUM-VOLUME', Quantity, UoMCode) then
                        Reason := 'Для ТЗ не задано фактичний DRUM-VOLUME.'
                    else
                        if ((UoMCode <> 'M3') and (UoMCode <> 'М3')) or (Quantity <= 0) then
                            Reason := 'DRUM-VOLUME повинен бути додатним і заданим у M3.';
                end;
        end;
        if Reason = '' then begin
            Fact."Planned Quantity M3" := Quantity;
            Fact."Batch Plan Vehicle No." := VehicleNo;
            Fact."Batch Plan Diagnostics" := '';
        end else
            Fact."Batch Plan Diagnostics" := CopyStr(Reason, 1, MaxStrLen(Fact."Batch Plan Diagnostics"));
        Fact.Modify(true);
    end;
}
