codeunit 61042 "SI VSC Resolver"
{
    procedure Resolve(ItemNo: Code[20]; VariantCode: Code[10]; RequiredQty: Decimal; UoMCode: Code[10]; RequiredDate: Date; ManufacturerCode: Code[20]; var Candidate: Record "SI VSC Candidate" temporary)
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ItemCategory: Record "Item Category";
        CurrentCategoryCode: Code[20];
        CategoryDistance: Integer;
    begin
        Candidate.Reset();
        Candidate.DeleteAll();

        Item.Get(ItemNo);
        Item.TestField("Item Category Code");
        if VariantCode <> '' then
            if not ItemVariant.Get(ItemNo, VariantCode) then
                Error(VariantNotFoundErr, VariantCode, ItemNo);
        if RequiredQty <= 0 then
            Error(QuantityMustBePositiveErr);
        if UoMCode = '' then
            Error(UoMRequiredErr);

        CurrentCategoryCode := Item."Item Category Code";
        CategoryDistance := 0;
        while CurrentCategoryCode <> '' do begin
            AddCategoryCandidates(CurrentCategoryCode, CategoryDistance, RequiredQty, UoMCode, RequiredDate, ManufacturerCode, Candidate);

            if not ItemCategory.Get(CurrentCategoryCode) then
                break;
            CurrentCategoryCode := ItemCategory."Parent Category";
            CategoryDistance += 1;
        end;
    end;

    local procedure AddCategoryCandidates(CategoryCode: Code[20]; CategoryDistance: Integer; RequiredQty: Decimal; UoMCode: Code[10]; RequiredDate: Date; ManufacturerCode: Code[20]; var Candidate: Record "SI VSC Candidate" temporary)
    var
        Capability: Record "SI Vendor Supply Capability";
    begin
        Capability.SetRange("Item Category Code", CategoryCode);
        Capability.SetRange(Status, Capability.Status::Active);
        if Capability.FindSet() then
            repeat
                if IsCapabilityApplicable(Capability, RequiredQty, UoMCode, RequiredDate, ManufacturerCode) then
                    InsertCandidate(Capability, CategoryDistance, RequiredQty, RequiredDate, ManufacturerCode, Candidate);
            until Capability.Next() = 0;
    end;

    local procedure IsCapabilityApplicable(Capability: Record "SI Vendor Supply Capability"; RequiredQty: Decimal; UoMCode: Code[10]; RequiredDate: Date; ManufacturerCode: Code[20]): Boolean
    var
        Vendor: Record Vendor;
        EvaluationDate: Date;
        EarliestDeliveryDate: Date;
    begin
        if not Vendor.Get(Capability."Vendor No.") then
            exit(false);
        if Vendor.Blocked <> Vendor.Blocked::" " then
            exit(false);
        EvaluationDate := RequiredDate;
        if EvaluationDate = 0D then
            EvaluationDate := WorkDate();

        if (Capability."Valid From" <> 0D) and (EvaluationDate < Capability."Valid From") then
            exit(false);
        if (Capability."Valid To" <> 0D) and (EvaluationDate > Capability."Valid To") then
            exit(false);

        // MVP v1: VSC quantity constraints are evaluated only in the same UoM.
        // UoM conversion is deliberately not inferred here.
        if (Capability."UoM Code" <> '') and (Capability."UoM Code" <> UoMCode) then
            exit(false);

        if not IsManufacturerAllowed(Capability.Code, ManufacturerCode) then
            exit(false);

        EarliestDeliveryDate := CalcEarliestDeliveryDate(Capability);
        if (RequiredDate <> 0D) and (EarliestDeliveryDate > RequiredDate) then
            exit(false);

        exit(true);
    end;

    local procedure IsManufacturerAllowed(CapabilityCode: Code[20]; ManufacturerCode: Code[20]): Boolean
    var
        VSCManufacturer: Record "SI VSC Manufacturer";
    begin
        // Blank manufacturer means that manufacturer is not a sourcing constraint.
        // In this mode all capabilities remain eligible, including capabilities
        // that have an explicit manufacturer whitelist.
        if ManufacturerCode = '' then
            exit(true);

        VSCManufacturer.SetRange("Capability Code", CapabilityCode);
        if VSCManufacturer.IsEmpty() then
            exit(true); // Empty whitelist = any manufacturer.

        exit(VSCManufacturer.Get(CapabilityCode, ManufacturerCode));
    end;

    local procedure InsertCandidate(Capability: Record "SI Vendor Supply Capability"; CategoryDistance: Integer; RequiredQty: Decimal; RequiredDate: Date; ManufacturerCode: Code[20]; var Candidate: Record "SI VSC Candidate" temporary)
    var
        Vendor: Record Vendor;
        ItemCategory: Record "Item Category";
        VSCManufacturer: Record "SI VSC Manufacturer";
        ShipmentMethod: Record "Shipment Method";
    begin
        Candidate.Init();
        Candidate."Capability Code" := Capability.Code;
        Candidate."Capability Description" := Capability.Description;
        Candidate."Vendor No." := Capability."Vendor No.";
        if Vendor.Get(Capability."Vendor No.") then
            Candidate."Vendor Name" := Vendor.Name;
        Candidate."Matched Category Code" := Capability."Item Category Code";
        if ItemCategory.Get(Capability."Item Category Code") then
            Candidate."Matched Category Description" := ItemCategory.Description;
        Candidate."Category Distance" := CategoryDistance;
        Candidate."Shipment Method Code" := Capability."Shipment Method Code";
        if ShipmentMethod.Get(Capability."Shipment Method Code") then
            Candidate."Shipment Method Description" := ShipmentMethod.Description;
        Candidate."UoM Code" := Capability."UoM Code";
        Candidate."Minimum Order Quantity" := Capability."Minimum Order Quantity";
        Candidate."Order Multiple" := Capability."Order Multiple";
        Candidate."Requested Quantity" := RequiredQty;
        Candidate."Suggested Purchase Quantity" := CalcSuggestedQuantity(RequiredQty, Capability."Minimum Order Quantity", Capability."Order Multiple");
        Candidate."Lead Time Calculation" := Capability."Lead Time Calculation";
        Candidate."Earliest Delivery Date" := CalcEarliestDeliveryDate(Capability);
        Candidate."Required Date" := RequiredDate;
        VSCManufacturer.SetRange("Capability Code", Capability.Code);
        Candidate."Manufacturer Restricted" := not VSCManufacturer.IsEmpty();
        Candidate."Manufacturer Code" := ManufacturerCode;
        Candidate.Insert();
    end;

    procedure CalcSuggestedQuantity(RequiredQty: Decimal; MinimumQty: Decimal; OrderMultiple: Decimal): Decimal
    var
        SuggestedQty: Decimal;
    begin
        SuggestedQty := RequiredQty;
        if SuggestedQty < MinimumQty then
            SuggestedQty := MinimumQty;
        if OrderMultiple > 0 then
            SuggestedQty := Round(SuggestedQty, OrderMultiple, '>');
        exit(SuggestedQty);
    end;

    local procedure CalcEarliestDeliveryDate(Capability: Record "SI Vendor Supply Capability"): Date
    begin
        if Format(Capability."Lead Time Calculation") = '' then
            exit(WorkDate());
        exit(CalcDate(Capability."Lead Time Calculation", WorkDate()));
    end;

    var
        VariantNotFoundErr: Label 'Варіант %1 не існує для товару %2.';
        QuantityMustBePositiveErr: Label 'Кількість потреби має бути більшою за нуль.';
        UoMRequiredErr: Label 'Для визначення каналів постачання потрібно вказати одиницю виміру.';
}
