page 53033 "SI Product Family Tmpl. Card"
{
    PageType = Card;
    SourceTable = "SI Product Family Template";
    ApplicationArea = All;
    Caption = 'Шаблон сімейства продуктів';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Загальне';
                field(Code; Rec.Code) { ApplicationArea = All; Importance = Promoted; }
                field(Description; Rec.Description) { ApplicationArea = All; Importance = Promoted; }
                field(Blocked; Rec.Blocked) { ApplicationArea = All; }
            }
            part(Parameters; "SI Family Template Parameters")
            {
                ApplicationArea = All;
                Caption = 'Параметри';
                SubPageLink = "Template Code" = field(Code);
            }
        }
    }
}
