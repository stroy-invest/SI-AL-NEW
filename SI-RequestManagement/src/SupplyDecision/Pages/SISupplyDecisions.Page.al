page 52046 "SI Supply Decisions"
{
    PageType = List;
    SourceTable = "SI Supply Decision Header";
    ApplicationArea = All;
    UsageCategory = Lists;
    Caption = 'Рішення щодо забезпечення';
    CardPageId = "SI Supply Decision Card";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Decisions)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                }
                field("Request No."; Rec."Request No.")
                {
                    ApplicationArea = All;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                }
                field("Construction Object No."; Rec."Construction Object No.")
                {
                    ApplicationArea = All;
                }
                field("Required Date"; Rec."Required Date")
                {
                    ApplicationArea = All;
                }
                field("Created By"; Rec."Created By")
                {
                    ApplicationArea = All;
                }
                field("Created At"; Rec."Created At")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
