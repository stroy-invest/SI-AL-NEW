page 56105 "SI Classification Node Part"
{
    PageType = CardPart;
    SourceTable = "SI Classification Node";
    SourceTableTemporary = true;
    ApplicationArea = All;
    Caption = 'Вибраний вузол';
    Editable = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Вибраний вузол';

                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Показує код вибраного вузла.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    MultiLine = true;
                    ToolTip = 'Показує назву вибраного вузла.';
                }
                field("Parent Code"; Rec."Parent Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Показує код батьківського вузла.';
                }
                field(Level; Rec.Level)
                {
                    ApplicationArea = All;
                    ToolTip = 'Показує рівень вузла в ієрархії.';
                }
                field("Node Type"; Rec."Node Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Показує тип вузла класифікації.';
                }
                field("Is Leaf"; Rec."Is Leaf")
                {
                    ApplicationArea = All;
                    ToolTip = 'Показує, чи є вузол кінцевим.';
                }
                field("Is Selectable"; Rec."Is Selectable")
                {
                    ApplicationArea = All;
                    ToolTip = 'Показує, чи можна використовувати вузол для класифікації.';
                }
                field("Is Service"; Rec."Is Service")
                {
                    ApplicationArea = All;
                    ToolTip = 'Показує, чи належить вузол до послуг.';
                }
                field("Is Active"; Rec."Is Active")
                {
                    ApplicationArea = All;
                    ToolTip = 'Показує, чи є вузол активним.';
                }
                field("Child Count"; Rec."Child Count")
                {
                    ApplicationArea = All;
                    ToolTip = 'Показує кількість безпосередніх дочірніх вузлів.';
                }
                field("Full Path"; Rec."Full Path")
                {
                    ApplicationArea = All;
                    MultiLine = true;
                    ToolTip = 'Показує повний шлях до вибраного вузла.';
                }
            }
        }
    }

    procedure SetNode(
        ClassificationSystemCode: Code[20];
        NodeCode: Code[50])
    var
        ClassificationNode: Record "SI Classification Node";
    begin
        Rec.Reset();
        Rec.DeleteAll();

        if (ClassificationSystemCode = '') or
           (NodeCode = '')
        then begin
            CurrPage.Update(false);
            exit;
        end;

        if not ClassificationNode.Get(
            ClassificationSystemCode,
            NodeCode)
        then begin
            CurrPage.Update(false);
            exit;
        end;

        ClassificationNode.CalcFields("Child Count");

        Rec.Init();
        Rec.TransferFields(ClassificationNode, true);
        Rec.Insert();

        CurrPage.Update(false);
    end;
}
