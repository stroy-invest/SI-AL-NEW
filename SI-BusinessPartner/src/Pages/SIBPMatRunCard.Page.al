page 54071 "SI BP Mat. Run Card"
{
    PageType = Card;
    SourceTable = "SI BP Materialization Run";

    Caption = 'Запуск матеріалізації';
    ApplicationArea = All;

    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Загальні дані';

                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                }

                field("Role Code"; Rec."Role Code")
                {
                    ApplicationArea = All;
                }

                field("Business Partner No."; Rec."Business Partner No.")
                {
                    ApplicationArea = All;
                }

                field("Role Type"; Rec."Role Type")
                {
                    ApplicationArea = All;
                }

                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                }

                field("Current Step"; Rec."Current Step")
                {
                    ApplicationArea = All;
                }

                field("Last Successful Step"; Rec."Last Successful Step")
                {
                    ApplicationArea = All;
                }
            }

            group(Result)
            {
                Caption = 'Результат';

                field("ERP No."; Rec."ERP No.")
                {
                    ApplicationArea = All;
                }

                field("Contact No."; Rec."Contact No.")
                {
                    ApplicationArea = All;
                }

                field("Error Message"; Rec."Error Message")
                {
                    ApplicationArea = All;
                    MultiLine = true;
                }
            }

            part(Steps; "SI BP Mat. Steps")
            {
                ApplicationArea = All;
                SubPageLink =
                    "Run Entry No." = field("Entry No.");
            }

            group(Audit)
            {
                Caption = 'Службові дані';

                field("Started At"; Rec."Started At")
                {
                    ApplicationArea = All;
                }

                field("Completed At"; Rec."Completed At")
                {
                    ApplicationArea = All;
                }

                field("Created At"; Rec."Created At")
                {
                    ApplicationArea = All;
                }

                field("Created By"; Rec."Created By")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RunPreflight)
            {
                Caption = 'Запустити pre-flight';
                ApplicationArea = All;
                Image = CheckRulesSyntax;

                trigger OnAction()
                var
                    MatMgt: Codeunit "SI BP Materialization Mgt.";
                begin
                    if MatMgt.RunPreflight(Rec) then
                        Message(
                            'Pre-flight validation успішно завершена.')
                    else
                        Message(
                            'Pre-flight validation завершилася з помилками. Перегляньте журнал кроків.');

                    CurrPage.Update(false);
                end;
            }
        }
    }
}