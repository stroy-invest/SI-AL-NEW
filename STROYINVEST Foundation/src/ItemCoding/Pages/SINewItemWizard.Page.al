page 50140 "SI New Item Wizard"
{
    PageType = StandardDialog;
    ApplicationArea = All;
    Caption = 'Новий товар';

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(ItemCategoryCode; ItemCategoryCode)
                {
                    ApplicationArea = All;
                    Caption = 'Код категорії';
                    TableRelation = "Item Category".Code;
                }

                field(ItemDescription; ItemDescription)
                {
                    ApplicationArea = All;
                    Caption = 'Опис товару';
                }
            }
        }
    }

    var
        ItemCategoryCode: Code[20];
        ItemDescription: Text[100];

    procedure GetItemCategoryCode(): Code[20]
    begin
        exit(ItemCategoryCode);
    end;

    procedure GetItemDescription(): Text[100]
    begin
        exit(ItemDescription);
    end;
}