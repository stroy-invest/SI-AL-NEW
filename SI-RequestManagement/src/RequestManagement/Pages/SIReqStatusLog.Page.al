page 52025 "SI Req. Status Log"
{
    PageType = List;
    SourceTable = "SI Req. Status Log";
    ApplicationArea = All;
    UsageCategory = History;
    Caption = 'Журнал станів заявок';
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(LogEntries)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                }

                field("Request No."; Rec."Request No.")
                {
                    ApplicationArea = All;
                }

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