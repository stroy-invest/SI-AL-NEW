page 50465 "SI EDS Operation Groups"
{
    PageType = List;
    SourceTable = "SI EDS Operation Group";
    Caption = 'EDS: групи операцій';
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Service Code"; Rec."Service Code")
                {
                    ApplicationArea = All;
                }

                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                }

                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }

                field("Path Prefix"; Rec."Path Prefix")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає базовий path prefix групи, наприклад /Authentication або /Company.';
                }

                field(Sequence; Rec.Sequence)
                {
                    ApplicationArea = All;
                }

                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}