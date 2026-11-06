codeunit 57183 "SI Prok UoM Normalizer"
{
    // Technical enrichment only. Source Proktek kg quantities are immutable.
    procedure NormalizeFact(FactEntryNo: Integer)
    var
        Material: Record "SI Prok Prod Fact Material";
    begin
        Material.SetRange("Production Fact Entry No.", FactEntryNo);
        if Material.FindSet(true) then
            repeat
                NormalizeLine(Material);
            until Material.Next() = 0;
    end;

    local procedure NormalizeLine(var Material: Record "SI Prok Prod Fact Material")
    var
        Item: Record Item;
        Converter: Codeunit "SI Item UoM Conversion";
        SourceUoM: Code[10];
        TargetUoM: Code[10];
        PlanQty: Decimal;
        AdjustedQty: Decimal;
        ActualQty: Decimal;
    begin
        // Clear prior derived values to avoid retaining stale results after changes in master data.
        Clear(Material."BC Base UoM");
        Clear(Material."Requested Base Qty");
        Clear(Material."Adjusted Base Qty");
        Clear(Material."Actual Base Qty");
        Clear(Material."Variance Base Qty");
        Material."UoM Normalized" := false;
        Clear(Material."UoM Diagnostic");

        if not Material."BC Material Resolved" then
            Material."UoM Diagnostic" := 'Матеріал BC не визначено.'
        else
            if not Item.Get(Material."Item No.") then
                Material."UoM Diagnostic" := 'Товар BC не знайдено.'
            else begin
                TargetUoM := Item."Base Unit of Measure";
                Material."BC Base UoM" := TargetUoM;
                if TargetUoM = '' then
                    Material."UoM Diagnostic" := 'У товару BC не визначено базову одиницю виміру.'
                else begin
                    // International ISO alias KG is resolved to the local UoM by Toolkit.
                    SourceUoM := 'KG';
                    if not Converter.CanConvertItemQuantity(Material."Item No.", Material."Variant Code", SourceUoM, TargetUoM) then
                        Material."UoM Diagnostic" := 'Toolkit: немає однозначного правила перерахунку KG у базову ОВ.'
                    else
                        if TryConvertThree(Material."Item No.", Material."Variant Code", SourceUoM, TargetUoM,
                            Material."Requested Kg", Material."Adjusted Kg", Material."Actual Kg",
                            PlanQty, AdjustedQty, ActualQty) then begin
                            Material."Requested Base Qty" := PlanQty;
                            Material."Adjusted Base Qty" := AdjustedQty;
                            Material."Actual Base Qty" := ActualQty;
                            Material."Variance Base Qty" := ActualQty - PlanQty;
                            Material."UoM Normalized" := true;
                        end else
                            Material."UoM Diagnostic" := CopyStr(GetLastErrorText(), 1, MaxStrLen(Material."UoM Diagnostic"));
                end;
            end;
        Material.Modify(true);
    end;

    [TryFunction]
    local procedure TryConvertThree(ItemNo: Code[20]; VariantCode: Code[10]; FromUoM: Code[10]; ToUoM: Code[10];
        RequestedKg: Decimal; AdjustedKg: Decimal; ActualKg: Decimal;
        var PlanQty: Decimal; var AdjustedQty: Decimal; var ActualQty: Decimal)
    var
        Converter: Codeunit "SI Item UoM Conversion";
    begin
        PlanQty := Converter.ConvertItemQuantity(ItemNo, VariantCode, RequestedKg, FromUoM, ToUoM);
        AdjustedQty := Converter.ConvertItemQuantity(ItemNo, VariantCode, AdjustedKg, FromUoM, ToUoM);
        ActualQty := Converter.ConvertItemQuantity(ItemNo, VariantCode, ActualKg, FromUoM, ToUoM);
    end;
}
