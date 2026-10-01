page 56201 "SI IW Ledger History"
{
    PageType = List;
    ApplicationArea = All;
    Caption = 'SI IW HR Adapter - Ledger History';
    SourceTable = "IWSP Employee Ledger Entry2";
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(Context)
            {
                Caption = 'Diagnostic Context';

                field(EmployeeNoDisplay; EmployeeNo)
                {
                    ApplicationArea = All;
                    Caption = 'BC Employee No.';
                    Editable = false;
                }
            }

            repeater(Entries)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                }
                field("Staff Employee No."; Rec."Staff Employee No.")
                {
                    ApplicationArea = All;
                }
                field("Staff Employee Name"; Rec."Staff Employee Name")
                {
                    ApplicationArea = All;
                }
                field("Person No."; Rec."Person No.")
                {
                    ApplicationArea = All;
                }
                field("Entry Type"; Rec."Entry Type")
                {
                    ApplicationArea = All;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = All;
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = All;
                }
                field(Canceled; Rec.Canceled)
                {
                    ApplicationArea = All;
                }
                field("Actual Record"; Rec."Actual Record")
                {
                    ApplicationArea = All;
                }
                field("Department Code"; Rec."Department Code")
                {
                    ApplicationArea = All;
                }
                field("Department Name"; Rec."Department Name")
                {
                    ApplicationArea = All;
                }
                field("Unit No."; Rec."Unit No.")
                {
                    ApplicationArea = All;
                }
                field("Unit Name"; Rec."Unit Name")
                {
                    ApplicationArea = All;
                }
                field("Position Code"; Rec."Position Code")
                {
                    ApplicationArea = All;
                }
                field("Employment Type"; Rec."Employment Type")
                {
                    ApplicationArea = All;
                }
                field("Instances Quantity"; Rec."Instances Quantity")
                {
                    ApplicationArea = All;
                }
                field("Work Schedule Code"; Rec."Work Schedule Code")
                {
                    ApplicationArea = All;
                }
                field("Staff Category Code"; Rec."Staff Category Code")
                {
                    ApplicationArea = All;
                }
                field("Unit Category Code"; Rec."Unit Category Code")
                {
                    ApplicationArea = All;
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = All;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                }
                field("Document Line No."; Rec."Document Line No.")
                {
                    ApplicationArea = All;
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = All;
                }
                field("Internal Order No."; Rec."Internal Order No.")
                {
                    ApplicationArea = All;
                }
                field("Internal Order Date"; Rec."Internal Order Date")
                {
                    ApplicationArea = All;
                }
                field("Termination Reason"; Rec."Termination Reason")
                {
                    ApplicationArea = All;
                }
                field("Transfer Type"; Rec."Transfer Type")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    procedure SetEmployeeNo(NewEmployeeNo: Code[20])
    begin
        EmployeeNo := NewEmployeeNo;

        Rec.Reset();
        Rec.SetCurrentKey("Person No.", "Posting Date");
        Rec.SetRange("Person No.", EmployeeNo);
    end;

    var
        EmployeeNo: Code[20];
}
