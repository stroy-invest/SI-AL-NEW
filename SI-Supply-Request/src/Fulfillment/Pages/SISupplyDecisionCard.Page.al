page 61012 "SI Supply Decision Card"
{
    PageType = Document;
    SourceTable = "SI Supply Decision Header";
    ApplicationArea = All;
    UsageCategory = None;
    Caption = 'Рішення щодо забезпечення';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Загальні';
                field("No."; Rec."No.") { ApplicationArea = All; Editable = false; }
                field("Request No."; Rec."Request No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    trigger OnDrillDown()
                    var
                        RequestHeader: Record "SI Supply Req Header";
                    begin
                        if RequestHeader.Get(Rec."Request No.") then
                            Page.Run(Page::"SI Supply Req Card", RequestHeader);
                    end;
                }
                field(Status; Rec.Status) { ApplicationArea = All; Editable = false; }
                field("Project No."; Rec."Project No.") { ApplicationArea = All; }
                field("Project Location Code"; Rec."Project Location Code") { ApplicationArea = All; }
                field("Required on Site At"; Rec."Required on Site At") { ApplicationArea = All; }
                field(Comment; Rec.Comment) { ApplicationArea = All; MultiLine = true; }
                field("Created By"; Rec."Created By") { ApplicationArea = All; }
                field("Created At"; Rec."Created At") { ApplicationArea = All; }
            }

            part(DecisionLines; "SI Supply Decision Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Decision No." = field("No.");
                UpdatePropagation = Both;
            }

            part(Allocations; "SI Supply Allocations")
            {
                ApplicationArea = All;
                Provider = DecisionLines;
                SubPageLink =
                    "Decision No." = field("Decision No."),
                    "Decision Line No." = field("Line No.");
                UpdatePropagation = Both;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ValidatePlan)
            {
                ApplicationArea = All;
                Caption = 'Перевірити розподіл';
                Image = Check;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    DecisionMgt: Codeunit "SI Supply Decision Mgt.";
                begin
                    CurrPage.SaveRecord();
                    DecisionMgt.ValidateAllocationPlan(Rec);
                    Message('Розподіл кількості заповнено коректно.');
                    CurrPage.Update(false);
                end;
            }
        }
    }
}
