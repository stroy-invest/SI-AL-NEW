page 58020 "SI UoM Semantic Profiles"
{
    PageType = List;
    SourceTable = "SI UoM Semantic Profile";
    ApplicationArea = All;
    UsageCategory = Lists;
    Caption = 'Семантичні профілі UoM';
    layout
    {
        area(Content)
        {
            repeater(Profiles)
            {
                field(Code; Rec.Code) { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
                field("Is Package"; Rec."Is Package") { ApplicationArea = All; }
                field(Blocked; Rec.Blocked) { ApplicationArea = All; }
            }
        }
    }
}
