page 53020 "SI Item ERP Projections"
{
    PageType = List;
    SourceTable = "SI Item ERP Projection";
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'ERP-проєкції товарів';
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Projections)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає технічний номер запису проєкції.';
                }

                field("Family Code"; Rec."Family Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає сімейство продуктів.';
                }

                field("Item Projection Key"; Rec."Item Projection Key")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає нормалізований ключ параметрів, які формують товар.';
                }

                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    ToolTip = 'Визначає стандартний товар Business Central.';
                }

                field("Item Description"; Rec."Item Description")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає назву стандартного товару Business Central.';
                }

                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає стан ERP-проєкції.';
                }

                field("Created At"; Rec."Created At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає дату й час створення проєкції.';
                }

                field("Created By"; Rec."Created By")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає користувача, який створив проєкцію.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OpenItem)
            {
                ApplicationArea = All;
                Caption = 'Відкрити товар';
                Image = Item;
                ToolTip = 'Відкриває картку стандартного товару Business Central.';

                trigger OnAction()
                var
                    Item: Record Item;
                begin
                    Rec.TestField("Item No.");
                    Item.Get(Rec."Item No.");
                    Page.Run(Page::"Item Card", Item);
                end;
            }
        }

        area(Promoted)
        {
            actionref(OpenItemPromoted; OpenItem)
            {
            }
        }
    }
}
