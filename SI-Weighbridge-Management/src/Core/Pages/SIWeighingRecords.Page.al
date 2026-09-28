page 59000 "SI Weighing Records"
{
    PageType = List;
    SourceTable = "SI Weighing Record";

    ApplicationArea = All;
    UsageCategory = Lists;

    Caption = 'Зважування';
    CardPageId = "SI Weighing Record Card";

    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Weighings)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                }

                field("Event Date/Time"; Rec."Event Date/Time")
                {
                    ApplicationArea = All;
                }

                field("Site Code"; Rec."Site Code")
                {
                    ApplicationArea = All;
                }

                field("Source System"; Rec."Source System")
                {
                    ApplicationArea = All;
                }

                field("Source Table"; Rec."Source Table")
                {
                    ApplicationArea = All;
                }

                field("Source Record ID"; Rec."Source Record ID")
                {
                    ApplicationArea = All;
                }

                field("Scale No."; Rec."Scale No.")
                {
                    ApplicationArea = All;
                }

                field("Gross Weight"; Rec."Gross Weight")
                {
                    ApplicationArea = All;
                }

                field("Tare Weight"; Rec."Tare Weight")
                {
                    ApplicationArea = All;
                }

                field("Net Weight"; Rec."Net Weight")
                {
                    ApplicationArea = All;
                }

                field("Vehicle Plate"; Rec."Vehicle Plate")
                {
                    ApplicationArea = All;
                }

                field("Trailer Plate"; Rec."Trailer Plate")
                {
                    ApplicationArea = All;
                }

                field("Inbound Entry No."; Rec."Inbound Entry No.")
                {
                    ApplicationArea = All;
                }

                field("External Event ID"; Rec."External Event ID")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(OpenCard)
            {
                ApplicationArea = All;
                Caption = 'Картка';

                trigger OnAction()
                begin
                    Page.Run(
                        Page::"SI Weighing Record Card",
                        Rec);
                end;
            }
        }
    }
}