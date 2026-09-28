page 57025 "SI Prok Recipe Workspace"
{
    PageType = Card;
    Caption = 'Рецептури виробництва';
    ApplicationArea = All;
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            usercontrol(RecipeTree; "SI Prok Recipe Tree")
            {
                ApplicationArea = All;

                trigger Ready()
                begin
                    RefreshTree();
                end;

                trigger NodeSelected(NodeType: Text; NodeId: Text)
                begin
                    SelectedType := NodeType;
                    SelectedId := NodeId;
                end;

                trigger NodeOpened(NodeType: Text; NodeId: Text)
                var
                    WorkspaceMgt: Codeunit "SI Prok Recipe Workspace Mgt.";
                begin
                    WorkspaceMgt.OpenNode(NodeType, NodeId);
                    RefreshTree();
                end;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ExpandAll)
            {
                ApplicationArea = All;
                Caption = 'Розгорнути все';
                Image = ExpandAll;
                trigger OnAction()
                begin
                    CurrPage.RecipeTree.ExpandAll();
                end;
            }
            action(CollapseAll)
            {
                ApplicationArea = All;
                Caption = 'Згорнути все';
                Image = CollapseAll;
                trigger OnAction()
                begin
                    CurrPage.RecipeTree.CollapseAll();
                end;
            }
            action(AddRecipe)
            {
                ApplicationArea = All;
                Caption = 'Додати';
                Image = New;
                trigger OnAction()
                begin
                    AddRecipeFromContext();
                end;
            }
            action(OpenRecipe)
            {
                ApplicationArea = All;
                Caption = 'Переглянути';
                Image = View;
                trigger OnAction()
                var
                    WorkspaceMgt: Codeunit "SI Prok Recipe Workspace Mgt.";
                begin
                    if SelectedId = '' then
                        Error('Спочатку виберіть рецептуру.');
                    WorkspaceMgt.OpenNode(SelectedType, SelectedId);
                    RefreshTree();
                end;
            }
            action(Refresh)
            {
                ApplicationArea = All;
                Caption = 'Оновити';
                Image = Refresh;
                trigger OnAction()
                begin
                    RefreshTree();
                end;
            }
        }
    }

    local procedure AddRecipeFromContext()
    var
        WorkspaceMgt: Codeunit "SI Prok Recipe Workspace Mgt.";
        BOMNo: Code[20];
        Choice: Integer;
        Snapshot: Record "SI Prok Recipe Snapshot";
        EntryNo: Integer;
    begin
        if SelectedId = '' then begin
            WorkspaceMgt.CreateBaseRecipe();
            RefreshTree();
            exit;
        end;

        if UpperCase(SelectedType) = 'MODIFIED' then begin
            Evaluate(EntryNo, SelectedId);
            Snapshot.Get(EntryNo);
            BOMNo := Snapshot."Production BOM No.";
        end else
            BOMNo := CopyStr(SelectedId, 1, MaxStrLen(BOMNo));

        Choice := StrMenu(
            StrSubstNo('Поруч із "%1",Всередині "%1"', BOMNo),
            2,
            'Де створити нову рецептуру?');
        case Choice of
            1:
                WorkspaceMgt.CreateBaseRecipe();
            2:
                WorkspaceMgt.CreateModifiedRecipe(BOMNo);
        end;
        RefreshTree();
    end;

    local procedure RefreshTree()
    var
        WorkspaceMgt: Codeunit "SI Prok Recipe Workspace Mgt.";
    begin
        CurrPage.RecipeTree.RenderTree(WorkspaceMgt.BuildTreeJson());
    end;

    var
        SelectedType: Text;
        SelectedId: Text;
}
