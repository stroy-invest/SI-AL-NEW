page 53018 "SI Wiz. Product Parameters"
{
    PageType = List;
    SourceTable = "SI Product Parameter";
    ApplicationArea = All;
    Caption = 'Параметри продуктів';
    UsageCategory = None;

    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    SourceTableView =
        sorting(Code)
        where(Blocked = const(false));

    layout
    {
        area(Content)
        {
            repeater(Parameters)
            {
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                    Caption = 'Код';
                    Importance = Promoted;
                    ToolTip = 'Визначає код корпоративного параметра.';
                }

                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Назва';
                    Importance = Promoted;
                    ToolTip = 'Визначає назву корпоративного параметра.';
                }

                field("Base Item Category Code"; Rec."Base Item Category Code")
                {
                    ApplicationArea = All;
                    Caption = 'Базова категорія товару';
                    ToolTip = 'Визначає базову категорію товарів параметра. Порожнє значення означає глобальний параметр.';
                }

                field("Value Type"; Rec."Value Type")
                {
                    ApplicationArea = All;
                    Caption = 'Тип значення';
                    ToolTip = 'Визначає тип значення параметра.';
                }
            }
        }
    }
}