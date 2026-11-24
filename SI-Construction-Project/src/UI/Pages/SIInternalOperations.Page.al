page 60040 "SI Internal Operations"
{
    PageType = List;
    SourceTable = "SI Internal Operation";
    Caption = 'Внутрішні операції';
    ApplicationArea = All;
    UsageCategory = Administration;
    layout
    {
        area(Content)
        {
            repeater(Operations)
            {
                field(Code; Rec.Code) { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
            }
        }
    }
}
