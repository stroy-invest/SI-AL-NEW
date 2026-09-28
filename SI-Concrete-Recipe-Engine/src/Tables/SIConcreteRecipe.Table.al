namespace STROYINVEST.ConcreteRecipeEngine;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.ProductionBOM;

table 62020 "SI Concrete Recipe"
{
    Caption = 'Рецептура бетону';
    DataClassification = CustomerContent;
    DataCaptionFields = "Recipe No.", Description;
    LookupPageId = "SI Concrete Recipes";
    DrillDownPageId = "SI Concrete Recipes";

    fields
    {
        field(1; "Recipe No."; Code[50])
        {
            Caption = 'Код рецептури';
            NotBlank = true;
            ToolTip = 'Вказує стабільний технічний ключ рецептури, сформований із кодів товару та варіанта.';
        }
        field(2; Description; Text[100])
        {
            Caption = 'Опис';
            ToolTip = 'Вказує відображувану назву продукту, що використовується як опис рецептури.';
        }
        field(10; "Recipe Type"; Enum "SI Recipe Type")
        {
            Caption = 'Тип рецептури';
            ToolTip = 'Вказує, чи є рецептура базовою або рецептурою варіанта.';

            trigger OnValidate()
            begin
                if "Recipe Type" = "Recipe Type"::Base then
                    Validate("Variant Code", '');
            end;
        }
        field(20; "Item No."; Code[20])
        {
            Caption = 'Код товару';
            TableRelation = Item."No.";
            ToolTip = 'Вказує готовий товар, що виробляється за цією рецептурою.';

            trigger OnValidate()
            var
                Item: Record Item;
            begin
                if "Item No." = xRec."Item No." then
                    exit;

                "Variant Code" := '';

                if "Item No." = '' then
                    exit;

                Item.Get("Item No.");

                if "Subcategory Code" = '' then begin
                    Item.TestField("Item Category Code");
                    Validate("Subcategory Code", Item."Item Category Code");
                end else
                    if Item."Item Category Code" <> "Subcategory Code" then
                        Error(ItemCategoryMismatchErr, Item."No.", Item."Item Category Code", "Subcategory Code");
            end;
        }
        field(21; "Variant Code"; Code[10])
        {
            Caption = 'Код варіанта';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
            ToolTip = 'Вказує варіант готового товару. Для базової рецептури поле має бути порожнім.';

            trigger OnValidate()
            begin
                if ("Recipe Type" = "Recipe Type"::Base) and ("Variant Code" <> '') then
                    Error(BaseRecipeVariantErr);
            end;
        }
        field(22; "Subcategory Code"; Code[20])
        {
            Caption = 'Код підкатегорії';
            TableRelation = "Item Category".Code;
            ToolTip = 'Вказує сімейство/підкатегорію продукту, представлену категорією товару Business Central.';

            trigger OnValidate()
            var
                ItemCategory: Record "Item Category";
                Item: Record Item;
            begin
                if "Subcategory Code" = '' then begin
                    "Output UoM Code" := '';
                    exit;
                end;

                ItemCategory.Get("Subcategory Code");
                ItemCategory.TestField("SI Default Base UoM Code");
                "Output UoM Code" := ItemCategory."SI Default Base UoM Code";

                if "Item No." <> '' then begin
                    Item.Get("Item No.");
                    if Item."Item Category Code" <> "Subcategory Code" then
                        Error(ItemCategoryMismatchErr, Item."No.", Item."Item Category Code", "Subcategory Code");
                end;
            end;
        }
        field(23; "Parent Recipe No."; Code[50])
        {
            Caption = 'Код батьківської рецептури';
            TableRelation = "SI Concrete Recipe"."Recipe No.";
            ToolTip = 'Вказує базову рецептуру батьківського товару для рецептури варіанта.';

            trigger OnValidate()
            var
                ParentRecipe: Record "SI Concrete Recipe";
            begin
                if "Parent Recipe No." = '' then
                    exit;
                if "Parent Recipe No." = "Recipe No." then
                    Error(RecipeCannotBeOwnParentErr);
                ParentRecipe.Get("Parent Recipe No.");
                if ParentRecipe."Recipe Type" <> ParentRecipe."Recipe Type"::Base then
                    Error(ParentMustBeBaseErr, "Parent Recipe No.");
            end;
        }
        field(30; "Output Quantity"; Decimal)
        {
            Caption = 'Вихідна кількість';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            ToolTip = 'Вказує базову вихідну кількість рецептури, до якої відносяться кількості всіх її рядків.';

            trigger OnValidate()
            begin
                if "Output Quantity" <= 0 then
                    Error(OutputQuantityPositiveErr);
            end;
        }
        field(31; "Output UoM Code"; Code[10])
        {
            Caption = 'Одиниця виміру виходу';
            TableRelation = "Unit of Measure".Code;
            ToolTip = 'Вказує одиницю виміру виходу, успадковану від вибраної підкатегорії продукту.';
        }
        field(40; "Production BOM No."; Code[20])
        {
            Caption = 'Код виробничої специфікації';
            TableRelation = "Production BOM Header"."No.";
            ToolTip = 'Вказує стандартну виробничу специфікацію Business Central, що використовується як ERP-проєкція цієї рецептури.';
        }
        field(50; Active; Boolean)
        {
            Caption = 'Активна';
            InitValue = true;
            ToolTip = 'Вказує, чи є ця рецептура активними майстер-даними.';
        }
    }

    keys
    {
        key(PK; "Recipe No.")
        {
            Clustered = true;
        }
        key(ItemVariant; "Item No.", "Variant Code")
        {
            Unique = true;
        }
        key(SubcategoryItemVariant; "Subcategory Code", "Item No.", "Variant Code")
        {
        }
        key(ParentRecipe; "Parent Recipe No.")
        {
        }
    }

    trigger OnInsert()
    begin
        TestField("Recipe No.");
        TestField("Item No.");
        TestField("Subcategory Code");

        if "Output Quantity" = 0 then
            "Output Quantity" := 1;

        TestField("Output UoM Code");

        if ("Recipe Type" = "Recipe Type"::Base) and ("Variant Code" <> '') then
            Error(BaseRecipeVariantErr);

        if ("Recipe Type" = "Recipe Type"::Variant) then begin
            TestField("Variant Code");
            TestField("Parent Recipe No.");
        end;
    end;

    trigger OnDelete()
    var
        RecipeRevision: Record "SI Concrete Recipe Revision";
    begin
        RecipeRevision.SetRange("Recipe No.", "Recipe No.");
        RecipeRevision.SetFilter(Status, '<>%1', RecipeRevision.Status::Draft);
        if not RecipeRevision.IsEmpty() then
            Error(RecipeWithControlledRevisionsDeleteErr, "Recipe No.");
    end;

    trigger OnModify()
    begin
        ValidateIdentityChanges();
    end;

    local procedure ValidateIdentityChanges()
    var
        RecipeRevision: Record "SI Concrete Recipe Revision";
    begin
        if ("Recipe Type" = xRec."Recipe Type") and
           ("Item No." = xRec."Item No.") and
           ("Variant Code" = xRec."Variant Code") and
           ("Subcategory Code" = xRec."Subcategory Code") and
           ("Parent Recipe No." = xRec."Parent Recipe No.") and
           (Description = xRec.Description) and
           ("Output Quantity" = xRec."Output Quantity") and
           ("Output UoM Code" = xRec."Output UoM Code")
        then
            exit;

        RecipeRevision.SetRange("Recipe No.", "Recipe No.");
        RecipeRevision.SetFilter(Status, '<>%1', RecipeRevision.Status::Draft);
        if not RecipeRevision.IsEmpty() then
            Error(RecipeIdentityLockedErr);
    end;

    var
        BaseRecipeVariantErr: Label 'Для базової рецептури код варіанта має бути порожнім.';
        RecipeCannotBeOwnParentErr: Label 'Рецептура не може бути батьківською сама для себе.';
        ParentMustBeBaseErr: Label 'Батьківська рецептура %1 має бути базовою.';
        OutputQuantityPositiveErr: Label 'Вихідна кількість має бути більшою за нуль.';
        RecipeWithControlledRevisionsDeleteErr: Label 'Рецептуру %1 не можна видалити, оскільки вона містить сертифіковані або неактивні ревізії.';
        RecipeIdentityLockedErr: Label 'Ідентичність рецептури та базис виходу не можна змінювати після появи сертифікованої ревізії.';
        ItemCategoryMismatchErr: Label 'Товар %1 належить до категорії %2 і не може використовуватися з підкатегорією %3.';
}
