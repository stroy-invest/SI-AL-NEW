codeunit 63300 "SI Vehicle Management"
{
    procedure AssignVehicleNo(var Vehicle: Record "SI Vehicle Profile")
    var
        Setup: Record "SI Vehicle Setup";
        NoSeries: Codeunit "No. Series";
    begin
        // Existing records retain their original primary keys.
        if Vehicle."No." <> '' then
            exit;
        if not Setup.Get('SETUP') then
            Error('Налаштуйте нумерацію в Налаштуваннях транспорту.');
        Setup.TestField("Vehicle Nos.");
        Vehicle."No." := NoSeries.GetNextNo(Setup."Vehicle Nos.", WorkDate());
    end;

    procedure AssertUniqueInventoryNo(Vehicle: Record "SI Vehicle Profile")
    var
        Other: Record "SI Vehicle Profile";
    begin
        if Vehicle."Inventory No." = '' then
            exit;
        Other.SetRange("Inventory No.", Vehicle."Inventory No.");
        Other.SetFilter("No.", '<>%1', Vehicle."No.");
        if not Other.IsEmpty() then
            Error('Інвентарний номер %1 уже використовується іншим транспортним засобом.', Vehicle."Inventory No.");
    end;

    procedure AssertUniqueVIN(Vehicle: Record "SI Vehicle Profile")
    var
        Other: Record "SI Vehicle Profile";
    begin
        if Vehicle.VIN = '' then exit;
        Other.SetRange(VIN, Vehicle.VIN);
        Other.SetFilter("No.", '<>%1', Vehicle."No.");
        if not Other.IsEmpty() then
            Error('VIN %1 уже використовується іншим транспортним засобом.', Vehicle.VIN);
    end;

    procedure AssertUniqueRegistration(Vehicle: Record "SI Vehicle Profile")
    var
        Other: Record "SI Vehicle Profile";
    begin
        if Vehicle."Registration No." = '' then exit;
        Other.SetRange("Registration No.", Vehicle."Registration No.");
        Other.SetFilter("No.", '<>%1', Vehicle."No.");
        if not Other.IsEmpty() then
            Error('Державний номер %1 уже використовується іншим транспортним засобом.', Vehicle."Registration No.");
    end;

    procedure AssertOperationallyUsable(VehicleNo: Code[20])
    var
        Vehicle: Record "SI Vehicle Profile";
        VehicleType: Record "SI Vehicle Type";
    begin
        Vehicle.Get(VehicleNo);
        Vehicle.TestField(Blocked, false);
        Vehicle.TestField("Vehicle Type Code");
        VehicleType.Get(Vehicle."Vehicle Type Code");
        VehicleType.TestField(Blocked, false);
        if Vehicle."Ownership Type" = Vehicle."Ownership Type"::Owned then
            Vehicle.TestField("Fixed Asset No.");
    end;

    procedure AssertBrandModel(Vehicle: Record "SI Vehicle Profile")
    var
        Brand: Record "SI Vehicle Brand";
        Model: Record "SI Vehicle Model";
    begin
        if Vehicle."Model Code" = '' then exit;
        Vehicle.TestField("Brand Code");
        if not Brand.Get(Vehicle."Brand Code") then
            Error('Бренд %1 не знайдено.', Vehicle."Brand Code");
        if not Model.Get(Vehicle."Brand Code", Vehicle."Model Code") then
            Error('Модель %1 не належить бренду %2.', Vehicle."Model Code", Vehicle."Brand Code");
    end;

    procedure RefreshVehicleDescription(var Vehicle: Record "SI Vehicle Profile")
    var
        Brand: Record "SI Vehicle Brand";
        Model: Record "SI Vehicle Model";
        NewDescription: Text;
    begin
        if (Vehicle."Brand Code" = '') or (Vehicle."Model Code" = '') then exit;
        AssertBrandModel(Vehicle);
        Brand.Get(Vehicle."Brand Code");
        Model.Get(Vehicle."Brand Code", Vehicle."Model Code");
        NewDescription := StrSubstNo('%1 %2', Brand.Name, Model.Name);
        Vehicle.Description := CopyStr(NewDescription, 1, MaxStrLen(Vehicle.Description));
        Vehicle."Search Description" := CopyStr(UpperCase(NewDescription), 1, MaxStrLen(Vehicle."Search Description"));
    end;

    procedure ValidateCapacityTypeDependents(CapacityType: Record "SI Vehicle Capacity Type")
    var
        Capacity: Record "SI Vehicle Capacity";
        ModelCapacity: Record "SI Vehicle Model Capacity";
        SemanticMgt: Codeunit "SI UoM Semantic Mgt.";
    begin
        Capacity.SetRange("Capacity Type Code", CapacityType.Code);
        if Capacity.FindSet() then
            repeat
                CapacityType.TestField("Required Semantic Code");
                SemanticMgt.AssertPhysicalUoM(Capacity."Unit of Measure Code", CapacityType."Required Semantic Code");
            until Capacity.Next() = 0;
        ModelCapacity.SetRange("Capacity Type Code", CapacityType.Code);
        if ModelCapacity.FindSet() then
            repeat
                CapacityType.TestField("Required Semantic Code");
                SemanticMgt.AssertPhysicalUoM(ModelCapacity."Unit of Measure Code", CapacityType."Required Semantic Code");
            until ModelCapacity.Next() = 0;
    end;

    procedure GetCharacteristicValue(
        VehicleNo: Code[20];
        CapacityTypeCode: Code[20];
        var Quantity: Decimal;
        var UoMCode: Code[10]
    ): Boolean
    var
        Vehicle: Record "SI Vehicle Profile";
        ModelCapacity: Record "SI Vehicle Model Capacity";
    begin
        Clear(Quantity);
        Clear(UoMCode);

        if not Vehicle.Get(VehicleNo) then
            exit(false);

        if (Vehicle."Brand Code" = '') or (Vehicle."Model Code" = '') then
            exit(false);

        if not ModelCapacity.Get(
            Vehicle."Brand Code",
            Vehicle."Model Code",
            CapacityTypeCode)
        then
            exit(false);

        Quantity := ModelCapacity.Quantity;
        UoMCode := ModelCapacity."Unit of Measure Code";

        exit(true);
    end;
    // Synchronizes model characteristics to a specific vehicle. Existing actual
    // values are retained unless the nominal limit was reduced below them.
    procedure SyncVehicleActualCapacities(VehicleNo: Code[20])
    var
        Vehicle: Record "SI Vehicle Profile";
        ModelCapacity: Record "SI Vehicle Model Capacity";
        Capacity: Record "SI Vehicle Capacity";
        UoMMgt: Codeunit "SI UoM Mgt.";
        ActualInModelUoM: Decimal;
    begin
        Vehicle.Get(VehicleNo);
        Vehicle.TestField("Brand Code");
        Vehicle.TestField("Model Code");
        ModelCapacity.SetRange("Brand Code", Vehicle."Brand Code");
        ModelCapacity.SetRange("Model Code", Vehicle."Model Code");
        if ModelCapacity.FindSet() then
            repeat
                if Capacity.Get(VehicleNo, ModelCapacity."Capacity Type Code") then begin
                    if (Capacity."Unit of Measure Code" <> ModelCapacity."Unit of Measure Code") and
                       (Capacity."Unit of Measure Code" <> '') then begin
                        if not UoMMgt.AreConvertible(Capacity."Unit of Measure Code", ModelCapacity."Unit of Measure Code") then
                            Error('Несумісні одиниці вимірювання для ТЗ %1, характеристики %2.', VehicleNo, ModelCapacity."Capacity Type Code");
                        ActualInModelUoM := UoMMgt.ConvertQuantity(
                            Capacity."Actual Quantity", Capacity."Unit of Measure Code", ModelCapacity."Unit of Measure Code");
                    end else
                        ActualInModelUoM := Capacity."Actual Quantity";
                    // Legacy rows without Actual Quantity receive the nominal value.
                    if Capacity."Actual Quantity" = 0 then
                        ActualInModelUoM := ModelCapacity.Quantity;
                    if ActualInModelUoM > ModelCapacity.Quantity then
                        Error('Реальне значення ТЗ %1 (%2) перевищує нове номінальне (%3). Спочатку скоригуйте характеристику.',
                            VehicleNo, ActualInModelUoM, ModelCapacity.Quantity);
                    Capacity.Validate("Unit of Measure Code", ModelCapacity."Unit of Measure Code");
                    Capacity.Validate(Quantity, ModelCapacity.Quantity);
                    Capacity."Nominal Quantity" := ModelCapacity.Quantity;
                    Capacity.Validate("Actual Quantity", ActualInModelUoM);
                    Capacity.Modify(true);
                end else begin
                    Capacity.Init();
                    Capacity.Validate("Vehicle No.", VehicleNo);
                    Capacity.Validate("Capacity Type Code", ModelCapacity."Capacity Type Code");
                    Capacity.Validate("Unit of Measure Code", ModelCapacity."Unit of Measure Code");
                    Capacity.Validate(Quantity, ModelCapacity.Quantity);
                    Capacity."Nominal Quantity" := ModelCapacity.Quantity;
                    Capacity.Validate("Actual Quantity", ModelCapacity.Quantity);
                    Capacity.Insert(true);
                end;
            until ModelCapacity.Next() = 0;
    end;

    procedure GetActualCharacteristicValue(
        VehicleNo: Code[20]; CapacityTypeCode: Code[20];
        var ActualQuantity: Decimal; var UoMCode: Code[10]): Boolean
    var
        Capacity: Record "SI Vehicle Capacity";
    begin
        Clear(ActualQuantity);
        Clear(UoMCode);
        if not Capacity.Get(VehicleNo, CapacityTypeCode) then
            exit(false);
        if (Capacity."Actual Quantity" <= 0) or
           (Capacity."Nominal Quantity" <= 0) or
           (Capacity."Actual Quantity" > Capacity."Nominal Quantity") then
            Error('Некоректна реальна характеристика %1 для ТЗ %2.', CapacityTypeCode, VehicleNo);
        ActualQuantity := Capacity."Actual Quantity";
        UoMCode := Capacity."Unit of Measure Code";
        exit(true);
    end;

}
