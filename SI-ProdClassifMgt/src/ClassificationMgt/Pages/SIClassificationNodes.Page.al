page 56102 "SI Classification Nodes"
{
    PageType = List;
    SourceTable = "SI Classification Node";
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'Вузли класифікації';
    CardPageId = "SI Classification Node Card";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Classification System Code"; Rec."Classification System Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає систему класифікації, до якої належить вузол.';
                }
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає код вузла класифікації.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає назву вузла класифікації.';
                }
                field("Parent Code"; Rec."Parent Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає код батьківського вузла.';
                }
                field(Level; Rec.Level)
                {
                    ApplicationArea = All;
                    ToolTip = 'Показує рівень вузла в ієрархії.';
                }
                field("Node Type"; Rec."Node Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає тип вузла класифікації.';
                }
                field("Sort Order"; Rec."Sort Order")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає порядок вузла серед інших вузлів одного рівня.';
                }
                field("Is Leaf"; Rec."Is Leaf")
                {
                    ApplicationArea = All;
                    ToolTip = 'Показує, чи є вузол кінцевим і не має дочірніх вузлів.';
                }
                field("Is Selectable"; Rec."Is Selectable")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає, чи можна використовувати вузол для класифікації об’єктів.';
                }
                field("Is Active"; Rec."Is Active")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає, чи є вузол активним.';
                }
                field("Child Count"; Rec."Child Count")
                {
                    ApplicationArea = All;
                    ToolTip = 'Показує кількість безпосередніх дочірніх вузлів.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OpenSystem)
            {
                ApplicationArea = All;
                Caption = 'Система класифікації';
                Image = ViewDetails;
                ToolTip = 'Відкрити картку системи класифікації поточного вузла.';

                trigger OnAction()
                var
                    ClassificationSystem: Record "SI Classification System";
                begin
                    ClassificationSystem.Get(
                        Rec."Classification System Code");

                    Page.Run(
                        Page::"SI Classification System Card",
                        ClassificationSystem);
                end;
            }

            action(OpenParentNode)
            {
                ApplicationArea = All;
                Caption = 'Батьківський вузол';
                Image = PreviousRecord;
                Enabled = Rec."Parent Code" <> '';
                ToolTip = 'Відкрити картку батьківського вузла.';

                trigger OnAction()
                var
                    ParentNode: Record "SI Classification Node";
                begin
                    Rec.TestField("Parent Code");

                    ParentNode.Get(
                        Rec."Classification System Code",
                        Rec."Parent Code");

                    Page.Run(
                        Page::"SI Classification Node Card",
                        ParentNode);
                end;
            }
        }

        area(Promoted)
        {
            actionref(OpenSystemPromoted; OpenSystem)
            {
            }
            actionref(OpenParentNodePromoted; OpenParentNode)
            {
            }
        }
    }
}
