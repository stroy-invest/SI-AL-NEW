page 53034 "SI Product Family Templates"
{
    PageType = List;
    SourceTable = "SI Product Family Template";
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'Шаблони сімейств продуктів';
    CardPageId = "SI Product Family Tmpl. Card";

    layout
    {
        area(Content)
        {
            repeater(Templates)
            {
                field(Code; Rec.Code) { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
                field(Blocked; Rec.Blocked) { ApplicationArea = All; }
            }
        }
    }
}
