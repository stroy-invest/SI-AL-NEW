page 53042 "SI Nominal Value Lookup"
{
    PageType = List;
    SourceTable = "SI Nominal Size Mapping";
    SourceTableView = sorting("Mapping Set Code", "Sort Order", "NPS Code") where(Active = const(true));
    Caption = 'Номінальні діаметри';
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(NPS; Rec."NPS Code") { ApplicationArea = All; }
                field(DN; Rec.DN) { ApplicationArea = All; }
            }
        }
    }
}
