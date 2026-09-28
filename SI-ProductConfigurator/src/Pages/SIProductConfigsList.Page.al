page 53036 "SI Product Configs List"
{
    PageType = List;
    SourceTable = "SI Product Config.";
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'Конфігурації продуктів — список';
    CardPageId = "SI Product Config. Card";
    Editable = false;

    SourceTableView =
        sorting(
            "Family Code",
            Status,
            "No.");

    layout
    {
        area(Content)
        {
            repeater(Configs)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    ToolTip = 'Визначає номер конфігурації продукту.';
                }

                field("Family Code"; Rec."Family Code")
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    ToolTip = 'Визначає сімейство продукту.';
                }

                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    ToolTip = 'Визначає згенеровану назву продукту.';
                }

                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    ToolTip = 'Визначає статус конфігурації.';
                }

                field("Validation Message"; Rec."Validation Message")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає результат останньої перевірки.';
                }

                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає, чи заблоковано конфігурацію.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            group(View)
            {
                Caption = 'Подання';

                action(OpenHierarchyView)
                {
                    ApplicationArea = All;
                    Caption = 'Ієрархія';
                    ToolTip = 'Відкриває конфігурації продуктів у вигляді ієрархічного дерева.';
                    Image = Hierarchy;

                    trigger OnAction()
                    begin
                        Page.Run(Page::"SI Product Configs.");
                    end;
                }
            }
        }

        area(Promoted)
        {
            group(View_Process)
            {
                Caption = 'Подання';

                actionref(OpenHierarchyView_Promoted; OpenHierarchyView)
                {
                }
            }
        }
    }
}
