page 58005 "SI Package Type Card"
{
    PageType = Card;
    SourceTable = "SI Package Type";
    ApplicationArea = All;
    Caption = 'Типи паковань';

    layout
    {
        area(Content)
        {
            group(General)
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
