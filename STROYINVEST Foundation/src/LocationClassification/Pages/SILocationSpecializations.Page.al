page 50507 "SI Location Specializations"
{
    PageType = List;
    SourceTable = "SI Location Specialization";
    Caption = 'Спеціалізації складів';
    ApplicationArea = All;
    UsageCategory = Administration;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(Code; Rec.Code) { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
                field(Active; Rec.Active) { ApplicationArea = All; }
            }
        }
    }
}
