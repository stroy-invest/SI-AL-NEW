page 52043 "SI Supply Decision Card"
{
    PageType = Document;
    SourceTable = "SI Supply Decision Header";
    ApplicationArea = All;
    Caption = 'Рішення щодо забезпечення';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Загальне';

                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Request No."; Rec."Request No.")
                {
                    ApplicationArea = All;
                    Editable = false;

                    trigger OnDrillDown()
                    var
                        RequestHeader: Record "SI Request Header";
                    begin
                        if RequestHeader.Get(Rec."Request No.") then
                            Page.Run(Page::"SI Request Card", RequestHeader);
                    end;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Construction Object No."; Rec."Construction Object No.")
                {
                    ApplicationArea = All;
                }
                field("Required Date"; Rec."Required Date")
                {
                    ApplicationArea = All;
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = All;
                    MultiLine = true;
                    Editable = IsPageEditable;
                }
                field("Created By"; Rec."Created By")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Created At"; Rec."Created At")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Completed By"; Rec."Completed By")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Completed At"; Rec."Completed At")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }

            part(DecisionLines; "SI Supply Decision Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Document No." = field("No.");
                UpdatePropagation = Both;
            }

            part(Allocations; "SI Supply Allocations")
            {
                ApplicationArea = All;
                Provider = DecisionLines;
                SubPageLink =
                    "Document No." = field("Document No."),
                    "Decision Line No." = field("Line No.");
                UpdatePropagation = Both;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ValidateDecision)
            {
                ApplicationArea = All;
                Caption = 'Перевірити розподіл';
                Image = Check;
                Promoted = true;
                PromotedCategory = Process;
                Enabled = IsPageEditable;

                trigger OnAction()
                var
                    SupplyDecisionMgt: Codeunit "SI Supply Decision Mgt.";
                begin
                    SupplyDecisionMgt.ValidateDecision(Rec);
                    Message(DecisionIsValidMsg);
                    CurrPage.Update(false);
                end;
            }

            action(CreateDocuments)
            {
                ApplicationArea = All;
                Caption = 'Створити документи';
                ToolTip = 'Створює документи Business Central відповідно до способів забезпечення.';
                Image = Process;
                Promoted = true;
                PromotedCategory = Process;
                Enabled = IsPageEditable;

                trigger OnAction()
                var
                    SupplyDecisionMgt: Codeunit "SI Supply Decision Mgt.";
                begin
                    CurrPage.SaveRecord();
                    SupplyDecisionMgt.CreateDocuments(Rec);
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SetPageState();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        SetPageState();
    end;

    local procedure SetPageState()
    begin
        IsPageEditable := Rec.Status = Rec.Status::Draft;
    end;

    var
        IsPageEditable: Boolean;
        DecisionIsValidMsg: Label 'Розподіл кількості заповнено коректно.';
}
