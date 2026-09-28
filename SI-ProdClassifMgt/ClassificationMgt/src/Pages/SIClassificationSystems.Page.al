page 56100 "SI Classification Systems"
{
    PageType = List;
    SourceTable = "SI Classification System";
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'Системи класифікації';
    CardPageId = "SI Classification System Card";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає код системи класифікації.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає назву системи класифікації.';
                }
                field(Version; Rec.Version)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає версію системи класифікації.';
                }
                field(Authority; Rec.Authority)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає орган або установу, що веде класифікатор.';
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає країну або регіон, до якого належить система класифікації.';
                }
                field("Is Hierarchical"; Rec."Is Hierarchical")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає, чи має система класифікації ієрархічну структуру.';
                }
                field("Is Active"; Rec."Is Active")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає, чи є система класифікації активною.';
                }
                field("Default for Reporting"; Rec."Default for Reporting")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає, чи використовується система за замовчуванням для звітності.';
                }
                field("Valid From"; Rec."Valid From")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає дату початку дії системи класифікації.';
                }
                field("Valid To"; Rec."Valid To")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає дату завершення дії системи класифікації.';
                }
                field("Entry Count"; Rec."Entry Count")
                {
                    ApplicationArea = All;
                    ToolTip = 'Показує кількість вузлів у системі класифікації.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OpenNodes)
            {
                ApplicationArea = All;
                Caption = 'Вузли класифікації';
                Image = Hierarchy;
                ToolTip = 'Відкрити вузли поточної системи класифікації.';

                trigger OnAction()
                var
                    ClassificationNode: Record "SI Classification Node";
                begin
                    Rec.TestField(Code);

                    ClassificationNode.SetRange(
                        "Classification System Code",
                        Rec.Code);

                    Page.Run(
                        Page::"SI Classification Nodes",
                        ClassificationNode);
                end;
            }
        }

        area(Promoted)
        {
            actionref(OpenNodesPromoted; OpenNodes)
            {
            }
        }
    }
}
