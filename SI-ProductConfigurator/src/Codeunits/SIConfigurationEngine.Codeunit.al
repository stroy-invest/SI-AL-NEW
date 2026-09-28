codeunit 53004 "SI Configuration Engine"
{
    procedure RebuildConfiguration(ConfigurationNo: Code[20])
    var
        ProductConfig: Record "SI Product Config.";
        NamingEngine: Codeunit "SI Naming Engine";
        ValidationEngine: Codeunit "SI Validation Engine";
        DescriptionText: Text;
        ShortDescriptionText: Text;
        CompositeKeyText: Text;
        CompositeHashText: Text;
        SearchText: Text;
    begin
        ProductConfig.Get(ConfigurationNo);
        ValidationEngine.CheckRebuildAllowed(ProductConfig);

        DescriptionText :=
            NamingEngine.BuildDescription(ConfigurationNo);
        ShortDescriptionText :=
            NamingEngine.BuildShortDescription(ConfigurationNo);
        CompositeKeyText :=
            NamingEngine.BuildCompositeKey(ConfigurationNo);
        CompositeHashText :=
            NamingEngine.BuildHash(CompositeKeyText);
        SearchText :=
            NamingEngine.BuildSearchText(
                ConfigurationNo,
                DescriptionText);

        ProductConfig.SetGeneratedValues(
            CopyStr(
                DescriptionText,
                1,
                MaxStrLen(ProductConfig.Description)),
            CopyStr(
                ShortDescriptionText,
                1,
                MaxStrLen(ProductConfig."Short Description")),
            CopyStr(
                CompositeKeyText,
                1,
                MaxStrLen(ProductConfig."Composite Key")),
            CopyStr(
                CompositeHashText,
                1,
                MaxStrLen(ProductConfig."Composite Key Hash")),
            CopyStr(
                SearchText,
                1,
                MaxStrLen(ProductConfig."Search Text")));

        ProductConfig.Modify(true);
    end;

    procedure ValidateConfiguration(ConfigurationNo: Code[20]): Boolean
    var
        ProductConfig: Record "SI Product Config.";
        ValidationEngine: Codeunit "SI Validation Engine";
        ValidationErrorText: Text;
    begin
        ProductConfig.Get(ConfigurationNo);

        if not ValidationEngine.TryValidateConfiguration(ConfigurationNo) then begin
            ValidationErrorText := GetLastErrorText();

            ProductConfig.Get(ConfigurationNo);
            ProductConfig.SetValidationResult(
                ProductConfig.Status::Draft,
                CopyStr(
                    ValidationErrorText,
                    1,
                    MaxStrLen(ProductConfig."Validation Message")));
            ProductConfig.Modify(true);

            exit(false);
        end;

        RebuildConfiguration(ConfigurationNo);

        ProductConfig.Get(ConfigurationNo);
        ProductConfig.SetValidationResult(
            ProductConfig.Status::Validated,
            ValidationSuccessfulMsg);
        ProductConfig.Modify(true);

        exit(true);
    end;

    procedure CreateProductFamily(
        FamilyCode: Code[30];
        Description: Text[100];
        DescriptionEN: Text[100];
        NamePrefix: Text[50];
        SupportsRecipes: Boolean;
        SortOrder: Integer): Code[30]
    var
        ProductFamily: Record "SI Product Family";
    begin
        ValidateNewFamilyIdentity(
            FamilyCode,
            Description);

        InsertProductFamily(
            ProductFamily,
            FamilyCode,
            Description,
            DescriptionEN,
            NamePrefix,
            SupportsRecipes,
            SortOrder,
            '',
            '');

        exit(ProductFamily.Code);
    end;

    procedure CreateProductFamilyInCategory(
        FamilyCode: Code[30];
        Description: Text[100];
        DescriptionEN: Text[100];
        NamePrefix: Text[50];
        SupportsRecipes: Boolean;
        SortOrder: Integer;
        ItemTemplateCode: Code[20];
        ItemCategoryCode: Code[20]): Code[30]
    var
        ProductFamily: Record "SI Product Family";
        ValidationEngine: Codeunit "SI Validation Engine";
    begin
        ValidateNewFamilyIdentity(
            FamilyCode,
            Description);

        ValidationEngine.ValidateCategoryForFamily(
            ItemCategoryCode,
            '');

        InsertProductFamily(
            ProductFamily,
            FamilyCode,
            Description,
            DescriptionEN,
            NamePrefix,
            SupportsRecipes,
            SortOrder,
            ItemCategoryCode,
            ItemTemplateCode);

        exit(ProductFamily.Code);
    end;

    procedure CreateProductFamilyWithChildCategory(
        FamilyCode: Code[30];
        Description: Text[100];
        DescriptionEN: Text[100];
        NamePrefix: Text[50];
        SupportsRecipes: Boolean;
        SortOrder: Integer;
        ItemTemplateCode: Code[20];
        ParentCategoryCode: Code[20];
        NewCategoryCode: Code[20];
        NewCategoryDescription: Text[100]): Code[30]
    var
        ItemCategory: Record "Item Category";
        ProductFamily: Record "SI Product Family";
        ValidationEngine: Codeunit "SI Validation Engine";
    begin
        ValidateNewFamilyIdentity(
            FamilyCode,
            Description);

        ValidationEngine.ValidateNewChildCategory(
            ParentCategoryCode,
            NewCategoryCode,
            NewCategoryDescription);

        ItemCategory.Init();
        ItemCategory.Validate(Code, NewCategoryCode);
        ItemCategory.Validate(
            Description,
            NewCategoryDescription);
        ItemCategory.Validate(
            "Parent Category",
            ParentCategoryCode);
        ItemCategory.Insert(true);

        InsertProductFamily(
            ProductFamily,
            FamilyCode,
            Description,
            DescriptionEN,
            NamePrefix,
            SupportsRecipes,
            SortOrder,
            ItemCategory.Code,
            ItemTemplateCode);

        exit(ProductFamily.Code);
    end;

    procedure CreateParameterForFamily(
        FamilyCode: Code[30];
        ParameterBuffer: Record "SI Product Parameter";
        FamilyParameterBuffer: Record "SI Family Parameter"): Code[30]
    var
        ProductFamily: Record "SI Product Family";
        ProductParameter: Record "SI Product Parameter";
        FamilyParameter: Record "SI Family Parameter";
    begin
        ProductFamily.Get(FamilyCode);

        if ProductFamily.Blocked then
            Error(
                FamilyBlockedForParameterErr,
                FamilyCode);

        ParameterBuffer.TestField(Code);
        ParameterBuffer.TestField(Description);

        if ProductParameter.Get(ParameterBuffer.Code) then
            Error(
                ProductParameterAlreadyExistsErr,
                ParameterBuffer.Code);

        ProductParameter.Init();
        ProductParameter.Validate(Code, ParameterBuffer.Code);
        ProductParameter.Validate(
            Description,
            ParameterBuffer.Description);
        ProductParameter.Validate(
            "Description EN",
            ParameterBuffer."Description EN");
        ProductParameter.Validate(
            "Base Item Category Code",
            ParameterBuffer."Base Item Category Code");
        ProductParameter.Validate(
            "Value Type",
            ParameterBuffer."Value Type");

        ValidateParameterCategoryForFamily(
            ProductParameter,
            ProductFamily);

        ProductParameter.Insert(true);

        CreateFamilyParameterRecord(
            FamilyCode,
            ProductParameter.Code,
            FamilyParameterBuffer,
            FamilyParameter);

        exit(ProductParameter.Code);
    end;

    procedure AddExistingParameterToFamily(
        FamilyCode: Code[30];
        ParameterCode: Code[30];
        FamilyParameterBuffer: Record "SI Family Parameter"): Code[30]
    var
        ProductFamily: Record "SI Product Family";
        ProductParameter: Record "SI Product Parameter";
        FamilyParameter: Record "SI Family Parameter";
    begin
        ProductFamily.Get(FamilyCode);

        if ProductFamily.Blocked then
            Error(
                FamilyBlockedForParameterErr,
                FamilyCode);

        if ParameterCode = '' then
            Error(ParameterCodeRequiredErr);

        ProductParameter.Get(ParameterCode);

        if ProductParameter.Blocked then
            Error(
                ProductParameterBlockedForFamilyErr,
                ParameterCode);

        ValidateParameterCategoryForFamily(
            ProductParameter,
            ProductFamily);

        if FamilyParameter.Get(FamilyCode, ParameterCode) then
            Error(
                ParameterAlreadyInFamilyErr,
                ParameterCode,
                FamilyCode);

        CreateFamilyParameterRecord(
            FamilyCode,
            ParameterCode,
            FamilyParameterBuffer,
            FamilyParameter);

        exit(ParameterCode);
    end;

    local procedure CreateFamilyParameterRecord(
        FamilyCode: Code[30];
        ParameterCode: Code[30];
        FamilyParameterBuffer: Record "SI Family Parameter";
        var FamilyParameter: Record "SI Family Parameter")
    begin
        FamilyParameterBuffer.TestField("Parameter Order");

        FamilyParameter.Init();
        FamilyParameter.Validate("Family Code", FamilyCode);
        FamilyParameter.Validate("Parameter Code", ParameterCode);
        FamilyParameter.Validate(
            "Parameter Order",
            FamilyParameterBuffer."Parameter Order");
        FamilyParameter.Validate(
            Mandatory,
            FamilyParameterBuffer.Mandatory);
        FamilyParameter.Validate(
            "ERP Projection Role",
            FamilyParameterBuffer."ERP Projection Role");
        FamilyParameter.Validate(
            "Include in Description",
            FamilyParameterBuffer."Include in Description");
        FamilyParameter.Validate(
            "Description Order",
            FamilyParameterBuffer."Description Order");
        FamilyParameter.Validate(
            "Include in Code",
            FamilyParameterBuffer."Include in Code");
        FamilyParameter.Validate(
            "Code Order",
            FamilyParameterBuffer."Code Order");
        FamilyParameter.Validate(
            "Include in Search",
            FamilyParameterBuffer."Include in Search");
        FamilyParameter.Validate(
            "Recipe Relevant",
            FamilyParameterBuffer."Recipe Relevant");

        if FamilyParameterBuffer."Default Value Code" <> '' then
            FamilyParameter.Validate(
                "Default Value Code",
                FamilyParameterBuffer."Default Value Code");

        FamilyParameter.Insert(true);
    end;

    local procedure ValidateNewFamilyIdentity(
        FamilyCode: Code[30];
        Description: Text[100])
    var
        ProductFamily: Record "SI Product Family";
    begin
        if FamilyCode = '' then
            Error(FamilyCodeRequiredErr);

        if Description = '' then
            Error(FamilyDescriptionRequiredErr);

        if ProductFamily.Get(FamilyCode) then
            Error(
                ProductFamilyAlreadyExistsErr,
                FamilyCode);
    end;

    local procedure InsertProductFamily(
        var ProductFamily: Record "SI Product Family";
        FamilyCode: Code[30];
        Description: Text[100];
        DescriptionEN: Text[100];
        NamePrefix: Text[50];
        SupportsRecipes: Boolean;
        SortOrder: Integer;
        ItemCategoryCode: Code[20];
        ItemTemplateCode: Code[20])
    begin
        ProductFamily.Init();
        ProductFamily.Validate(Code, FamilyCode);
        ProductFamily.Validate(Description, Description);
        ProductFamily.Validate(
            "Description EN",
            DescriptionEN);
        ProductFamily.Validate(
            "Name Prefix",
            NamePrefix);
        ProductFamily.Validate(
            "Supports Recipes",
            SupportsRecipes);
        ProductFamily.Validate(
            "Sort Order",
            SortOrder);

        if ItemCategoryCode <> '' then
            ProductFamily.Validate(
                "Item Category Code",
                ItemCategoryCode);

        if ItemTemplateCode <> '' then
            ProductFamily.Validate(
                "Item Template Code",
                ItemTemplateCode);

        ProductFamily.Insert(true);
    end;


    local procedure ValidateParameterCategoryForFamily(
        ProductParameter: Record "SI Product Parameter";
        ProductFamily: Record "SI Product Family")
    begin
        if IsParameterCategoryApplicable(
            ProductParameter."Base Item Category Code",
            ProductFamily."Item Category Code")
        then
            exit;

        Error(
            ParameterCategoryMismatchErr,
            ProductParameter.Code,
            ProductParameter."Base Item Category Code",
            ProductFamily.Code,
            ProductFamily."Item Category Code");
    end;

    local procedure IsParameterCategoryApplicable(
        ParameterCategoryCode: Code[20];
        FamilyCategoryCode: Code[20]): Boolean
    var
        ItemCategory: Record "Item Category";
        CurrentCategoryCode: Code[20];
    begin
        if ParameterCategoryCode = '' then
            exit(true);

        CurrentCategoryCode := FamilyCategoryCode;

        while CurrentCategoryCode <> '' do begin
            if CurrentCategoryCode = ParameterCategoryCode then
                exit(true);

            if not ItemCategory.Get(CurrentCategoryCode) then
                exit(false);

            CurrentCategoryCode := ItemCategory."Parent Category";
        end;

        exit(false);
    end;

    procedure PromptAssignExistingItemTemplate(
        FamilyCode: Code[30];
        var ItemTemplateCode: Code[20]): Boolean
    begin
        if ItemTemplateCode <> '' then
            exit(true);

        if not Confirm(AssignItemTemplateQst, false, FamilyCode) then
            exit(false);

        exit(SelectExistingItemTemplate(ItemTemplateCode));
    end;

    procedure EnsureFamilyItemTemplate(FamilyCode: Code[30]): Boolean
    var
        ProductFamily: Record "SI Product Family";
        ItemTemplateCode: Code[20];
    begin
        if not ProductFamily.Get(FamilyCode) then
            Error(FamilyNotFoundErr, FamilyCode);

        if ProductFamily."Item Template Code" <> '' then
            exit(true);

        if not PromptAssignExistingItemTemplate(
            ProductFamily.Code,
            ItemTemplateCode)
        then
            exit(false);

        ProductFamily.Validate("Item Template Code", ItemTemplateCode);
        ProductFamily.Modify(true);
        exit(true);
    end;

    procedure SelectExistingItemTemplate(
        var ItemTemplateCode: Code[20]): Boolean
    var
        ItemTemplate: Record "Item Templ.";
        ItemTemplateList: Page "Item Templ. List";
    begin
        Clear(ItemTemplateList);
        ItemTemplateList.LookupMode(true);

        if ItemTemplateList.RunModal() <> Action::LookupOK then
            exit(false);

        ItemTemplateList.GetRecord(ItemTemplate);
        ItemTemplateCode := ItemTemplate.Code;
        exit(ItemTemplateCode <> '');
    end;

    procedure CreateDraftConfiguration(FamilyCode: Code[30]): Code[20]
    var
        ProductConfig: Record "SI Product Config.";
        ProductFamily: Record "SI Product Family";
        ConfigurationNo: Code[20];
    begin
        ProductFamily.Get(FamilyCode);

        if ProductFamily.Blocked then
            Error(BlockedFamilyForConfigurationErr, ProductFamily.Code);

        if not EnsureFamilyItemTemplate(FamilyCode) then
            Error(ItemTemplateAssignmentCancelledErr, FamilyCode);

        // Refresh the record because guided recovery may have assigned the template.
        ProductFamily.Get(FamilyCode);
        ProductFamily.ValidateSetup();

        ConfigurationNo := GetNewConfigurationNo();

        ProductConfig.Init();
        ProductConfig.Validate("No.", ConfigurationNo);
        ProductConfig.Validate("Family Code", FamilyCode);
        ProductConfig.Validate(
            "Include Base Name",
            ProductFamily."Name Prefix" = '');
        ProductConfig.Insert(true);

        ReinitializeConfigurationValues(ProductConfig."No.");

        exit(ProductConfig."No.");
    end;

    procedure CancelDraftConfiguration(ConfigurationNo: Code[20])
    var
        ProductConfig: Record "SI Product Config.";
        ProductConfigValue: Record "SI Product Config. Value";
    begin
        if ConfigurationNo = '' then
            exit;

        if not ProductConfig.Get(ConfigurationNo) then
            exit;

        if ProductConfig.Status <> ProductConfig.Status::Draft then
            exit;

        ProductConfigValue.SetRange("Configuration No.", ConfigurationNo);
        ProductConfigValue.DeleteAll(true);
        ProductConfig.Delete(true);
    end;

    procedure ReinitializeConfigurationValues(ConfigurationNo: Code[20])
    var
        ProductConfig: Record "SI Product Config.";
        FamilyParameter: Record "SI Family Parameter";
        ProductConfigValue: Record "SI Product Config. Value";
        RequiredRole: Enum "SI ERP Projection Role";
    begin
        ProductConfig.Get(ConfigurationNo);
        ProductConfig.TestField("Family Code");

        ProductConfigValue.SetRange("Configuration No.", ConfigurationNo);
        ProductConfigValue.DeleteAll(true);

        if ProductConfig."Base Item No." <> '' then
            RequiredRole := RequiredRole::"Variant Identity"
        else
            RequiredRole := RequiredRole::"Item Identity";

        FamilyParameter.SetCurrentKey(
            "Family Code",
            "Parameter Order",
            "Parameter Code");
        FamilyParameter.SetRange("Family Code", ProductConfig."Family Code");
        FamilyParameter.SetRange("ERP Projection Role", RequiredRole);
        FamilyParameter.SetRange(Blocked, false);

        if FamilyParameter.FindSet() then
            repeat
                if FamilyParameter.Mandatory or
                   (FamilyParameter."Default Value Code" <> '')
                then begin
                    ProductConfigValue.Init();
                    ProductConfigValue.Validate(
                        "Configuration No.",
                        ProductConfig."No.");
                    ProductConfigValue.Validate(
                        "Parameter Code",
                        FamilyParameter."Parameter Code");
                    ProductConfigValue.Insert(true);
                end;
            until FamilyParameter.Next() = 0;
    end;

    procedure SyncMissingParameters(ConfigurationNo: Code[20]): Integer
    var
        ProductConfig: Record "SI Product Config.";
        FamilyParameter: Record "SI Family Parameter";
        ProductConfigValue: Record "SI Product Config. Value";
        RequiredRole: Enum "SI ERP Projection Role";
        AddedCount: Integer;
    begin
        ProductConfig.Get(ConfigurationNo);
        ProductConfig.TestField("Family Code");

        if ProductConfig.Blocked then
            Error(BlockedConfigurationForSyncErr, ProductConfig."No.");

        if ProductConfig.Status <> ProductConfig.Status::Projected then
            Error(ConfigurationNotProjectedForSyncErr, ProductConfig."No.", Format(ProductConfig.Status));

        if ProductConfig."Base Item No." <> '' then
            RequiredRole := RequiredRole::"Variant Identity"
        else
            RequiredRole := RequiredRole::"Item Identity";

        FamilyParameter.SetCurrentKey(
            "Family Code",
            "Parameter Order",
            "Parameter Code");
        FamilyParameter.SetRange("Family Code", ProductConfig."Family Code");
        FamilyParameter.SetRange("ERP Projection Role", RequiredRole);
        FamilyParameter.SetRange(Blocked, false);

        if FamilyParameter.FindSet() then
            repeat
                if not ProductConfigValue.Get(ProductConfig."No.", FamilyParameter."Parameter Code") then begin
                    ProductConfigValue.Init();
                    ProductConfigValue.SetMaintenanceInsertMode(true);
                    ProductConfigValue.Validate("Configuration No.", ProductConfig."No.");
                    ProductConfigValue.Validate("Parameter Code", FamilyParameter."Parameter Code");
                    ProductConfigValue."Maintenance Editable" := true;
                    ProductConfigValue.Insert(true);
                    AddedCount += 1;
                end;
            until FamilyParameter.Next() = 0;

        exit(AddedCount);
    end;

    procedure FinalizeMaintenanceParameters(ConfigurationNo: Code[20]): Integer
    var
        ProductConfig: Record "SI Product Config.";
        ProductConfigValue: Record "SI Product Config. Value";
        FinalizedCount: Integer;
    begin
        ProductConfig.Get(ConfigurationNo);

        if ProductConfig.Blocked then
            Error(BlockedConfigurationForFinalizeErr, ProductConfig."No.");

        if ProductConfig.Status <> ProductConfig.Status::Projected then
            Error(ConfigurationNotProjectedForFinalizeErr, ProductConfig."No.", Format(ProductConfig.Status));

        ProductConfigValue.SetRange("Configuration No.", ProductConfig."No.");
        ProductConfigValue.SetRange("Maintenance Editable", true);

        if ProductConfigValue.FindSet(true) then
            repeat
                ProductConfigValue."Maintenance Editable" := false;
                // Deliberately skip OnModify: after the flag is cleared the normal
                // Projected-configuration edit guard must become effective again.
                ProductConfigValue.Modify(false);
                FinalizedCount += 1;
            until ProductConfigValue.Next() = 0;

        exit(FinalizedCount);
    end;

    local procedure GetNewConfigurationNo(): Code[20]
    var
        ProductConfig: Record "SI Product Config.";
        ConfigurationNo: Code[20];
        GuidText: Text;
    begin
        repeat
            GuidText := DelChr(Format(CreateGuid()), '=', '{}-');
            ConfigurationNo :=
                CopyStr(
                    'CFG' + UpperCase(GuidText),
                    1,
                    MaxStrLen(ProductConfig."No."));
        until not ProductConfig.Get(ConfigurationNo);

        exit(ConfigurationNo);
    end;

    var
        BlockedFamilyForConfigurationErr: Label
            'Сімейство %1 заблоковане й не може використовуватися для створення конфігурації.';

        BlockedConfigurationForSyncErr: Label
            'Конфігурація %1 заблокована. Синхронізація параметрів неможлива.';

        ConfigurationNotProjectedForSyncErr: Label
            'Синхронізація параметрів призначена для спроєктованих конфігурацій. Конфігурація %1 має статус «%2».';

        BlockedConfigurationForFinalizeErr: Label
            'Конфігурація %1 заблокована. Завершення редагування параметрів неможливе.';

        ConfigurationNotProjectedForFinalizeErr: Label
            'Завершення редагування параметрів призначене для спроєктованих конфігурацій. Конфігурація %1 має статус «%2».';

        ValidationSuccessfulMsg: Label
            'Конфігурація пройшла перевірку.';

        FamilyBlockedForParameterErr: Label
            'Сімейство %1 заблоковане. До нього не можна додавати параметри.';

        ProductParameterAlreadyExistsErr: Label
            'Параметр продукту %1 уже існує. Використайте дію «Додати наявний».';

        ProductParameterBlockedForFamilyErr: Label
            'Параметр %1 заблокований і не може бути доданий до сімейства.';

        ParameterAlreadyInFamilyErr: Label
            'Параметр %1 уже доданий до сімейства %2.';

        ParameterCodeRequiredErr: Label
            'Не визначено параметр продукту.';

        FamilyCodeRequiredErr: Label
            'Не визначено код сімейства продуктів.';

        FamilyDescriptionRequiredErr: Label
            'Не визначено назву сімейства продуктів.';

        ProductFamilyAlreadyExistsErr: Label
            'Сімейство продуктів із кодом %1 уже існує.';

        ParameterCategoryMismatchErr: Label
            'Параметр %1 належить до базової категорії %2 і не може бути доданий до сімейства %3 з категорією %4.';

        AssignItemTemplateQst: Label
            'Для сімейства %1 не визначено шаблон товару. Призначити наявний Item Template зараз?';

        ItemTemplateAssignmentCancelledErr: Label
            'Для сімейства %1 не призначено Item Template. Операцію скасовано.';

        FamilyNotFoundErr: Label
            'Сімейство продуктів %1 не знайдено.';
}

