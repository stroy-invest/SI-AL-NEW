page 61013 "SI Supply Decisions"
{
    PageType = List;
    SourceTable = "SI Supply Decision Header";
    ApplicationArea = All;
    UsageCategory = Lists;
    Caption = 'Рішення щодо забезпечення';
    CardPageId = "SI Supply Decision Card";

    layout
    {
        area(Content)
        {
            repeater(Decisions)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field("Request No."; Rec."Request No.") { ApplicationArea = All; }
                field("Project No."; Rec."Project No.") { ApplicationArea = All; }
                field(Status; Rec.Status) { ApplicationArea = All; }
                field("Required on Site At"; Rec."Required on Site At") { ApplicationArea = All; }
                field("Created At"; Rec."Created At") { ApplicationArea = All; }
            }
        }
    }
}
