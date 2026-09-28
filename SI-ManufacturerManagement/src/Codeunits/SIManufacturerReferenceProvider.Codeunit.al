codeunit 55010 "SI Manufacturer Ref. Provider"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SI Reference Parameter Mgt.", 'OnLookupReferenceValue', '', false, false)]
    local procedure LookupApprovedManufacturerProduct(
        ProductConfig: Record "SI Product Config.";
        FamilyParameter: Record "SI Family Parameter";
        ReferenceType: Enum "SI Parameter Reference Type";
        CurrentSystemId: Guid;
        var SelectedSystemId: Guid;
        var SelectedKey: Text[250];
        var DisplayValue: Text[250];
        var Handled: Boolean)
    var
        ApprovedProduct: Record "SI Approved Manufacturer Prod.";
        CurrentApprovedProduct: Record "SI Approved Manufacturer Prod.";
        ApprovedProductsPage: Page "SI Approved Mfr. Products";
        ReferenceItemNo: Code[20];
        ReferenceVariantCode: Code[10];
    begin
        if ReferenceType <> ReferenceType::"Approved Manufacturer Product" then
            exit;

        Handled := true;

        ResolveReferenceFilter(
            FamilyParameter,
            ReferenceItemNo,
            ReferenceVariantCode);

        SetReferenceFilter(
            ApprovedProduct,
            ReferenceItemNo,
            ReferenceVariantCode);
        ApprovedProductsPage.SetTableView(ApprovedProduct);
        ApprovedProductsPage.LookupMode(true);

        if not IsNullGuid(CurrentSystemId) then begin
            CurrentApprovedProduct.SetRange(SystemId, CurrentSystemId);
            if CurrentApprovedProduct.FindFirst() then
                ApprovedProductsPage.SetRecord(CurrentApprovedProduct);
        end;

        if ApprovedProductsPage.RunModal() <> Action::LookupOK then
            exit;

        ApprovedProductsPage.GetRecord(ApprovedProduct);
        BuildReferenceValue(
            ApprovedProduct,
            SelectedSystemId,
            SelectedKey,
            DisplayValue);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SI Reference Parameter Mgt.", 'OnValidateReferenceValue', '', false, false)]
    local procedure ValidateApprovedManufacturerProduct(
        ProductConfig: Record "SI Product Config.";
        FamilyParameter: Record "SI Family Parameter";
        ReferenceType: Enum "SI Parameter Reference Type";
        ReferenceSystemId: Guid;
        ReferenceKey: Text[250];
        DisplayValue: Text[250];
        var Handled: Boolean)
    var
        ApprovedProduct: Record "SI Approved Manufacturer Prod.";
        ManufacturerMgt: Codeunit "SI Manufacturer Mgt.";
        ReferenceItemNo: Code[20];
        ReferenceVariantCode: Code[10];
    begin
        if ReferenceType <> ReferenceType::"Approved Manufacturer Product" then
            exit;

        Handled := true;

        ResolveReferenceFilter(
            FamilyParameter,
            ReferenceItemNo,
            ReferenceVariantCode);

        ApprovedProduct.SetRange(SystemId, ReferenceSystemId);
        if not ApprovedProduct.FindFirst() then
            Error(ApprovedReferenceMissingErr);

        if (ReferenceItemNo <> '') and
           (ApprovedProduct."Item No." <> ReferenceItemNo)
        then
            Error(ApprovedReferenceContextErr);

        if (ReferenceVariantCode <> '') and
           (ApprovedProduct."Variant Code" <> ReferenceVariantCode)
        then
            Error(ApprovedReferenceContextErr);

        ManufacturerMgt.ValidateManufacturerProduct(
            ApprovedProduct."Item No.",
            ApprovedProduct."Variant Code",
            ApprovedProduct."Manufacturer Product Code");
    end;

    local procedure SetReferenceFilter(
        var ApprovedProduct: Record "SI Approved Manufacturer Prod.";
        ReferenceItemNo: Code[20];
        ReferenceVariantCode: Code[10])
    begin
        ApprovedProduct.Reset();

        // The referenced approved product may belong to another material Item
        // (for example: Concrete configuration -> Plasticizer approved product).
        // Therefore the current configuration Base Item must NOT be used as an
        // implicit filter.
        if ReferenceItemNo <> '' then
            ApprovedProduct.SetRange("Item No.", ReferenceItemNo);

        if ReferenceVariantCode <> '' then
            ApprovedProduct.SetRange("Variant Code", ReferenceVariantCode)
        else
            ApprovedProduct.SetFilter("Variant Code", '<>%1', '');

        ApprovedProduct.SetRange(
            "Approval Status",
            ApprovedProduct."Approval Status"::Approved);
    end;

    local procedure ResolveReferenceFilter(
        FamilyParameter: Record "SI Family Parameter";
        var ReferenceItemNo: Code[20];
        var ReferenceVariantCode: Code[10])
    begin
        // These fields are optional narrowing filters only.
        // If Item is blank, the lookup shows all approved manufacturer products.
        ReferenceItemNo := FamilyParameter."SI Ref. Item No.";
        ReferenceVariantCode := FamilyParameter."SI Ref. Variant Code";

        // A Variant filter without an Item filter is ambiguous and should not
        // silently restrict unrelated Items.
        if (ReferenceItemNo = '') and (ReferenceVariantCode <> '') then
            Clear(ReferenceVariantCode);
    end;

    local procedure BuildReferenceValue(
        var ApprovedProduct: Record "SI Approved Manufacturer Prod.";
        var SelectedSystemId: Guid;
        var SelectedKey: Text[250];
        var DisplayValue: Text[250])
    var
        VariantDescription: Text[100];
    begin
        ApprovedProduct.CalcFields("Variant Description");
        VariantDescription := ApprovedProduct."Variant Description";

        SelectedSystemId := ApprovedProduct.SystemId;
        SelectedKey := CopyStr(
            ApprovedProduct."Item No." + '|' +
            ApprovedProduct."Variant Code" + '|' +
            ApprovedProduct."Manufacturer Product Code",
            1,
            MaxStrLen(SelectedKey));

        // The stored/displayed reference value is always the Item Variant name.
        // Manufacturer name is a naming option only and is resolved separately
        // by OnResolveDescriptionValue.
        DisplayValue := CopyStr(
            VariantDescription,
            1,
            MaxStrLen(DisplayValue));
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SI Naming Engine", 'OnResolveDescriptionValue', '', false, false)]
    local procedure ResolveApprovedManufacturerProductDescription(
        ProductConfig: Record "SI Product Config.";
        FamilyParameter: Record "SI Family Parameter";
        ConfigValue: Record "SI Product Config. Value";
        var DescriptionValue: Text[250])
    var
        ProductParameter: Record "SI Product Parameter";
        ApprovedProduct: Record "SI Approved Manufacturer Prod.";
        ManufacturerProduct: Record "SI Manufacturer Product";
        Manufacturer: Record "SI Manufacturer";
        ManufacturerName: Text[100];
        VariantDescription: Text[100];
    begin
        if ConfigValue."Value Type" <> ConfigValue."Value Type"::Reference then
            exit;

        if not ProductParameter.Get(FamilyParameter."Parameter Code") then
            exit;

        if ProductParameter."Reference Type" <>
           ProductParameter."Reference Type"::"Approved Manufacturer Product"
        then
            exit;

        if IsNullGuid(ConfigValue."Reference SystemId") then
            exit;

        ApprovedProduct.SetRange(SystemId, ConfigValue."Reference SystemId");
        if not ApprovedProduct.FindFirst() then
            exit;

        ApprovedProduct.CalcFields("Variant Description");
        VariantDescription := ApprovedProduct."Variant Description";

        if ManufacturerProduct.Get(ApprovedProduct."Manufacturer Product Code") then
            if Manufacturer.Get(ManufacturerProduct."Manufacturer Code") then
                ManufacturerName := Manufacturer.Name;

        if VariantDescription = '' then
            exit;

        DescriptionValue := CopyStr(
            VariantDescription,
            1,
            MaxStrLen(DescriptionValue));

        if ProductConfig."SI Show Manufacturer in Name" and
           (ManufacturerName <> '')
        then
            DescriptionValue := CopyStr(
                VariantDescription + ' (' + ManufacturerName + ')',
                1,
                MaxStrLen(DescriptionValue));
    end;

    var
        ApprovedReferenceMissingErr: Label 'Вибраний схвалений продукт виробника більше не існує.';
        ApprovedReferenceContextErr: Label 'Вибраний схвалений продукт виробника не належить до товару/варіанта, заданого для цього параметра сімейства.';
}

