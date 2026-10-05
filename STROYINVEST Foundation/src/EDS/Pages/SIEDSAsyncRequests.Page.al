page 50469 "SI EDS Async Requests"
{
    PageType = List;
    SourceTable = "SI EDS Async Request";
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'EDS — асинхронні запити';
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field(Status; Rec.Status) { ApplicationArea = All; }
                field("Service Code"; Rec."Service Code") { ApplicationArea = All; }
                field("Operation Code"; Rec."Operation Code") { ApplicationArea = All; }
                field("Business Key"; Rec."Business Key") { ApplicationArea = All; }
                field("Provider Code"; Rec."Provider Code") { ApplicationArea = All; }
                field("Started At"; Rec."Started At") { ApplicationArea = All; }
                field("Last Attempt At"; Rec."Last Attempt At") { ApplicationArea = All; }
                field("Next Attempt At"; Rec."Next Attempt At") { ApplicationArea = All; }
                field("Expires At"; Rec."Expires At") { ApplicationArea = All; }
                field("Completed At"; Rec."Completed At") { ApplicationArea = All; }
                field("Attempt Count"; Rec."Attempt Count") { ApplicationArea = All; }
                field("HTTP Status Code"; Rec."HTTP Status Code") { ApplicationArea = All; }
                field("HTTP Reason Phrase"; Rec."HTTP Reason Phrase") { ApplicationArea = All; }
                field("Error Message"; Rec."Error Message") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ProcessDueNow)
            {
                ApplicationArea = All;
                Caption = 'Обробити належні зараз';
                Image = Process;
                trigger OnAction()
                var
                    Worker: Codeunit "SI EDS Async Worker";
                begin
                    Worker.ProcessDue();
                    CurrPage.Update(false);
                end;
            }
        }
    }
}
