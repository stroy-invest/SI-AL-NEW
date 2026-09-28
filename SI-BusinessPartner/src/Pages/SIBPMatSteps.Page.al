page 54072 "SI BP Mat. Steps"
{
    PageType = ListPart;
    SourceTable = "SI BP Materialization Step";

    Caption = 'Кроки матеріалізації';
    ApplicationArea = All;

    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Step Type"; Rec."Step Type")
                {
                    ApplicationArea = All;
                }

                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                }

                field("Attempt Count"; Rec."Attempt Count")
                {
                    ApplicationArea = All;
                }

                field("Started At"; Rec."Started At")
                {
                    ApplicationArea = All;
                }

                field("Completed At"; Rec."Completed At")
                {
                    ApplicationArea = All;
                }

                field("Error Message"; Rec."Error Message")
                {
                    ApplicationArea = All;
                }

                field(Details; Rec.Details)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}