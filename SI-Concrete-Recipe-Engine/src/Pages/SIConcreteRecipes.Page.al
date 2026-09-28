namespace STROYINVEST.ConcreteRecipeEngine;

using Microsoft.Inventory.Item;

page 62100 "SI Concrete Recipes"
{
    PageType = List;
    SourceTable = "SI Concrete Recipe";
    Caption = 'Рецептури бетону';
    ApplicationArea = All;
    UsageCategory = Lists;
    CardPageId = "SI Concrete Recipe Card";
    InsertAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Recipes)
            {
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field("Recipe Type"; Rec."Recipe Type")
                {
                    ApplicationArea = All;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Recipe No."; Rec."Recipe No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Вказує стабільний технічний ключ рецептури, сформований із кодів продукту.';
                }
                field("Output Quantity"; Rec."Output Quantity")
                {
                    ApplicationArea = All;
                }
                field("Output UoM Code"; Rec."Output UoM Code")
                {
                    ApplicationArea = All;
                    Caption = 'Одиниця виміру виходу';
                }
                field(Active; Rec.Active)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(TreeView)
            {
                Caption = 'Дерево';
                ApplicationArea = All;
                Image = Hierarchy;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ToolTip = 'Відкриває робочу область рецептур у вигляді ієрархічного дерева.';

                trigger OnAction()
                begin
                    Page.Run(Page::"SI Concrete Recipes Tree");
                end;
            }

            action(CreateRecipe)
            {
                Caption = 'Створити рецептуру';
                ApplicationArea = All;
                Image = New;
                Promoted = true;
                PromotedCategory = New;
                PromotedOnly = true;
                ToolTip = 'Виберіть товар бетону або його варіант. За потреби система створить логічну рецептуру та відкриє її поточну чернеткову ревізію.';

                trigger OnAction()
                var
                    ProductSelector: Page "SI Recipe Product Selector";
                    RecipeCreationMgt: Codeunit "SI Recipe Creation Mgt.";
                    RecipeRevision: Record "SI Concrete Recipe Revision";
                    ItemNo: Code[20];
                    VariantCode: Code[10];
                begin
                    ProductSelector.RunModal();
                    if not ProductSelector.GetSelection(ItemNo, VariantCode) then
                        exit;

                    RecipeCreationMgt.GetOrCreateDraftRevision(ItemNo, VariantCode, RecipeRevision);

                    // Keep the UI boundary outside the write transaction.
                    Commit();
                    Page.Run(Page::"SI Recipe Revision Card", RecipeRevision);
                    CurrPage.Update(false);
                end;
            }
        }
    }
}
