page 58000 "SI Package Types"
{
    PageType = List;
    SourceTable = "SI Package Type";
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'Типи паковань';
    CardPageId = "SI Package Type Card";

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field("Description EN"; Rec."Description EN")
                {
                    ApplicationArea = All;
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
