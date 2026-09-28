namespace STROYINVEST.ConcreteRecipeEngine;

using Microsoft.Inventory.Item;

codeunit 62200 "SI Recipe Creation Mgt."
{
    procedure GetOrCreateDraftRevision(ItemNo: Code[20]; VariantCode: Code[10]; var RecipeRevision: Record "SI Concrete Recipe Revision")
    var
        Recipe: Record "SI Concrete Recipe";
    begin
        ResolveOrCreateRecipe(ItemNo, VariantCode, Recipe);

        RecipeRevision.Reset();
        RecipeRevision.SetRange("Recipe No.", Recipe."Recipe No.");
        RecipeRevision.SetRange(Status, RecipeRevision.Status::Draft);
        if RecipeRevision.FindLast() then
            exit;

        RecipeRevision.Init();
        RecipeRevision.Validate("Recipe No.", Recipe."Recipe No.");
        RecipeRevision.Insert(true);
    end;

    procedure GetOrCreateDraftRevisionForRecipe(RecipeNo: Code[50]; var RecipeRevision: Record "SI Concrete Recipe Revision")
    var
        Recipe: Record "SI Concrete Recipe";
    begin
        Recipe.Get(RecipeNo);
        GetOrCreateDraftRevision(Recipe."Item No.", Recipe."Variant Code", RecipeRevision);
    end;

    procedure GetConcreteRootCategoryCode(): Code[20]
    var
        RecipeSetup: Record "SI Concrete Recipe Setup";
        ItemCategory: Record "Item Category";
        RootCategoryCode: Code[20];
    begin
        EnsureSetup(RecipeSetup);

        if RecipeSetup."Concrete Root Category Code" <> '' then begin
            ItemCategory.Get(RecipeSetup."Concrete Root Category Code");
            exit(RecipeSetup."Concrete Root Category Code");
        end;

        RootCategoryCode := CopyStr(DefaultConcreteCategoryTxt, 1, MaxStrLen(RootCategoryCode));
        if ItemCategory.Get(RootCategoryCode) then begin
            RecipeSetup."Concrete Root Category Code" := ItemCategory.Code;
            RecipeSetup.Modify(true);
            exit(ItemCategory.Code);
        end;

        ItemCategory.Reset();
        ItemCategory.SetFilter(Description, '@%1', DefaultConcreteCategoryTxt);
        if ItemCategory.FindFirst() then begin
            RootCategoryCode := ItemCategory.Code;
            if ItemCategory.Next() <> 0 then
                Error(ConcreteRootCategoryAmbiguousErr, DefaultConcreteCategoryTxt);

            RecipeSetup."Concrete Root Category Code" := RootCategoryCode;
            RecipeSetup.Modify(true);
            exit(RootCategoryCode);
        end;

        Error(ConcreteRootCategoryMissingErr, DefaultConcreteCategoryTxt);
    end;

    procedure BuildRecipeNo(ItemNo: Code[20]; VariantCode: Code[10]): Code[50]
    var
        RecipeNoText: Text;
        RecipeNo: Code[50];
    begin
        if VariantCode = '' then
            RecipeNoText := ItemNo
        else
            RecipeNoText := StrSubstNo('%1|%2', ItemNo, VariantCode);

        if StrLen(RecipeNoText) > MaxStrLen(RecipeNo) then
            Error(RecipeKeyTooLongErr, RecipeNoText, MaxStrLen(RecipeNo));

        exit(CopyStr(RecipeNoText, 1, MaxStrLen(RecipeNo)));
    end;

    local procedure ResolveOrCreateRecipe(ItemNo: Code[20]; VariantCode: Code[10]; var Recipe: Record "SI Concrete Recipe")
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ItemCategory: Record "Item Category";
        ParentRecipe: Record "SI Concrete Recipe";
        ExpectedRecipeNo: Code[50];
    begin
        Item.Get(ItemNo);
        Item.TestField("Item Category Code");

        ItemCategory.Get(Item."Item Category Code");
        ItemCategory.TestField("SI Default Base UoM Code");

        Recipe.Reset();
        Recipe.SetRange("Item No.", ItemNo);
        Recipe.SetRange("Variant Code", VariantCode);
        if Recipe.FindFirst() then
            exit;

        ExpectedRecipeNo := BuildRecipeNo(ItemNo, VariantCode);

        if Recipe.Get(ExpectedRecipeNo) then begin
            if (Recipe."Item No." <> ItemNo) or (Recipe."Variant Code" <> VariantCode) then
                Error(RecipeKeyCollisionErr, ExpectedRecipeNo);
            exit;
        end;

        Recipe.Init();
        Recipe."Recipe No." := ExpectedRecipeNo;
        Recipe.Validate("Item No.", ItemNo);
        Recipe.Validate("Subcategory Code", Item."Item Category Code");
        Recipe.Validate("Output Quantity", 1);
        Recipe.Validate("Output UoM Code", ItemCategory."SI Default Base UoM Code");
        Recipe.Active := true;

        if VariantCode = '' then begin
            Recipe.Validate("Recipe Type", Recipe."Recipe Type"::Base);
            Recipe.Description := Item.Description;
        end else begin
            ItemVariant.Get(ItemNo, VariantCode);

            ParentRecipe.Reset();
            ParentRecipe.SetRange("Item No.", ItemNo);
            ParentRecipe.SetRange("Variant Code", '');
            ParentRecipe.SetRange("Recipe Type", ParentRecipe."Recipe Type"::Base);
            if not ParentRecipe.FindFirst() then
                Error(BaseRecipeMissingErr, GetItemDisplayName(Item));

            Recipe.Validate("Recipe Type", Recipe."Recipe Type"::Variant);
            Recipe.Validate("Variant Code", VariantCode);
            Recipe.Validate("Parent Recipe No.", ParentRecipe."Recipe No.");
            Recipe.Description := GetVariantDisplayName(Item, ItemVariant);
        end;

        Recipe.Insert(true);
    end;

    local procedure EnsureSetup(var RecipeSetup: Record "SI Concrete Recipe Setup")
    begin
        if RecipeSetup.Get('') then
            exit;

        RecipeSetup.Init();
        RecipeSetup."Primary Key" := '';
        RecipeSetup.Insert(true);
    end;

    local procedure GetItemDisplayName(Item: Record Item): Text
    begin
        if Item.Description <> '' then
            exit(Item.Description);

        exit(Item."No.");
    end;

    local procedure GetVariantDisplayName(Item: Record Item; ItemVariant: Record "Item Variant"): Text
    begin
        if ItemVariant.Description <> '' then
            exit(ItemVariant.Description);

        exit(StrSubstNo('%1 %2', GetItemDisplayName(Item), ItemVariant.Code));
    end;

    var
        DefaultConcreteCategoryTxt: Label 'БЕТОН', Locked = true;
        ConcreteRootCategoryMissingErr: Label 'Кореневу категорію бетону "%1" не знайдено. Вкажіть кореневу категорію бетону в налаштуваннях рецептур.';
        ConcreteRootCategoryAmbiguousErr: Label 'Існує кілька категорій товарів з описом "%1". У налаштуваннях рецептур бетону вкажіть кореневу категорію бетону.';
        BaseRecipeMissingErr: Label 'Базовий продукт "%1" не має рецептури. Спочатку створіть рецептуру базового продукту.';
        RecipeKeyCollisionErr: Label 'Ключ рецептури %1 уже використовується іншим продуктом.';
        RecipeKeyTooLongErr: Label 'Згенерований ключ рецептури "%1" перевищує дозволену довжину %2 символів.';
}
