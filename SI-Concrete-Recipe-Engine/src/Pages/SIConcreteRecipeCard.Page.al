namespace STROYINVEST.ConcreteRecipeEngine;

using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.ProductionBOM;

page 62101 "SI Concrete Recipe Card"
{
    PageType = Card;
    SourceTable = "SI Concrete Recipe";
    Caption = 'Рецептура бетону';
    ApplicationArea = All;
    UsageCategory = None;
    InsertAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Recipe Type"; Rec."Recipe Type")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(Subcategory; SubcategoryDisplayName)
                {
                    ApplicationArea = All;
                    Caption = 'Підкатегорія';
                    Editable = false;
                }
                field(Item; ItemDisplayName)
                {
                    ApplicationArea = All;
                    Caption = 'Товар';
                    Editable = false;
                }
                field(Variant; VariantDisplayName)
                {
                    ApplicationArea = All;
                    Caption = 'Варіант';
                    Editable = false;
                    Visible = IsVariantRecipe;
                }
                field(ParentRecipe; ParentRecipeDisplayName)
                {
                    ApplicationArea = All;
                    Caption = 'Батьківська рецептура';
                    Editable = false;
                    Visible = IsVariantRecipe;
                }
                field("Output Quantity"; Rec."Output Quantity")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Output UoM Code"; Rec."Output UoM Code")
                {
                    ApplicationArea = All;
                    Caption = 'Одиниця виміру виходу';
                    Editable = false;
                }
                field("Production BOM No."; Rec."Production BOM No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(Active; Rec.Active)
                {
                    ApplicationArea = All;
                }
                field("Recipe No."; Rec."Recipe No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Importance = Additional;
                }
            }
            part(Revisions; "SI Recipe Revisions Part")
            {
                ApplicationArea = All;
                SubPageLink = "Recipe No." = field("Recipe No.");
                UpdatePropagation = Both;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ResolveApplicableRevisions)
            {
                Caption = 'Актуальні ревізії';
                ApplicationArea = All;
                Image = FilterLines;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ToolTip = 'Показати всі сертифіковані й адміністративно активні ревізії рецептур, актуальні на вибрану дату. Допускається кілька кандидатів; автоматичний вибір не виконується.';

                trigger OnAction()
                var
                    ResolveDate: Page "SI Recipe Resolve Date";
                    Candidates: Page "SI Recipe Candidates";
                    TargetDate: Date;
                begin
                    ResolveDate.SetTargetDate(Today());
                    if ResolveDate.RunModal() <> Action::OK then
                        exit;

                    TargetDate := ResolveDate.GetTargetDate();
                    if TargetDate = 0D then
                        Error(TargetDateRequiredErr);

                    Candidates.SetContext(
                        Rec."Item No.",
                        Rec."Variant Code",
                        TargetDate);
                    Candidates.RunModal();
                end;
            }
        }

        area(Navigation)
        {
            action(OpenProductionBOM)
            {
                Caption = 'Виробнича специфікація';
                ApplicationArea = All;
                Image = BOM;
                Enabled = HasProductionBOM;
                ToolTip = 'Відкрити стандартну виробничу специфікацію Business Central, спроєктовану з цієї рецептури.';

                trigger OnAction()
                var
                    ProdBOMHeader: Record "Production BOM Header";
                begin
                    Rec.TestField("Production BOM No.");
                    ProdBOMHeader.Get(Rec."Production BOM No.");
                    Page.Run(Page::"Production BOM", ProdBOMHeader);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        UpdateDisplayNames();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateDisplayNames();
    end;

    local procedure UpdateDisplayNames()
    var
        ItemCategory: Record "Item Category";
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ParentRecipe: Record "SI Concrete Recipe";
    begin
        IsVariantRecipe := Rec."Recipe Type" = Rec."Recipe Type"::Variant;
        HasProductionBOM := Rec."Production BOM No." <> '';

        Clear(SubcategoryDisplayName);
        Clear(ItemDisplayName);
        Clear(VariantDisplayName);
        Clear(ParentRecipeDisplayName);

        if (Rec."Subcategory Code" <> '') and ItemCategory.Get(Rec."Subcategory Code") then begin
            SubcategoryDisplayName := ItemCategory.Description;
            if SubcategoryDisplayName = '' then
                SubcategoryDisplayName := ItemCategory.Code;
        end;

        if (Rec."Item No." <> '') and Item.Get(Rec."Item No.") then begin
            ItemDisplayName := Item.Description;
            if ItemDisplayName = '' then
                ItemDisplayName := Item."No.";
        end;

        if (Rec."Item No." <> '') and (Rec."Variant Code" <> '') and
           ItemVariant.Get(Rec."Item No.", Rec."Variant Code")
        then begin
            VariantDisplayName := ItemVariant.Description;
            if VariantDisplayName = '' then
                VariantDisplayName := ItemVariant.Code;
        end;

        if (Rec."Parent Recipe No." <> '') and ParentRecipe.Get(Rec."Parent Recipe No.") then begin
            ParentRecipeDisplayName := ParentRecipe.Description;
            if ParentRecipeDisplayName = '' then
                ParentRecipeDisplayName := ParentRecipe."Recipe No.";
        end;
    end;

    var
        SubcategoryDisplayName: Text[100];
        ItemDisplayName: Text[100];
        VariantDisplayName: Text[100];
        ParentRecipeDisplayName: Text[100];
        IsVariantRecipe: Boolean;
        HasProductionBOM: Boolean;
        TargetDateRequiredErr: Label 'Потрібно вказати цільову дату.';
}
