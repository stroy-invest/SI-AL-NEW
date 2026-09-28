page 53009 "SI Prod. Families Part"
{
    PageType = ListPart;
    SourceTable = "SI Product Family";
    ApplicationArea = All;
    Caption = 'Сімейства продуктів';
    DelayedInsert = true;

    SourceTableView =
        sorting("Sort Order", Description);

    layout
    {
        area(Content)
        {
            repeater(Families)
            {
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    ToolTip = 'Визначає стабільний код сімейства продуктів.';
                }

                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    ToolTip = 'Визначає назву сімейства продуктів.';
                }

                field("Name Prefix"; Rec."Name Prefix")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає початковий текст згенерованої назви продукту.';
                }

                field("Supports Recipes"; Rec."Supports Recipes")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає, чи підтримує сімейство рецептури.';
                }

                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає, чи заблоковане сімейство.';
                }
            }
        }
    }
}