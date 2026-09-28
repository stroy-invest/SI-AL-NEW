page 54032 "SI BP Role History"
{
    PageType = ListPart;
    SourceTable = "SI BP Role Status Entry";

    Caption = 'Історія станів';
    ApplicationArea = All;

    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Changed At"; Rec."Changed At")
                {
                    ApplicationArea = All;
                }

                field("Old Status"; Rec."Old Status")
                {
                    ApplicationArea = All;
                }

                field("New Status"; Rec."New Status")
                {
                    ApplicationArea = All;
                }

                field("Changed By"; Rec."Changed By")
                {
                    ApplicationArea = All;
                }

                field(Reason; Rec.Reason)
                {
                    ApplicationArea = All;
                }

                field(Comment; Rec.Comment)
                {
                    ApplicationArea = All;
                }

                field(Source; Rec.Source)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}