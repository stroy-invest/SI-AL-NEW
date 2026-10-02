page 50614 "SI Workforce Capabilities"
{
    PageType = List;
    SourceTable = "SI Workforce Capability";
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'Workforce Capabilities';

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
