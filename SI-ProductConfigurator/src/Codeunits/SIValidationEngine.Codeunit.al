codeunit 53003 "SI Validation Engine"
{
    [TryFunction]
    procedure TryValidateConfiguration(ConfigurationNo: Code[20])
    var
        ProductConfig: Record "SI Product Config.";
        ProductFamily: Record "SI Product Family";
    begin
        ProductConfig.Get(ConfigurationNo);
        ProductConfig.TestField("Family Code");

        if ProductConfig.Blocked then
            Error(
                BlockedConfigurationErr,
                ProductConfig."No.");

        if ProductConfig.Status <> ProductConfig.Status::Draft then
            Error(
                InvalidStatusForValidationErr,
                ProductConfig."No.",
                Format(ProductConfig.Status));

        ProductFamily.Get(ProductConfig."Family Code");

        if ProductFamily.Blocked then
            Error(
                BlockedFamilyErr,
                ProductFamily.Code);

        ValidateMandatoryParameters(ProductConfig);
        ValidateExistingValues(ProductConfig);
        ValidateIdentityModel(ProductConfig);
        CheckDuplicate(ConfigurationNo);
    end;

    procedure CheckDuplicate(ConfigurationNo: Code[20])
    var
        ProductConfig: Record "SI Product Config.";
        DuplicateConfig: Record "SI Product Config.";
        NamingEngine: Codeunit "SI Naming Engine";
        CompositeKeyText: Text;
        CompositeHashText: Text;
    begin
        ProductConfig.Get(ConfigurationNo);

        CompositeKeyText :=
            NamingEngine.BuildCompositeKey(ConfigurationNo);
        CompositeHashText :=
            NamingEngine.BuildHash(CompositeKeyText);

        if CompositeHashText = '' then
            exit;

        DuplicateConfig.SetCurrentKey("Composite Key Hash");
        DuplicateConfig.SetRange(
            "Composite Key Hash",
            CopyStr(
                CompositeHashText,
                1,
                MaxStrLen(DuplicateConfig."Composite Key Hash")));
        DuplicateConfig.SetFilter(
            "No.",
            '<>%1',
            ConfigurationNo);

        if DuplicateConfig.FindSet() then
            repeat
                if DuplicateConfig."Composite Key" = CompositeKeyText then
                    Error(
                        DuplicateConfigurationErr,
                        ConfigurationNo,
                        DuplicateConfig."No.");
            until DuplicateConfig.Next() = 0;
    end;

    procedure CheckRebuildAllowed(
        ProductConfig: Record "SI Product Config.")
    begin
        if ProductConfig.Blocked then
            Error(
                BlockedConfigurationErr,
                ProductConfig."No.");

        if ProductConfig.Status <> ProductConfig.Status::Draft then
            Error(
                RebuildNotAllowedErr,
                ProductConfig."No.",
                Format(ProductConfig.Status));
    end;

    procedure ValidateCategoryForFamily(
        ItemCategoryCode: Code[20];
        ExcludedFamilyCode: Code[30])
    var
        ItemCategory: Record "Item Category";
        ChildCategory: Record "Item Category";
    begin
        if ItemCategoryCode = '' then
            Error(ItemCategoryRequiredErr);

        if not ItemCategory.Get(ItemCategoryCode) then
            Error(ItemCategoryDoesNotExistErr, ItemCategoryCode);

        ChildCategory.SetRange(
            "Parent Category",
            ItemCategoryCode);

        if not ChildCategory.IsEmpty() then
            Error(ItemCategoryMustBeLeafErr, ItemCategoryCode);

        // A Business Central Item Category classifies products and is not
        // owned by a Product Family. Multiple Product Families may therefore
        // point to the same leaf category (Category 1:N Product Families).
        // ExcludedFamilyCode is intentionally retained in the public procedure
        // signature for backward compatibility with existing callers.
    end;

    procedure ValidateNewChildCategory(
        ParentCategoryCode: Code[20];
        NewCategoryCode: Code[20];
        NewCategoryDescription: Text[100])
    var
        ParentCategory: Record "Item Category";
        ItemCategory: Record "Item Category";
    begin
        if ParentCategoryCode = '' then
            Error(ParentCategoryRequiredErr);

        if not ParentCategory.Get(ParentCategoryCode) then
            Error(
                ItemCategoryDoesNotExistErr,
                ParentCategoryCode);

        if NewCategoryCode = '' then
            Error(NewCategoryCodeRequiredErr);

        if NewCategoryDescription = '' then
            Error(NewCategoryDescriptionRequiredErr);

        if ItemCategory.Get(NewCategoryCode) then
            Error(
                ItemCategoryAlreadyExistsErr,
                NewCategoryCode);
    end;

    local procedure ValidateMandatoryParameters(
        ProductConfig: Record "SI Product Config.")
    var
        FamilyParameter: Record "SI Family Parameter";
        ConfigValue: Record "SI Product Config. Value";
        RequiredRole: Enum "SI ERP Projection Role";
    begin
        if ProductConfig."Base Item No." <> '' then
            RequiredRole := RequiredRole::"Variant Identity"
        else
            RequiredRole := RequiredRole::"Item Identity";

        FamilyParameter.SetCurrentKey(
            "Family Code",
            "Parameter Order",
            "Parameter Code");
        FamilyParameter.SetRange(
            "Family Code",
            ProductConfig."Family Code");
        FamilyParameter.SetRange("ERP Projection Role", RequiredRole);
        FamilyParameter.SetRange(Mandatory, true);

        if FamilyParameter.FindSet() then
            repeat
                if FamilyParameter.Blocked then
                    Error(
                        MandatoryParameterBlockedErr,
                        FamilyParameter."Parameter Code",
                        ProductConfig."Family Code");

                if not ConfigValue.Get(
                    ProductConfig."No.",
                    FamilyParameter."Parameter Code")
                then
                    Error(
                        MandatoryParameterMissingErr,
                        FamilyParameter."Parameter Code",
                        ProductConfig."No.");

                ConfigValue.ValidateCompleteValue();
            until FamilyParameter.Next() = 0;
    end;

    local procedure ValidateExistingValues(
        ProductConfig: Record "SI Product Config.")
    var
        ConfigValue: Record "SI Product Config. Value";
        FamilyParameter: Record "SI Family Parameter";
        RequiredRole: Enum "SI ERP Projection Role";
    begin
        if ProductConfig."Base Item No." <> '' then
            RequiredRole := RequiredRole::"Variant Identity"
        else
            RequiredRole := RequiredRole::"Item Identity";

        ConfigValue.SetCurrentKey(
            "Configuration No.",
            "Parameter Order",
            "Parameter Code");
        ConfigValue.SetRange(
            "Configuration No.",
            ProductConfig."No.");

        if ConfigValue.FindSet() then
            repeat
                FamilyParameter.Get(
                    ProductConfig."Family Code",
                    ConfigValue."Parameter Code");

                if FamilyParameter."ERP Projection Role" <> RequiredRole then
                    Error(
                        InvalidModeParameterErr,
                        ConfigValue."Parameter Code",
                        Format(RequiredRole),
                        ProductConfig."No.");

                ConfigValue.ValidateCompleteValue();
            until ConfigValue.Next() = 0;
    end;

    local procedure ValidateIdentityModel(
        ProductConfig: Record "SI Product Config.")
    var
        ProductFamily: Record "SI Product Family";
        FamilyParameter: Record "SI Family Parameter";
        Item: Record Item;
        HasItemIdentity: Boolean;
        HasVariantIdentity: Boolean;
    begin
        FamilyParameter.SetRange(
            "Family Code",
            ProductConfig."Family Code");
        FamilyParameter.SetRange(Blocked, false);

        FamilyParameter.SetRange(
            "ERP Projection Role",
            FamilyParameter."ERP Projection Role"::"Item Identity");
        HasItemIdentity := not FamilyParameter.IsEmpty();

        FamilyParameter.SetRange(
            "ERP Projection Role",
            FamilyParameter."ERP Projection Role"::"Variant Identity");
        HasVariantIdentity := not FamilyParameter.IsEmpty();

        if ProductConfig."Base Item No." = '' then begin
            if not HasItemIdentity then
                Error(
                    ItemIdentityMissingErr,
                    ProductConfig."Family Code");

            exit;
        end;

        if not HasVariantIdentity then
            Error(
                VariantIdentityMissingErr,
                ProductConfig."Family Code");

        ProductFamily.Get(ProductConfig."Family Code");
        Item.Get(ProductConfig."Base Item No.");

        if Item.Blocked then
            Error(
                BaseItemBlockedErr,
                Item."No.");

        if ProductFamily."Item Category Code" = '' then
            Error(
                FamilyCategoryRequiredErr,
                ProductFamily.Code);

        if Item."Item Category Code" <> ProductFamily."Item Category Code" then
            Error(
                BaseItemCategoryMismatchErr,
                Item."No.",
                Item."Item Category Code",
                ProductFamily."Item Category Code");
    end;

    var
        BlockedConfigurationErr: Label
            'Конфігурація %1 заблокована й не може бути оброблена.';

        InvalidStatusForValidationErr: Label
            'Конфігурацію %1 зі статусом «%2» не можна перевірити.';

        RebuildNotAllowedErr: Label
            'Не можна оновити представлення конфігурації %1 зі статусом «%2».';

        BlockedFamilyErr: Label
            'Сімейство %1 заблоковане й не може використовуватися.';

        MandatoryParameterBlockedErr: Label
            'Обов’язковий параметр %1 заблокований у сімействі %2. Перевірте налаштування сімейства.';

        MandatoryParameterMissingErr: Label
            'Не задано обов’язковий параметр %1 у конфігурації %2.';

        IdentityModelMissingErr: Label
            'Для сімейства %1 не налаштовано активних параметрів, що визначають ані товар, ані його варіант.';

        ItemIdentityMissingErr: Label
            'Для сімейства %1 не налаштовано активних параметрів ідентичності товару.';

        VariantIdentityMissingErr: Label
            'Для сімейства %1 не налаштовано активних параметрів ідентичності варіанта.';

        InvalidModeParameterErr: Label
            'Параметр %1 не відповідає режиму «%2» у конфігурації %3.';

        BaseItemRequiredErr: Label
            'Сімейство %1 визначає тільки варіант товару. Виберіть базовий товар.';

        BaseItemBlockedErr: Label
            'Базовий товар %1 заблокований і не може використовуватися.';

        FamilyCategoryRequiredErr: Label
            'Для сімейства %1 не визначено категорію товару Business Central.';

        BaseItemCategoryMismatchErr: Label
            'Базовий товар %1 належить до категорії %2, але сімейство налаштовано для категорії %3.';

        DuplicateConfigurationErr: Label
            'Конфігурація %1 дублює наявну конфігурацію %2.';

        ItemCategoryRequiredErr: Label
            'Не визначено категорію товару Business Central.';

        ParentCategoryRequiredErr: Label
            'Не визначено батьківську категорію товару.';

        ItemCategoryDoesNotExistErr: Label
            'Категорія товару %1 не існує.';

        ItemCategoryMustBeLeafErr: Label
            'Категорія товару %1 має дочірні категорії й не може бути безпосередньо пов’язана із сімейством. Виберіть кінцевий листок дерева.';


        NewCategoryCodeRequiredErr: Label
            'Укажіть код нової дочірньої категорії товару.';

        NewCategoryDescriptionRequiredErr: Label
            'Укажіть назву нової дочірньої категорії товару.';

        ItemCategoryAlreadyExistsErr: Label
            'Категорія товару з кодом %1 уже існує.';
}
