codeunit 53006 "SI ERP Projection Validator"
{
    // Перевірка готовності ERP-проєкції до матеріалізації.

    procedure ValidatePreview(
        var PrevBuffer: Record "SI ERP Projection Prev Buffer" temporary): Boolean
    var
        ValidationMessage: Text;
        IsValid: Boolean;
    begin
        Clear(ValidationMessage);
        IsValid := true;

        ValidateConfiguration(
            PrevBuffer,
            ValidationMessage,
            IsValid);

        ValidateFamily(
            PrevBuffer,
            ValidationMessage,
            IsValid);

        ValidateCategory(
            PrevBuffer,
            ValidationMessage,
            IsValid);

        ValidateTemplate(
            PrevBuffer,
            ValidationMessage,
            IsValid);

        ValidateBaseUoM(
            PrevBuffer,
            ValidationMessage,
            IsValid);

        ValidateIdentity(
            PrevBuffer,
            ValidationMessage,
            IsValid);

        ValidateRoleSetup(
            PrevBuffer,
            ValidationMessage,
            IsValid);

        ValidatePresentation(
            PrevBuffer,
            ValidationMessage,
            IsValid);

        ValidateKeyCollision(
            PrevBuffer,
            ValidationMessage,
            IsValid);

        if IsValid then
            PrevBuffer.SetValidationResult(
                PrevBuffer.Status::Ready,
                true,
                ReadyMsg)
        else
            PrevBuffer.SetValidationResult(
                PrevBuffer.Status::Previewed,
                false,
                ValidationMessage);

        exit(IsValid);
    end;


    procedure ValidateResolvedContextOrError(
        PrevBuffer: Record "SI ERP Projection Prev Buffer" temporary)
    var
        ProductConfig: Record "SI Product Config.";
        ItemCategory: Record "Item Category";
        ItemTemplate: Record "Item Templ.";
        UnitOfMeasure: Record "Unit of Measure";
    begin
        if PrevBuffer."Configuration No." = '' then
            Error(ConfigNoRequiredErr);

        if not ProductConfig.Get(PrevBuffer."Configuration No.") then
            Error(ConfigNotFoundErr, PrevBuffer."Configuration No.");

        if PrevBuffer."Item Category Code" = '' then
            Error(CategoryRequiredErr);

        if not ItemCategory.Get(PrevBuffer."Item Category Code") then
            Error(CategoryNotFoundErr, PrevBuffer."Item Category Code");

        if PrevBuffer."Base UoM Code" = '' then
            Error(BaseUoMRequiredErr);

        if not UnitOfMeasure.Get(PrevBuffer."Base UoM Code") then
            Error(BaseUoMNotFoundErr, PrevBuffer."Base UoM Code");

        // Item Template is mandatory only in Item mode. Variant mode reuses
        // the complete ERP setup of the explicitly selected Base Item.
        if ProductConfig."Base Item No." <> '' then
            exit;

        if PrevBuffer."Item Template Code" = '' then
            Error(TemplateRequiredErr);

        if not ItemTemplate.Get(PrevBuffer."Item Template Code") then
            Error(TemplateNotFoundErr, PrevBuffer."Item Template Code");
    end;

    procedure SetFailed(
        var PrevBuffer: Record "SI ERP Projection Prev Buffer" temporary;
        ErrorText: Text)
    begin
        PrevBuffer.SetValidationResult(
            PrevBuffer.Status::Failed,
            false,
            ErrorText);
    end;

    local procedure ValidateConfiguration(
        PrevBuffer: Record "SI ERP Projection Prev Buffer" temporary;
        var ValidationMessage: Text;
        var IsValid: Boolean)
    var
        ProductConfig: Record "SI Product Config.";
    begin
        if PrevBuffer."Configuration No." = '' then begin
            AddError(
                ValidationMessage,
                IsValid,
                ConfigNoRequiredErr);
            exit;
        end;

        if not ProductConfig.Get(
            PrevBuffer."Configuration No.")
        then begin
            AddError(
                ValidationMessage,
                IsValid,
                StrSubstNo(
                    ConfigNotFoundErr,
                    PrevBuffer."Configuration No."));
            exit;
        end;

        if ProductConfig.Blocked then
            AddError(
                ValidationMessage,
                IsValid,
                StrSubstNo(
                    ConfigBlockedErr,
                    ProductConfig."No."));

        if ProductConfig.Status =
           ProductConfig.Status::Archived
        then
            AddError(
                ValidationMessage,
                IsValid,
                StrSubstNo(
                    ConfigArchivedErr,
                    ProductConfig."No."));

        if ProductConfig."Family Code" = '' then
            AddError(
                ValidationMessage,
                IsValid,
                StrSubstNo(
                    ConfigFamilyRequiredErr,
                    ProductConfig."No."));

        if (PrevBuffer."Family Code" <> '') and
           (ProductConfig."Family Code" <>
            PrevBuffer."Family Code")
        then
            AddError(
                ValidationMessage,
                IsValid,
                StrSubstNo(
                    ConfigFamilyMismatchErr,
                    ProductConfig."No.",
                    ProductConfig."Family Code",
                    PrevBuffer."Family Code"));
    end;

    local procedure ValidateFamily(
        PrevBuffer: Record "SI ERP Projection Prev Buffer" temporary;
        var ValidationMessage: Text;
        var IsValid: Boolean)
    var
        ProductFamily: Record "SI Product Family";
    begin
        if PrevBuffer."Family Code" = '' then begin
            AddError(
                ValidationMessage,
                IsValid,
                FamilyCodeRequiredErr);
            exit;
        end;

        if not ProductFamily.Get(
            PrevBuffer."Family Code")
        then begin
            AddError(
                ValidationMessage,
                IsValid,
                StrSubstNo(
                    FamilyNotFoundErr,
                    PrevBuffer."Family Code"));
            exit;
        end;

        if ProductFamily.Blocked then
            AddError(
                ValidationMessage,
                IsValid,
                StrSubstNo(
                    FamilyBlockedErr,
                    ProductFamily.Code));

        if ProductFamily."Item Category Code" = '' then
            AddError(
                ValidationMessage,
                IsValid,
                StrSubstNo(
                    FamilyCategoryRequiredErr,
                    ProductFamily.Code));

        if (PrevBuffer."Item Category Code" <> '') and
           (ProductFamily."Item Category Code" <>
            PrevBuffer."Item Category Code")
        then
            AddError(
                ValidationMessage,
                IsValid,
                StrSubstNo(
                    FamilyCategoryMismatchErr,
                    ProductFamily.Code,
                    ProductFamily."Item Category Code",
                    PrevBuffer."Item Category Code"));

        // A mismatch is an error only when the family explicitly specifies a template.
        // If the family field is empty, Context Resolver may legitimately resolve
        // the single standard Item Template assigned to the same Item Category.
        // Item Template is relevant only when a new Item is being created.
        // In Variant mode Existing Item No. is already resolved and Context Resolver
        // intentionally leaves Item Template Code empty.
        if (PrevBuffer."Existing Item No." = '') and
           (ProductFamily."Item Template Code" <> '') and
           (ProductFamily."Item Template Code" <>
            PrevBuffer."Item Template Code")
        then
            AddError(
                ValidationMessage,
                IsValid,
                StrSubstNo(
                    FamilyTemplateMismatchErr,
                    ProductFamily.Code,
                    ProductFamily."Item Template Code",
                    PrevBuffer."Item Template Code"));
    end;

    local procedure ValidateCategory(
        PrevBuffer: Record "SI ERP Projection Prev Buffer" temporary;
        var ValidationMessage: Text;
        var IsValid: Boolean)
    var
        ItemCategory: Record "Item Category";
        ContextResolver: Codeunit "SI ERP Context Resolver";
    begin
        if PrevBuffer."Item Category Code" = '' then begin
            AddError(
                ValidationMessage,
                IsValid,
                CategoryRequiredErr);
            exit;
        end;

        if not ItemCategory.Get(
            PrevBuffer."Item Category Code")
        then begin
            AddError(
                ValidationMessage,
                IsValid,
                StrSubstNo(
                    CategoryNotFoundErr,
                    PrevBuffer."Item Category Code"));
            exit;
        end;

        if ContextResolver.HasChildCategories(
            PrevBuffer."Item Category Code")
        then
            AddError(
                ValidationMessage,
                IsValid,
                StrSubstNo(
                    CategoryNotLeafErr,
                    PrevBuffer."Item Category Code"));
    end;

    local procedure ValidateTemplate(
        PrevBuffer: Record "SI ERP Projection Prev Buffer" temporary;
        var ValidationMessage: Text;
        var IsValid: Boolean)
    var
        ItemTemplate: Record "Item Templ.";
    begin
        // Для Variant mode новий Item не створюється, тому шаблон не є обов'язковим.
        if PrevBuffer."Existing Item No." <> '' then
            exit;

        // Для нового Item шаблон є обов'язковою частиною ERP-контексту.
        if PrevBuffer."Item Template Code" = '' then begin
            AddError(
                ValidationMessage,
                IsValid,
                TemplateRequiredErr);
            exit;
        end;

        if not ItemTemplate.Get(
            PrevBuffer."Item Template Code")
        then
            AddError(
                ValidationMessage,
                IsValid,
                StrSubstNo(
                    TemplateNotFoundErr,
                    PrevBuffer."Item Template Code"));
    end;

    local procedure ValidateBaseUoM(
        PrevBuffer: Record "SI ERP Projection Prev Buffer" temporary;
        var ValidationMessage: Text;
        var IsValid: Boolean)
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        if PrevBuffer."Base UoM Code" = '' then begin
            AddError(
                ValidationMessage,
                IsValid,
                BaseUoMRequiredErr);
            exit;
        end;

        if not UnitOfMeasure.Get(
            PrevBuffer."Base UoM Code")
        then
            AddError(
                ValidationMessage,
                IsValid,
                StrSubstNo(
                    BaseUoMNotFoundErr,
                    PrevBuffer."Base UoM Code"));

        if PrevBuffer."Base UoM Source" =
           PrevBuffer."Base UoM Source"::None
        then
            AddError(
                ValidationMessage,
                IsValid,
                BaseUoMSourceRequiredErr);
    end;

    local procedure ValidateIdentity(
        PrevBuffer: Record "SI ERP Projection Prev Buffer" temporary;
        var ValidationMessage: Text;
        var IsValid: Boolean)
    begin
        if PrevBuffer."Item Projection Key" = '' then
            AddError(
                ValidationMessage,
                IsValid,
                ItemKeyRequiredErr);

        if PrevBuffer."Item Projection Key Hash" = '' then
            AddError(
                ValidationMessage,
                IsValid,
                ItemHashRequiredErr);

        if StrLen(PrevBuffer."Item Projection Key Hash") > 64 then
            AddError(
                ValidationMessage,
                IsValid,
                StrSubstNo(
                    ItemHashTooLongErr,
                    StrLen(
                        PrevBuffer."Item Projection Key Hash"),
                    64));
    end;

    local procedure ValidateRoleSetup(
        PrevBuffer: Record "SI ERP Projection Prev Buffer" temporary;
        var ValidationMessage: Text;
        var IsValid: Boolean)
    var
        ProductConfig: Record "SI Product Config.";
        FamilyParameter: Record "SI Family Parameter";
        HasItemIdentity: Boolean;
        HasVariantIdentity: Boolean;
    begin
        if PrevBuffer."Family Code" = '' then
            exit;

        FamilyParameter.SetRange(
            "Family Code",
            PrevBuffer."Family Code");
        FamilyParameter.SetRange(Blocked, false);

        FamilyParameter.SetRange(
            "ERP Projection Role",
            FamilyParameter."ERP Projection Role"::"Item Identity");
        HasItemIdentity := not FamilyParameter.IsEmpty();

        FamilyParameter.SetRange(
            "ERP Projection Role",
            FamilyParameter."ERP Projection Role"::"Variant Identity");
        HasVariantIdentity := not FamilyParameter.IsEmpty();

        if HasItemIdentity then
            exit;

        if not HasVariantIdentity then begin
            AddError(
                ValidationMessage,
                IsValid,
                StrSubstNo(
                    IdentityRoleMissingErr,
                    PrevBuffer."Family Code"));
            exit;
        end;

        if ProductConfig.Get(PrevBuffer."Configuration No.") then
            if ProductConfig."Base Item No." = '' then
                AddError(
                    ValidationMessage,
                    IsValid,
                    StrSubstNo(
                        BaseItemRequiredErr,
                        PrevBuffer."Family Code"));
    end;

    local procedure ValidatePresentation(
        PrevBuffer: Record "SI ERP Projection Prev Buffer" temporary;
        var ValidationMessage: Text;
        var IsValid: Boolean)
    begin
        // Generated Item presentation is mandatory only when a new Item must be created.
        // For a configuration linked to an existing/base Item, the Item already owns its code and description.
        if PrevBuffer."Existing Item No." = '' then begin
            ValidateItemCode(
                PrevBuffer,
                ValidationMessage,
                IsValid);

            ValidateItemDescription(
                PrevBuffer,
                ValidationMessage,
                IsValid);
        end;

        // Variant Code is a technical ERP identifier and is assigned by the materializer.
        // Preview validates only semantic variant readiness and its human-readable description.
        if PrevBuffer."Variant Projection Key" <> '' then
            ValidateVariantDesc(PrevBuffer, ValidationMessage, IsValid)
        else
            if (PrevBuffer."Generated Variant Code" <> '') or
               (PrevBuffer."Generated Variant Description" <> '')
            then
                AddError(ValidationMessage, IsValid, UnexpectedVariantPresentationErr);
    end;

    local procedure HasVariantIdentity(FamilyCode: Code[30]): Boolean
    var
        IdentityMgt: Codeunit "SI Product Identity Mgt.";
    begin
        if FamilyCode = '' then
            exit(false);
        exit(IdentityMgt.HasVariantIdentity(FamilyCode));
    end;

    local procedure ValidateItemCode(
        PrevBuffer: Record "SI ERP Projection Prev Buffer" temporary;
        var ValidationMessage: Text;
        var IsValid: Boolean)
    begin
        if PrevBuffer."Generated Item Code" = '' then begin
            AddError(
                ValidationMessage,
                IsValid,
                ItemCodeRequiredErr);
            exit;
        end;

        if StrLen(
            PrevBuffer."Generated Item Code") > 20
        then
            AddError(
                ValidationMessage,
                IsValid,
                StrSubstNo(
                    ItemCodeTooLongErr,
                    StrLen(
                        PrevBuffer."Generated Item Code"),
                    20));
    end;

    local procedure ValidateItemDescription(
        PrevBuffer: Record "SI ERP Projection Prev Buffer" temporary;
        var ValidationMessage: Text;
        var IsValid: Boolean)
    begin
        if PrevBuffer."Generated Item Description" = '' then begin
            AddError(
                ValidationMessage,
                IsValid,
                ItemDescriptionRequiredErr);
            exit;
        end;

        if StrLen(
            PrevBuffer."Generated Item Description") > 100
        then
            AddError(
                ValidationMessage,
                IsValid,
                StrSubstNo(
                    ItemDescriptionTooLongErr,
                    StrLen(
                        PrevBuffer."Generated Item Description"),
                    100));
    end;

    local procedure ValidateVariantCode(
        PrevBuffer: Record "SI ERP Projection Prev Buffer" temporary;
        var ValidationMessage: Text;
        var IsValid: Boolean)
    begin
        if PrevBuffer."Generated Variant Code" = '' then begin
            AddError(
                ValidationMessage,
                IsValid,
                VariantCodeRequiredErr);
            exit;
        end;

        if StrLen(
            PrevBuffer."Generated Variant Code") > 10
        then
            AddError(
                ValidationMessage,
                IsValid,
                StrSubstNo(
                    VariantCodeTooLongErr,
                    StrLen(
                        PrevBuffer."Generated Variant Code"),
                    10));
    end;

    local procedure ValidateVariantDesc(
        PrevBuffer: Record "SI ERP Projection Prev Buffer" temporary;
        var ValidationMessage: Text;
        var IsValid: Boolean)
    begin
        if PrevBuffer."Generated Variant Description" = '' then begin
            AddError(
                ValidationMessage,
                IsValid,
                VariantDescRequiredErr);
            exit;
        end;

        if StrLen(
            PrevBuffer."Generated Variant Description") > 100
        then
            AddError(
                ValidationMessage,
                IsValid,
                StrSubstNo(
                    VariantDescTooLongErr,
                    StrLen(
                        PrevBuffer."Generated Variant Description"),
                    100));
    end;

    local procedure ValidateKeyCollision(
        PrevBuffer: Record "SI ERP Projection Prev Buffer" temporary;
        var ValidationMessage: Text;
        var IsValid: Boolean)
    var
        ItemProjection: Record "SI Item ERP Projection";
    begin
        if PrevBuffer."Family Code" = '' then
            exit;

        if PrevBuffer."Item Projection Key Hash" = '' then
            exit;

        ItemProjection.SetRange(
            "Family Code",
            PrevBuffer."Family Code");

        ItemProjection.SetRange(
            "Item Projection Key Hash",
            PrevBuffer."Item Projection Key Hash");

        if not ItemProjection.FindFirst() then
            exit;

        if ItemProjection."Item Projection Key" =
           PrevBuffer."Item Projection Key"
        then
            exit;

        AddError(
            ValidationMessage,
            IsValid,
            StrSubstNo(
                ItemKeyCollisionErr,
                PrevBuffer."Family Code",
                PrevBuffer."Item Projection Key Hash",
                ItemProjection."Entry No."));
    end;

    local procedure AddError(
        var ValidationMessage: Text;
        var IsValid: Boolean;
        ErrorText: Text)
    begin
        IsValid := false;

        if ErrorText = '' then
            exit;

        if ValidationMessage <> '' then
            ValidationMessage += ' | ';

        ValidationMessage += ErrorText;
    end;

    var
        ReadyMsg: Label
            'ERP-проєкція готова до матеріалізації.';

        ConfigNoRequiredErr: Label
            'Не вказано номер конфігурації.';

        ConfigNotFoundErr: Label
            'Конфігурацію %1 не знайдено.';

        ConfigBlockedErr: Label
            'Конфігурацію %1 заблоковано.';

        ConfigArchivedErr: Label
            'Конфігурація %1 перебуває в архіві.';

        ConfigFamilyRequiredErr: Label
            'У конфігурації %1 не вказано сімейство.';

        ConfigFamilyMismatchErr: Label
            'Конфігурація %1 належить сімейству %2, але в буфері зазначено сімейство %3.';

        FamilyCodeRequiredErr: Label
            'Не визначено сімейство продукту.';

        FamilyNotFoundErr: Label
            'Сімейство %1 не знайдено.';

        FamilyBlockedErr: Label
            'Сімейство %1 заблоковано.';

        FamilyCategoryRequiredErr: Label
            'Для сімейства %1 не вказано категорію товару.';

        FamilyCategoryMismatchErr: Label
            'Для сімейства %1 визначено категорію %2, але в буфері зазначено категорію %3.';

        FamilyTemplateMismatchErr: Label
            'Для сімейства %1 визначено шаблон %2, але в буфері зазначено шаблон %3.';

        CategoryRequiredErr: Label
            'Не визначено категорію товару.';

        CategoryNotFoundErr: Label
            'Категорію товару %1 не знайдено.';

        CategoryNotLeafErr: Label
            'Категорія товару %1 має дочірні категорії та не є кінцевим листком.';

        TemplateRequiredErr: Label
            'Для створення нового товару не знайдено шаблон товару: його не задано в сімействі й не знайдено серед стандартних шаблонів для категорії. Створіть або налаштуйте Item Template.';

        TemplateNotFoundErr: Label
            'Шаблон товару %1 не знайдено.';

        BaseUoMRequiredErr: Label
            'Не визначено базову одиницю виміру.';

        BaseUoMNotFoundErr: Label
            'Базову одиницю виміру %1 не знайдено.';

        BaseUoMSourceRequiredErr: Label
            'Не визначено джерело базової одиниці виміру.';

        ItemKeyRequiredErr: Label
            'Не сформовано ключ проєкції товару.';

        ItemHashRequiredErr: Label
            'Не сформовано hash ключа проєкції товару.';

        ItemHashTooLongErr: Label
            'Hash ключа проєкції товару має %1 символів; дозволено не більше %2.';

        IdentityRoleMissingErr: Label
            'Для сімейства %1 не налаштовано параметрів із роллю Item Identity або Variant Identity.';

        BaseItemRequiredErr: Label
            'Сімейство %1 визначає тільки варіант. Для конфігурації не вибрано базовий товар.';

        VariantRoleMissingErr: Label
            'Для сімейства %1 не налаштовано параметрів із ERP-роллю Variant.';

        UnexpectedVariantPresentationErr: Label
            'Для сімейства без Variant Identity не повинні формуватися код або назва варіанта.';

        ItemCodeRequiredErr: Label
            'Не сформовано код товару.';

        ItemCodeTooLongErr: Label
            'Згенерований код товару має %1 символів; дозволено не більше %2.';

        ItemDescriptionRequiredErr: Label
            'Не сформовано назву товару.';

        ItemDescriptionTooLongErr: Label
            'Згенерована назва товару має %1 символів; дозволено не більше %2.';

        VariantCodeRequiredErr: Label
            'Не сформовано код варіанта товару.';

        VariantCodeTooLongErr: Label
            'Згенерований код варіанта має %1 символів; дозволено не більше %2.';

        VariantDescRequiredErr: Label
            'Не сформовано назву варіанта товару.';

        VariantDescTooLongErr: Label
            'Згенерована назва варіанта має %1 символів; дозволено не більше %2.';

        ItemKeyCollisionErr: Label
            'Виявлено колізію hash для сімейства %1. Hash %2 вже використано записом проєкції %3 з іншим ключем.';
}