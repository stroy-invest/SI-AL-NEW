page 52024 "SI Req. Status Log Part"
{
    PageType = ListPart;
    SourceTable = "SI Req. Status Log";
    ApplicationArea = All;
    Caption = 'Історія станів';
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(LogEntries)
            {
                field("Date Time"; Rec."Date Time")
                {
                    ApplicationArea = All;
                }

                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = All;
                }

                field("Action Code"; Rec."Action Code")
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

                field(Comment; Rec.Comment)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}