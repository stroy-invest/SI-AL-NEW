namespace STROYINVEST.ConcreteRecipeEngine;

using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.ProductionBOM;

codeunit 62204 "SI Recipe BOM Projection"
{
    Permissions =
        tabledata "Production BOM Header" = RIMD,
        tabledata "Production BOM Version" = RIMD,
        tabledata "Production BOM Line" = RIMD,
        tabledata Item = RM,
        tabledata "Item Variant" = RM;

    procedure ProjectRevision(var RecipeRevision: Record "SI Concrete Recipe Revision")
    var
        Recipe: Record "SI Concrete Recipe";
        ProdBOMHeader: Record "Production BOM Header";
        ProdBOMVersion: Record "Production BOM Version";
        VersionCode: Code[20];
        ExpectedLineCount: Integer;
    begin
        RecipeRevision.Get(RecipeRevision."Recipe No.", RecipeRevision."Revision No.");
        RecipeRevision.TestField(Status, RecipeRevision.Status::Certified);

        Recipe.Get(RecipeRevision."Recipe No.");
        Recipe.TestField("Item No.");
        Recipe.TestField("Output UoM Code");
        if Recipe."Output Quantity" <= 0 then
            Error(OutputQuantityErr, Recipe."Recipe No.");

        ExpectedLineCount := ValidateRecipeLines(RecipeRevision);

        EnsureProductionBOMHeader(Recipe, ProdBOMHeader);
        EnsureProductBOMLink(Recipe, ProdBOMHeader."No.");

        VersionCode := BuildVersionCode(RecipeRevision."Revision No.");
        RecipeRevision.SetProjectionState(
            RecipeRevision."Projection Status"::Pending,
            VersionCode,
            '');

        if ProdBOMVersion.Get(ProdBOMHeader."No.", VersionCode) then begin
            if ProjectionMatchesSource(
                Recipe,
                RecipeRevision,
                ProdBOMHeader."No.",
                VersionCode,
                ExpectedLineCount)
            then begin
                if ProdBOMVersion.Status <> ProdBOMVersion.Status::Certified then
                    ProdBOMVersion.Validate(Status, ProdBOMVersion.Status::Certified);

                RecipeRevision.Get(RecipeRevision."Recipe No.", RecipeRevision."Revision No.");
                RecipeRevision.SetProjectionState(
                    RecipeRevision."Projection Status"::Projected,
                    VersionCode,
                    '');

                Message(
                    ProjectionSuccessMsg,
                    ProdBOMHeader."No.",
                    VersionCode,
                    ExpectedLineCount);

                OnAfterRecipeRevisionProjected(
                    Recipe,
                    RecipeRevision,
                    ProdBOMHeader,
                    ProdBOMVersion);
                exit;
            end;

            PrepareExistingVersionForRebuild(ProdBOMVersion);
            DeleteVersionLines(ProdBOMHeader."No.", VersionCode);
            UpdateProductionBOMVersion(
                Recipe,
                RecipeRevision,
                ProdBOMVersion);
        end else
            CreateProductionBOMVersion(
                Recipe,
                RecipeRevision,
                ProdBOMHeader,
                ProdBOMVersion,
                VersionCode);

        CreateProductionBOMLines(
            Recipe,
            RecipeRevision,
            ProdBOMHeader."No.",
            VersionCode);

        // Hard invariant: never certify/mark Projected unless the ERP projection
        // contains exactly the source recipe lines with the expected values.
        ValidateProjectedLines(
            Recipe,
            RecipeRevision,
            ProdBOMHeader."No.",
            VersionCode,
            ExpectedLineCount);

        // Standard BC may COMMIT inside Status.OnValidate().
        // Therefore all projection validation must happen before this call.
        ProdBOMVersion.Get(ProdBOMHeader."No.", VersionCode);
        ProdBOMVersion.Validate(Status, ProdBOMVersion.Status::Certified);

        RecipeRevision.Get(RecipeRevision."Recipe No.", RecipeRevision."Revision No.");
        RecipeRevision.SetProjectionState(
            RecipeRevision."Projection Status"::Projected,
            VersionCode,
            '');

        Message(
            ProjectionSuccessMsg,
            ProdBOMHeader."No.",
            VersionCode,
            ExpectedLineCount);

        OnAfterRecipeRevisionProjected(
            Recipe,
            RecipeRevision,
            ProdBOMHeader,
            ProdBOMVersion);
    end;

    procedure BuildVersionCode(RevisionNo: Integer): Code[20]
    var
        VersionCode: Code[20];
    begin
        if RevisionNo <= 0 then
            Error(InvalidRevisionNoErr, RevisionNo);

        VersionCode := CopyStr(StrSubstNo('REV-%1', RevisionNo), 1, MaxStrLen(VersionCode));
        exit(VersionCode);
    end;

    local procedure EnsureProductionBOMHeader(
        var Recipe: Record "SI Concrete Recipe";
        var ProdBOMHeader: Record "Production BOM Header")
    begin
        if Recipe."Production BOM No." <> '' then begin
            ProdBOMHeader.Get(Recipe."Production BOM No.");
            ValidateExistingHeader(Recipe, ProdBOMHeader);
            exit;
        end;

        ProdBOMHeader.Init();
        ProdBOMHeader.Insert(true);
        ProdBOMHeader.Validate(Description, Recipe.Description);
        ProdBOMHeader.Validate("Unit of Measure Code", Recipe."Output UoM Code");
        ProdBOMHeader.Modify(true);

        Recipe."Production BOM No." := ProdBOMHeader."No.";
        Recipe.Modify(true);
    end;

    local procedure ValidateExistingHeader(
        Recipe: Record "SI Concrete Recipe";
        ProdBOMHeader: Record "Production BOM Header")
    begin
        if ProdBOMHeader."Unit of Measure Code" <> Recipe."Output UoM Code" then
            Error(
                BOMUoMMismatchErr,
                ProdBOMHeader."No.",
                ProdBOMHeader."Unit of Measure Code",
                Recipe."Output UoM Code");
    end;

    local procedure EnsureProductBOMLink(
        Recipe: Record "SI Concrete Recipe";
        ProductionBOMNo: Code[20])
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
    begin
        Item.Get(Recipe."Item No.");

        if Recipe."Recipe Type" = Recipe."Recipe Type"::Base then begin
            if (Item."Production BOM No." <> '') and
               (Item."Production BOM No." <> ProductionBOMNo)
            then
                Error(
                    ItemBOMConflictErr,
                    Item."No.",
                    Item."Production BOM No.",
                    ProductionBOMNo);

            if Item."Production BOM No." <> ProductionBOMNo then begin
                Item.Validate("Production BOM No.", ProductionBOMNo);
                Item.Modify(true);
            end;

            exit;
        end;

        Recipe.TestField("Variant Code");
        ItemVariant.Get(Recipe."Item No.", Recipe."Variant Code");

        if (ItemVariant."SI Production BOM No." <> '') and
           (ItemVariant."SI Production BOM No." <> ProductionBOMNo)
        then
            Error(
                VariantBOMConflictErr,
                ItemVariant.Code,
                ItemVariant."Item No.",
                ItemVariant."SI Production BOM No.",
                ProductionBOMNo);

        if ItemVariant."SI Production BOM No." <> ProductionBOMNo then begin
            ItemVariant."SI Production BOM No." := ProductionBOMNo;
            ItemVariant.Modify(true);
        end;
    end;

    local procedure CreateProductionBOMVersion(
        Recipe: Record "SI Concrete Recipe";
        RecipeRevision: Record "SI Concrete Recipe Revision";
        ProdBOMHeader: Record "Production BOM Header";
        var ProdBOMVersion: Record "Production BOM Version";
        VersionCode: Code[20])
    begin
        ProdBOMVersion.Init();
        ProdBOMVersion."Production BOM No." := ProdBOMHeader."No.";
        ProdBOMVersion."Version Code" := VersionCode;
        ProdBOMVersion.Description :=
            CopyStr(
                StrSubstNo('%1 / Rev. %2', Recipe.Description, RecipeRevision."Revision No."),
                1,
                MaxStrLen(ProdBOMVersion.Description));
        ProdBOMVersion."Starting Date" := RecipeRevision."Valid From";
        ProdBOMVersion.Validate("Unit of Measure Code", Recipe."Output UoM Code");
        ProdBOMVersion.Status := ProdBOMVersion.Status::New;
        ProdBOMVersion.Insert(true);
    end;

    local procedure CreateProductionBOMLines(
        Recipe: Record "SI Concrete Recipe";
        RecipeRevision: Record "SI Concrete Recipe Revision";
        ProductionBOMNo: Code[20];
        VersionCode: Code[20])
    var
        RecipeLine: Record "SI Concrete Recipe Line";
        ProdBOMLine: Record "Production BOM Line";
        QuantityPer: Decimal;
    begin
        RecipeLine.SetRange("Recipe No.", RecipeRevision."Recipe No.");
        RecipeLine.SetRange("Revision No.", RecipeRevision."Revision No.");
        RecipeLine.SetCurrentKey("Recipe No.", "Revision No.", "Line No.");

        if not RecipeLine.FindSet() then
            Error(NoRecipeLinesErr, RecipeRevision."Recipe No.", RecipeRevision."Revision No.");

        repeat
            QuantityPer := RecipeLine.Quantity / Recipe."Output Quantity";

            ProdBOMLine.Init();
            ProdBOMLine."Production BOM No." := ProductionBOMNo;
            ProdBOMLine."Version Code" := VersionCode;
            ProdBOMLine."Line No." := RecipeLine."Line No.";
            ProdBOMLine.Validate(Type, ProdBOMLine.Type::Item);
            ProdBOMLine.Validate("No.", RecipeLine."Item No.");

            if RecipeLine."Variant Code" <> '' then
                ProdBOMLine.Validate("Variant Code", RecipeLine."Variant Code");

            if RecipeLine."Unit of Measure Code" <> '' then
                ProdBOMLine.Validate("Unit of Measure Code", RecipeLine."Unit of Measure Code");

            ProdBOMLine.Validate("Quantity per", QuantityPer);
            ProdBOMLine.Validate("Starting Date", RecipeRevision."Valid From");
            ProdBOMLine.Validate("Ending Date", RecipeRevision."Valid To");
            ProdBOMLine.Insert(true);
        until RecipeLine.Next() = 0;
    end;

    local procedure PrepareExistingVersionForRebuild(var ProdBOMVersion: Record "Production BOM Version")
    begin
        if ProdBOMVersion.Status = ProdBOMVersion.Status::Certified then
            ProdBOMVersion.Validate(Status, ProdBOMVersion.Status::"Under Development");

        ProdBOMVersion.Get(
            ProdBOMVersion."Production BOM No.",
            ProdBOMVersion."Version Code");
    end;

    local procedure UpdateProductionBOMVersion(
        Recipe: Record "SI Concrete Recipe";
        RecipeRevision: Record "SI Concrete Recipe Revision";
        var ProdBOMVersion: Record "Production BOM Version")
    begin
        ProdBOMVersion.Description :=
            CopyStr(
                StrSubstNo('%1 / Rev. %2', Recipe.Description, RecipeRevision."Revision No."),
                1,
                MaxStrLen(ProdBOMVersion.Description));
        ProdBOMVersion."Starting Date" := RecipeRevision."Valid From";
        ProdBOMVersion.Validate("Unit of Measure Code", Recipe."Output UoM Code");
        ProdBOMVersion.Modify(true);
    end;

    local procedure ProjectionMatchesSource(
        Recipe: Record "SI Concrete Recipe";
        RecipeRevision: Record "SI Concrete Recipe Revision";
        ProductionBOMNo: Code[20];
        VersionCode: Code[20];
        ExpectedLineCount: Integer): Boolean
    var
        RecipeLine: Record "SI Concrete Recipe Line";
        ProdBOMLine: Record "Production BOM Line";
        ActualLineCount: Integer;
        ExpectedQuantityPer: Decimal;
    begin
        ProdBOMLine.SetRange("Production BOM No.", ProductionBOMNo);
        ProdBOMLine.SetRange("Version Code", VersionCode);
        ActualLineCount := ProdBOMLine.Count();

        if ActualLineCount <> ExpectedLineCount then
            exit(false);

        RecipeLine.SetRange("Recipe No.", RecipeRevision."Recipe No.");
        RecipeLine.SetRange("Revision No.", RecipeRevision."Revision No.");
        if not RecipeLine.FindSet() then
            exit(false);

        repeat
            if not ProdBOMLine.Get(
                ProductionBOMNo,
                VersionCode,
                RecipeLine."Line No.")
            then
                exit(false);

            ExpectedQuantityPer := RecipeLine.Quantity / Recipe."Output Quantity";

            if ProdBOMLine.Type <> ProdBOMLine.Type::Item then
                exit(false);
            if ProdBOMLine."No." <> RecipeLine."Item No." then
                exit(false);
            if ProdBOMLine."Variant Code" <> RecipeLine."Variant Code" then
                exit(false);
            if ProdBOMLine."Unit of Measure Code" <> RecipeLine."Unit of Measure Code" then
                exit(false);
            if ProdBOMLine."Quantity per" <> ExpectedQuantityPer then
                exit(false);
            if ProdBOMLine."Starting Date" <> RecipeRevision."Valid From" then
                exit(false);
            if ProdBOMLine."Ending Date" <> RecipeRevision."Valid To" then
                exit(false);
        until RecipeLine.Next() = 0;

        exit(true);
    end;

    local procedure ValidateProjectedLines(
        Recipe: Record "SI Concrete Recipe";
        RecipeRevision: Record "SI Concrete Recipe Revision";
        ProductionBOMNo: Code[20];
        VersionCode: Code[20];
        ExpectedLineCount: Integer)
    var
        ProdBOMLine: Record "Production BOM Line";
        ActualLineCount: Integer;
    begin
        ProdBOMLine.SetRange("Production BOM No.", ProductionBOMNo);
        ProdBOMLine.SetRange("Version Code", VersionCode);
        ActualLineCount := ProdBOMLine.Count();

        if ActualLineCount <> ExpectedLineCount then
            Error(
                ProjectionLineCountErr,
                ProductionBOMNo,
                VersionCode,
                ExpectedLineCount,
                ActualLineCount);

        if not ProjectionMatchesSource(
            Recipe,
            RecipeRevision,
            ProductionBOMNo,
            VersionCode,
            ExpectedLineCount)
        then
            Error(
                ProjectionContentErr,
                ProductionBOMNo,
                VersionCode);
    end;

    local procedure DeleteVersionLines(ProductionBOMNo: Code[20]; VersionCode: Code[20])
    var
        ProdBOMLine: Record "Production BOM Line";
    begin
        ProdBOMLine.SetRange("Production BOM No.", ProductionBOMNo);
        ProdBOMLine.SetRange("Version Code", VersionCode);
        if not ProdBOMLine.IsEmpty() then
            ProdBOMLine.DeleteAll(true);
    end;

    local procedure ValidateRecipeLines(RecipeRevision: Record "SI Concrete Recipe Revision"): Integer
    var
        RecipeLine: Record "SI Concrete Recipe Line";
        LineCount: Integer;
    begin
        RecipeLine.SetRange("Recipe No.", RecipeRevision."Recipe No.");
        RecipeLine.SetRange("Revision No.", RecipeRevision."Revision No.");

        if not RecipeLine.FindSet() then
            Error(NoRecipeLinesErr, RecipeRevision."Recipe No.", RecipeRevision."Revision No.");

        repeat
            RecipeLine.TestField("Item No.");
            RecipeLine.TestField("Unit of Measure Code");
            if RecipeLine.Quantity <= 0 then
                Error(LineQuantityErr, RecipeLine."Line No.");
            LineCount += 1;
        until RecipeLine.Next() = 0;

        exit(LineCount);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRecipeRevisionProjected(
        Recipe: Record "SI Concrete Recipe";
        RecipeRevision: Record "SI Concrete Recipe Revision";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMVersion: Record "Production BOM Version")
    begin
    end;

    var
        OutputQuantityErr: Label 'Рецептура %1 має некоректну вихідну кількість. Значення має бути більшим за нуль.';
        InvalidRevisionNoErr: Label '№ ревізії %1 некоректний.';
        BOMUoMMismatchErr: Label 'Виробнича специфікація %1 використовує одиницю виміру %2, але рецептура вимагає %3.';
        ItemBOMConflictErr: Label 'Товар %1 уже використовує виробничу специфікацію %2. Recipe Engine не може автоматично замінити її на %3.';
        VariantBOMConflictErr: Label 'Варіант %1 товару %2 уже використовує виробничу специфікацію SI %3. Recipe Engine не може автоматично замінити її на %4.';
        NoRecipeLinesErr: Label 'Рецептура %1, ревізія %2, не містить рядків для проєкції.';
        LineQuantityErr: Label 'Рядок рецептури %1 повинен мати кількість більшу за нуль.';
        ProjectionLineCountErr: Label 'Версію %2 виробничої специфікації %1 спроєктовано некоректно. Очікувалося рядків компонентів: %3, знайдено: %4. Проєкцію не позначено завершеною.';
        ProjectionContentErr: Label 'Версія %2 виробничої специфікації %1 не відповідає сертифікованій ревізії рецептури. Проєкцію не позначено завершеною.';
        ProjectionSuccessMsg: Label 'Виробничу специфікацію %1, версію %2, успішно спроєктовано. Рядків компонентів: %3.';
}
