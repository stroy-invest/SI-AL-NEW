page 56103 "SI Classification Node Card"
{
    PageType = Card;
    SourceTable = "SI Classification Node";
    ApplicationArea = All;
    UsageCategory = None;
    Caption = 'Вузол класифікації';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Загальне';

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
                    MultiLine = true;
                    ToolTip = 'Визначає назву вузла класифікації.';
                }
                field("Description EN"; Rec."Description EN")
                {
                    ApplicationArea = All;
                    MultiLine = true;
                    ToolTip = 'Визначає англомовну назву вузла класифікації.';
                }
                field("Search Description"; Rec."Search Description")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає текст, що використовується для пошуку вузла.';
                }
            }

            group(Hierarchy)
            {
                Caption = 'Ієрархія';

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
                field("Full Path"; Rec."Full Path")
                {
                    ApplicationArea = All;
                    MultiLine = true;
                    ToolTip = 'Показує повний шлях від кореневого вузла до поточного вузла.';
                }
                field("Child Count"; Rec."Child Count")
                {
                    ApplicationArea = All;
                    ToolTip = 'Показує кількість безпосередніх дочірніх вузлів.';
                }
                field("Is Leaf"; Rec."Is Leaf")
                {
                    ApplicationArea = All;
                    ToolTip = 'Показує, чи є вузол кінцевим і не має дочірніх вузлів.';
                }
            }

            group(Status)
            {
                Caption = 'Стан і застосування';

                field("Is Selectable"; Rec."Is Selectable")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає, чи можна використовувати вузол для класифікації об’єктів.';
                }
                field("Is Service"; Rec."Is Service")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає, чи належить вузол до класифікації послуг.';
                }
                field("Is Active"; Rec."Is Active")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає, чи є вузол активним.';
                }
                field("Valid From"; Rec."Valid From")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає дату початку дії вузла.';
                }
                field("Valid To"; Rec."Valid To")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає дату завершення дії вузла.';
                }
            }

            group(Source)
            {
                Caption = 'Джерело';

                field("Source Version"; Rec."Source Version")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає версію джерела, з якого було імпортовано вузол.';
                }
                field("Source Line No."; Rec."Source Line No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає номер рядка вузла у вихідному джерелі.';
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

            action(OpenChildNodes)
            {
                ApplicationArea = All;
                Caption = 'Дочірні вузли';
                Image = Hierarchy;
                ToolTip = 'Відкрити безпосередні дочірні вузли поточного вузла.';

                trigger OnAction()
                var
                    ChildNode: Record "SI Classification Node";
                begin
                    ChildNode.SetRange(
                        "Classification System Code",
                        Rec."Classification System Code");
                    ChildNode.SetRange(
                        "Parent Code",
                        Rec.Code);

                    Page.Run(
                        Page::"SI Classification Nodes",
                        ChildNode);
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
            actionref(OpenChildNodesPromoted; OpenChildNodes)
            {
            }
        }
    }
}
