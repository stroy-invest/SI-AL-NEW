codeunit 55000 "SI Manufacturer Mgt."
{
    procedure IsManufacturerProductAllowed(
        ItemNo: Code[20];
        VariantCode: Code[10];
        ManufacturerProductCode: Code[20]): Boolean
    var
        ApprovedManufacturerProd: Record "SI Approved Manufacturer Prod.";
    begin
        if not IsGloballyAvailable(ManufacturerProductCode) then
            exit(false);

        if not ApprovedManufacturerProd.Get(
            ItemNo,
            VariantCode,
            ManufacturerProductCode)
        then
            exit(false);

        exit(
            ApprovedManufacturerProd."Approval Status" =
            ApprovedManufacturerProd."Approval Status"::Approved);
    end;

    procedure ValidateManufacturerProduct(
        ItemNo: Code[20];
        VariantCode: Code[10];
        ManufacturerProductCode: Code[20])
    begin
        if ManufacturerProductCode = '' then
            exit;

        if not IsManufacturerProductAllowed(
            ItemNo,
            VariantCode,
            ManufacturerProductCode)
        then
            Error(
                ManufacturerProductNotAllowedErr,
                ManufacturerProductCode,
                ItemNo,
                VariantCode);
    end;

    procedure IsGloballyAvailable(
        ManufacturerProductCode: Code[20]): Boolean
    var
        ManufacturerProduct: Record "SI Manufacturer Product";
        Manufacturer: Record "SI Manufacturer";
    begin
        if ManufacturerProductCode = '' then
            exit(false);

        if not ManufacturerProduct.Get(ManufacturerProductCode) then
            exit(false);

        if ManufacturerProduct.Blocked then
            exit(false);

        if not Manufacturer.Get(ManufacturerProduct."Manufacturer Code") then
            exit(false);

        if Manufacturer.Blocked then
            exit(false);

        exit(true);
    end;

    procedure SetApprovedProductFilter(
        var ApprovedManufacturerProd: Record "SI Approved Manufacturer Prod.";
        ItemNo: Code[20];
        VariantCode: Code[10])
    begin
        ApprovedManufacturerProd.Reset();
        ApprovedManufacturerProd.SetRange("Item No.", ItemNo);
        ApprovedManufacturerProd.SetRange("Variant Code", VariantCode);
        ApprovedManufacturerProd.SetRange(
            "Approval Status",
            ApprovedManufacturerProd."Approval Status"::Approved);
    end;

    procedure ValidateGloballyAvailable(
        ManufacturerProductCode: Code[20])
    var
        ManufacturerProduct: Record "SI Manufacturer Product";
        Manufacturer: Record "SI Manufacturer";
    begin
        if ManufacturerProductCode = '' then
            Error(ManufacturerProductRequiredErr);

        if not ManufacturerProduct.Get(ManufacturerProductCode) then
            Error(
                ManufacturerProductNotFoundErr,
                ManufacturerProductCode);

        if ManufacturerProduct.Blocked then
            Error(
                ManufacturerProductBlockedErr,
                ManufacturerProductCode);

        if not Manufacturer.Get(ManufacturerProduct."Manufacturer Code") then
            Error(
                ManufacturerNotFoundErr,
                ManufacturerProduct."Manufacturer Code");

        if Manufacturer.Blocked then
            Error(
                ManufacturerBlockedErr,
                Manufacturer.Code);
    end;

    procedure ConfirmManufacturerBlocking(
        ManufacturerCode: Code[20]): Boolean
    var
        ManufacturerProduct: Record "SI Manufacturer Product";
        ApprovedManufacturerProd: Record "SI Approved Manufacturer Prod.";
    begin
        ManufacturerProduct.SetRange("Manufacturer Code", ManufacturerCode);

        if ManufacturerProduct.FindSet() then
            repeat
                ApprovedManufacturerProd.Reset();
                ApprovedManufacturerProd.SetRange(
                    "Manufacturer Product Code",
                    ManufacturerProduct.Code);
                ApprovedManufacturerProd.SetRange(
                    "Approval Status",
                    ApprovedManufacturerProd."Approval Status"::Approved);

                if not ApprovedManufacturerProd.IsEmpty() then
                    exit(
                        Confirm(
                            ManufacturerHasApprovedMappingsQst,
                            false,
                            ManufacturerCode));
            until ManufacturerProduct.Next() = 0;

        exit(true);
    end;

    procedure ConfirmManufacturerProductBlocking(
        ManufacturerProductCode: Code[20]): Boolean
    var
        ApprovedManufacturerProd: Record "SI Approved Manufacturer Prod.";
    begin
        ApprovedManufacturerProd.SetRange(
            "Manufacturer Product Code",
            ManufacturerProductCode);
        ApprovedManufacturerProd.SetRange(
            "Approval Status",
            ApprovedManufacturerProd."Approval Status"::Approved);

        if ApprovedManufacturerProd.IsEmpty() then
            exit(true);

        exit(
            Confirm(
                ManufacturerProductHasApprovedMappingsQst,
                false,
                ManufacturerProductCode));
    end;

    procedure IsManufacturerAllowedForCategory(
        ItemCategoryCode: Code[20];
        ManufacturerCode: Code[20]): Boolean
    var
        CategoryManufacturer: Record "SI Category Manufacturer";
        Manufacturer: Record "SI Manufacturer";
    begin
        if ItemCategoryCode = '' then
            exit(false);

        if ManufacturerCode = '' then
            exit(false);

        if not Manufacturer.Get(ManufacturerCode) then
            exit(false);

        if Manufacturer.Blocked then
            exit(false);

        exit(
            CategoryManufacturer.Get(
                ItemCategoryCode,
                ManufacturerCode));
    end;

    procedure ValidateManufacturerForCategory(
        ItemCategoryCode: Code[20];
        ManufacturerCode: Code[20])
    begin
        if ItemCategoryCode = '' then
            Error(ItemCategoryRequiredErr);

        if ManufacturerCode = '' then
            Error(ManufacturerRequiredErr);

        if not IsManufacturerAllowedForCategory(
            ItemCategoryCode,
            ManufacturerCode)
        then
            Error(
                ManufacturerNotAllowedForCategoryErr,
                ManufacturerCode,
                ItemCategoryCode);
    end;

    procedure SetAllowedManufacturerFilter(
        var CategoryManufacturer: Record "SI Category Manufacturer";
        ItemCategoryCode: Code[20])
    begin
        CategoryManufacturer.Reset();
        CategoryManufacturer.SetRange(
            "Item Category Code",
            ItemCategoryCode);
    end;

    procedure TryLinkExistingVariantFromApprovedProduct(
        var ApprovedProduct: Record "SI Approved Manufacturer Prod.";
        var ExistingVariantCode: Code[10]): Boolean
    var
        ConfigValue: Record "SI Product Config. Value";
        ProductConfig: Record "SI Product Config.";
        ConfigProjection: Record "SI Config. ERP Projection";
        ItemVariant: Record "Item Variant";
        ERPProjectionMgt: Codeunit "SI ERP Projection Mgt.";
        CandidateVariantCode: Code[10];
    begin
        Clear(ExistingVariantCode);

        ApprovedProduct.TestField("Item No.");
        ApprovedProduct.TestField("Manufacturer Product Code");
        ApprovedProduct.TestField(
            "Approval Status",
            ApprovedProduct."Approval Status"::Approved);

        if ApprovedProduct."Variant Code" <> '' then begin
            ExistingVariantCode := ApprovedProduct."Variant Code";
            exit(true);
        end;

        ConfigValue.Reset();
        ConfigValue.SetRange("Reference SystemId", ApprovedProduct.SystemId);

        if ConfigValue.FindSet() then
            repeat
                if ProductConfig.Get(ConfigValue."Configuration No.") then
                    if ProductConfig."Base Item No." = ApprovedProduct."Item No." then
                        if ERPProjectionMgt.HasMaterializedERPLinks(ProductConfig."No.") then
                            if ConfigProjection.Get(ProductConfig."No.") then
                                if (ConfigProjection."Item No." = ApprovedProduct."Item No.") and
                                   (ConfigProjection."Variant Code" <> '') and
                                   ItemVariant.Get(
                                       ConfigProjection."Item No.",
                                       ConfigProjection."Variant Code")
                                then begin
                                    CandidateVariantCode := ConfigProjection."Variant Code";

                                    if ExistingVariantCode = '' then
                                        ExistingVariantCode := CandidateVariantCode
                                    else
                                        if ExistingVariantCode <> CandidateVariantCode then
                                            Error(
                                                MultipleReferencedVariantsErr,
                                                ApprovedProduct."Manufacturer Product Code",
                                                ApprovedProduct."Item No.",
                                                ExistingVariantCode,
                                                CandidateVariantCode);
                                end;
            until ConfigValue.Next() = 0;

        if ExistingVariantCode = '' then
            exit(false);

        EnsureApprovedProductForVariant(
            ApprovedProduct,
            ExistingVariantCode);

        exit(true);
    end;

    procedure CreateVariantFromApprovedProduct(
        var ApprovedProduct: Record "SI Approved Manufacturer Prod.";
        VariantCode: Code[10];
        VariantDescription: Text[100])
    var
        ItemVariant: Record "Item Variant";
    begin
        ApprovedProduct.TestField("Item No.");
        ApprovedProduct.TestField("Manufacturer Product Code");
        ApprovedProduct.TestField(
            "Approval Status",
            ApprovedProduct."Approval Status"::Approved);

        if ApprovedProduct."Variant Code" <> '' then
            Error(VariantAlreadyAssignedErr, ApprovedProduct."Variant Code");

        if VariantCode = '' then
            Error(VariantCodeRequiredErr);

        if ItemVariant.Get(ApprovedProduct."Item No.", VariantCode) then
            Error(
                VariantAlreadyExistsErr,
                VariantCode,
                ApprovedProduct."Item No.");

        ItemVariant.Init();
        ItemVariant.Validate("Item No.", ApprovedProduct."Item No.");
        ItemVariant.Validate(Code, VariantCode);
        ItemVariant.Validate(Description, VariantDescription);
        ItemVariant.Insert(true);

        EnsureApprovedProductForVariant(
            ApprovedProduct,
            VariantCode);
    end;

    local procedure EnsureApprovedProductForVariant(
        ApprovedProduct: Record "SI Approved Manufacturer Prod.";
        VariantCode: Code[10])
    var
        VariantApprovedProduct: Record "SI Approved Manufacturer Prod.";
    begin
        if VariantApprovedProduct.Get(
            ApprovedProduct."Item No.",
            VariantCode,
            ApprovedProduct."Manufacturer Product Code")
        then begin
            if VariantApprovedProduct."Approval Status" <> ApprovedProduct."Approval Status" then begin
                VariantApprovedProduct.Validate(
                    "Approval Status",
                    ApprovedProduct."Approval Status");
                VariantApprovedProduct.Modify(true);
            end;
            exit;
        end;

        VariantApprovedProduct.Init();
        VariantApprovedProduct.Validate("Item No.", ApprovedProduct."Item No.");
        VariantApprovedProduct.Validate("Variant Code", VariantCode);
        VariantApprovedProduct.Validate(
            "Manufacturer Product Code",
            ApprovedProduct."Manufacturer Product Code");
        VariantApprovedProduct.Validate(
            "Approval Status",
            ApprovedProduct."Approval Status");
        VariantApprovedProduct.Insert(true);
    end;

    var
        ManufacturerProductNotAllowedErr: Label
            'Продукт виробника %1 не схвалений для товару %2, варіант %3, або заблокований.';
        ManufacturerProductRequiredErr: Label
            'Необхідно вказати продукт виробника.';

        ManufacturerProductNotFoundErr: Label
            'Продукт виробника %1 не знайдено.';

        ManufacturerProductBlockedErr: Label
            'Продукт виробника %1 заблоковано.';

        ManufacturerNotFoundErr: Label
            'Виробника %1 не знайдено.';

        ManufacturerBlockedErr: Label
            'Виробника %1 заблоковано.';

        ManufacturerHasApprovedMappingsQst: Label
            'Виробник %1 використовується у схвалених продуктах. Після блокування пов''язані продукти стануть недоступними для використання. Продовжити?';

        ManufacturerProductHasApprovedMappingsQst: Label
            'Продукт виробника %1 використовується у схвалених зв''язках. Після блокування він стане недоступним для використання. Продовжити?';

        ItemCategoryRequiredErr: Label
            'Необхідно вказати категорію товару.';

        ManufacturerRequiredErr: Label
            'Необхідно вказати виробника.';

        ManufacturerNotAllowedForCategoryErr: Label
            'Виробник %1 не дозволений для категорії товару %2 або заблокований.';

        VariantAlreadyAssignedErr: Label
            'Для цього схваленого продукту вже задано варіант %1.';

        VariantCodeRequiredErr: Label
            'Необхідно вказати код нового варіанта.';

        VariantAlreadyExistsErr: Label
            'Варіант %1 уже існує для товару %2.';

        MultipleReferencedVariantsErr: Label
            'Для схваленого продукту %1 товару %2 знайдено кілька матеріалізованих варіантів (%3 і %4). Автоматично визначити потрібний варіант неможливо.';
}