page 56104 "SI Classification Workspace"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'Класифікатор продукції';

    layout
    {
        area(Content)
        {
            group(SystemSelection)
            {
                Caption = 'Система класифікації';

                field(ClassificationSystemCode; ClassificationSystemCode)
                {
                    ApplicationArea = All;
                    Caption = 'Система класифікації';
                    TableRelation =
                        "SI Classification System".Code where(
                            "Is Active" = const(true));
                    ToolTip = 'Визначає систему класифікації, дерево якої потрібно показати.';

                    trigger OnValidate()
                    begin
                        ClearSelectedNode();
                        RenderCurrentTree();
                    end;
                }
            }

            group(TreeArea)
            {
                ShowCaption = false;

                usercontrol(ClassificationTree; "SI Classification Tree")
                {
                    ApplicationArea = All;

                    trigger ControlReady()
                    begin
                        ControlIsReady := true;
                        EnsureClassificationSystem();
                        RenderCurrentTree();
                    end;

                    trigger NodeSelected(
                        SystemCode: Text;
                        NodeCode: Text)
                    begin
                        SelectedSystemCode :=
                            CopyStr(
                                SystemCode,
                                1,
                                MaxStrLen(SelectedSystemCode));
                        SelectedNodeCode :=
                            CopyStr(
                                NodeCode,
                                1,
                                MaxStrLen(SelectedNodeCode));

                        CurrPage.NodeDetails.Page.SetNode(
                            SelectedSystemCode,
                            SelectedNodeCode);

                        CurrPage.Update(false);
                    end;
                }
            }

            part(NodeDetails; "SI Classification Node Part")
            {
                ApplicationArea = All;
                UpdatePropagation = Both;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RefreshTree)
            {
                ApplicationArea = All;
                Caption = 'Оновити дерево';
                Image = Refresh;
                ToolTip = 'Повторно побудувати дерево вибраної системи класифікації.';

                trigger OnAction()
                begin
                    RenderCurrentTree();
                end;
            }

            action(OpenSelectedNode)
            {
                ApplicationArea = All;
                Caption = 'Відкрити вузол';
                Image = ViewDetails;
                Enabled = SelectedNodeCode <> '';
                ToolTip = 'Відкрити картку вибраного вузла класифікації.';

                trigger OnAction()
                var
                    ClassificationNode: Record "SI Classification Node";
                begin
                    if (SelectedSystemCode = '') or
                       (SelectedNodeCode = '')
                    then
                        exit;

                    ClassificationNode.Get(
                        SelectedSystemCode,
                        SelectedNodeCode);

                    Page.Run(
                        Page::"SI Classification Node Card",
                        ClassificationNode);
                end;
            }

            action(OpenFlatList)
            {
                ApplicationArea = All;
                Caption = 'Плоский список';
                Image = List;
                ToolTip = 'Відкрити стандартний список вузлів вибраної системи класифікації.';

                trigger OnAction()
                var
                    ClassificationNode: Record "SI Classification Node";
                begin
                    if ClassificationSystemCode <> '' then
                        ClassificationNode.SetRange(
                            "Classification System Code",
                            ClassificationSystemCode);

                    Page.Run(
                        Page::"SI Classification Nodes",
                        ClassificationNode);
                end;
            }
        }

        area(Promoted)
        {
            actionref(RefreshTreePromoted; RefreshTree)
            {
            }
            actionref(OpenSelectedNodePromoted; OpenSelectedNode)
            {
            }
            actionref(OpenFlatListPromoted; OpenFlatList)
            {
            }
        }
    }

    trigger OnOpenPage()
    begin
        EnsureClassificationSystem();
    end;

    var
        ClassificationSystemCode: Code[20];
        SelectedSystemCode: Code[20];
        SelectedNodeCode: Code[50];
        ControlIsReady: Boolean;

    local procedure EnsureClassificationSystem()
    var
        ClassificationSystem: Record "SI Classification System";
    begin
        if ClassificationSystemCode <> '' then
            exit;

        ClassificationSystem.SetRange("Is Active", true);
        ClassificationSystem.SetCurrentKey(
            "Is Active",
            Description);

        if ClassificationSystem.FindFirst() then
            ClassificationSystemCode :=
                ClassificationSystem.Code;
    end;

    local procedure RenderCurrentTree()
    var
        ClassificationTreeMgt:
            Codeunit "SI Classification Tree Mgt.";
        TreeJson: Text;
    begin
        if not ControlIsReady then
            exit;

        if ClassificationSystemCode = '' then begin
            CurrPage.ClassificationTree.ClearTree();
            exit;
        end;

        TreeJson :=
            ClassificationTreeMgt.BuildTreeJson(
                ClassificationSystemCode);

        CurrPage.ClassificationTree.RenderTree(TreeJson);
    end;

    local procedure ClearSelectedNode()
    begin
        Clear(SelectedSystemCode);
        Clear(SelectedNodeCode);

        CurrPage.NodeDetails.Page.SetNode('', '');
    end;
}
