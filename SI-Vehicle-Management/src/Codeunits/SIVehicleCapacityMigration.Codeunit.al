codeunit 63301 "SI Vehicle Capacity Migration"
{
    // Manual migration: validates ALL legacy rows first; does not delete legacy data.
    // When two vehicles of the same model disagree, stop rather than pick a winner.
    procedure MigrateLegacyCapacities()
    var
        Legacy: Record "SI Vehicle Capacity";
        Vehicle: Record "SI Vehicle Profile";
        Existing: Record "SI Vehicle Model Capacity";
        NewCapacity: Record "SI Vehicle Model Capacity";
        CreatedCount: Integer;
    begin
        if not Confirm('Перенести характеристики ТЗ на моделі? Старі записи залишаться без змін.') then exit;
        if Legacy.FindSet() then
            repeat
                Vehicle.Get(Legacy."Vehicle No.");
                Vehicle.TestField("Brand Code");
                Vehicle.TestField("Model Code");
                if Existing.Get(Vehicle."Brand Code", Vehicle."Model Code", Legacy."Capacity Type Code") then
                    AssertSame(Existing, Legacy, Vehicle."No.");
            until Legacy.Next() = 0;
        // Second pass: any conflict with an already-created model row is also checked.
        if Legacy.FindSet() then
            repeat
                Vehicle.Get(Legacy."Vehicle No.");
                if NewCapacity.Get(Vehicle."Brand Code", Vehicle."Model Code", Legacy."Capacity Type Code") then
                    AssertSame(NewCapacity, Legacy, Vehicle."No.")
                else begin
                    NewCapacity.Init();
                    NewCapacity.Validate("Brand Code", Vehicle."Brand Code");
                    NewCapacity.Validate("Model Code", Vehicle."Model Code");
                    NewCapacity.Validate("Capacity Type Code", Legacy."Capacity Type Code");
                    NewCapacity.Validate(Quantity, Legacy.Quantity);
                    NewCapacity.Validate("Unit of Measure Code", Legacy."Unit of Measure Code");
                    NewCapacity.Insert(true);
                    CreatedCount += 1;
                end;
            until Legacy.Next() = 0;
        Message('Перенесення завершено. Створено характеристик моделей: %1. Старі записи збережено.', CreatedCount);
    end;

    local procedure AssertSame(ModelCapacity: Record "SI Vehicle Model Capacity"; Legacy: Record "SI Vehicle Capacity"; VehicleNo: Code[20])
    var
        UoMMgt: Codeunit "SI UoM Mgt.";
        NormalizedQuantity: Decimal;
        Equivalent: Boolean;
    begin
        if ModelCapacity."Unit of Measure Code" = Legacy."Unit of Measure Code" then begin
            NormalizedQuantity := Legacy.Quantity;
            Equivalent := true;
        end else
            if UoMMgt.AreConvertible(Legacy."Unit of Measure Code", ModelCapacity."Unit of Measure Code") then begin
                NormalizedQuantity := UoMMgt.ConvertQuantity(
                    Legacy.Quantity,
                    Legacy."Unit of Measure Code",
                    ModelCapacity."Unit of Measure Code");
                Equivalent := true;
            end;

        // Compare in the model's UoM. Allow tiny decimal rounding differences.
        if Equivalent then
            if Abs(ModelCapacity.Quantity - NormalizedQuantity) <= 0.000001 then
                exit;

        Error('Конфлікт характеристик моделі %1/%2, тип %3, автомобіль %4. Модель: %5 %6; ТЗ: %7 %8. Перенесення зупинено.',
            ModelCapacity."Brand Code", ModelCapacity."Model Code", ModelCapacity."Capacity Type Code", VehicleNo,
            ModelCapacity.Quantity, ModelCapacity."Unit of Measure Code", Legacy.Quantity, Legacy."Unit of Measure Code");
    end;
}
