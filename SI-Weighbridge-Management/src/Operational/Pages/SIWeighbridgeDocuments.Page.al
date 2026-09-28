page 59100 "SI Weighbridge Documents"
{
    PageType = List;
    SourceTable = "SI Weighbridge Document";

    ApplicationArea = All;
    UsageCategory = Lists;

    Caption = 'Операційні документи вагової';
    CardPageId = "SI Weighbridge Document Card";

    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                }

                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                }

                field("Operation Type"; Rec."Operation Type")
                {
                    ApplicationArea = All;
                }

                field("Weighing Date/Time"; Rec."Weighing Date/Time")
                {
                    ApplicationArea = All;
                }

                field("Vehicle Plate"; Rec."Vehicle Plate")
                {
                    ApplicationArea = All;
                }
                /*
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = All;
                }

                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                }
                */
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = All;
                }

                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = All;
                }

                field("TTN No."; Rec."TTN No.")
                {
                    ApplicationArea = All;
                }

                field("Weighing Entry No."; Rec."Weighing Entry No.")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}