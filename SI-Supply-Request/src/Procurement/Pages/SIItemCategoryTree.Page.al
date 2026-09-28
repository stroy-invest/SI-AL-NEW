page 61023 "SI Item Category Tree"
{
    PageType = List;
    SourceTable = "Item Category";
    Caption = 'Вибір категорії товару';
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;
    SourceTableView = sorting("Presentation Order");

    layout
    {
        area(Content)
        {
            repeater(Categories)
            {
                IndentationColumn = Rec.Indentation;
                ShowAsTree = true;
                TreeInitialState = CollapseAll;

                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Категорія';
                }
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                    Caption = 'Код';
                }
            }
        }
    }
}
