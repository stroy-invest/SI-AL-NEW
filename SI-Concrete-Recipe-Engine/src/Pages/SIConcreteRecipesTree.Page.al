namespace STROYINVEST.ConcreteRecipeEngine;

page 62109 "SI Concrete Recipes Tree"
{
    PageType = Card;
    Caption = 'Рецептури бетону';
    ApplicationArea = All;
    UsageCategory = Lists;
    Editable = false;

    layout
    {
        area(Content)
        {
            group(RecipeHierarchy)
            {
                Caption = 'Ієрархія рецептур';

                usercontrol(RecipeTree; "SI Recipe Tree")
                {
                    ApplicationArea = All;

                    trigger ControlReady()
                    begin
                        TreeReady := true;
                        RenderTree();
                    end;

                    trigger NodeSelected(NodeType: Text; RecipeNo: Text)
                    begin
                        SelectedNodeType := CopyStr(NodeType, 1, MaxStrLen(SelectedNodeType));
                        SelectedRecipeNo := CopyStr(RecipeNo, 1, MaxStrLen(SelectedRecipeNo));
                        UpdateSelection();
                    end;

                    trigger NodeOpen(RecipeNo: Text)
                    var
                        WorkspaceMgt: Codeunit "SI Recipe Workspace Mgt.";
                    begin
                        WorkspaceMgt.OpenRecipe(CopyStr(RecipeNo, 1, MaxStrLen(SelectedRecipeNo)));
                        RefreshWorkspace();
                    end;
                }
            }

            group(BaseRecipeRevisions)
            {
                Caption = 'Ревізії базової рецептури';

                usercontrol(BaseRevisions; "SI Recipe Revision Grid")
                {
                    ApplicationArea = All;

                    trigger ControlReady()
                    begin
                        BaseGridReady := true;
                        RenderRevisionGrids();
                    end;

                    trigger RevisionOpen(RecipeNo: Text; RevisionNo: Integer)
                    var
                        WorkspaceMgt: Codeunit "SI Recipe Workspace Mgt.";
                    begin
                        WorkspaceMgt.OpenRevision(
                            CopyStr(RecipeNo, 1, MaxStrLen(BaseRecipeNo)),
                            RevisionNo);
                        RefreshWorkspace();
                    end;

                    trigger BOMVersionOpen(RecipeNo: Text; RevisionNo: Integer)
                    var
                        WorkspaceMgt: Codeunit "SI Recipe Workspace Mgt.";
                    begin
                        WorkspaceMgt.OpenBOMVersion(
                            CopyStr(RecipeNo, 1, MaxStrLen(BaseRecipeNo)),
                            RevisionNo);
                        RefreshWorkspace();
                    end;
                }
            }

            group(VariantRecipeRevisions)
            {
                Caption = 'Ревізії рецептури варіанта';

                usercontrol(VariantRevisions; "SI Recipe Revision Grid")
                {
                    ApplicationArea = All;

                    trigger ControlReady()
                    begin
                        VariantGridReady := true;
                        RenderRevisionGrids();
                    end;

                    trigger RevisionOpen(RecipeNo: Text; RevisionNo: Integer)
                    var
                        WorkspaceMgt: Codeunit "SI Recipe Workspace Mgt.";
                    begin
                        WorkspaceMgt.OpenRevision(
                            CopyStr(RecipeNo, 1, MaxStrLen(VariantRecipeNo)),
                            RevisionNo);
                        RefreshWorkspace();
                    end;

                    trigger BOMVersionOpen(RecipeNo: Text; RevisionNo: Integer)
                    var
                        WorkspaceMgt: Codeunit "SI Recipe Workspace Mgt.";
                    begin
                        WorkspaceMgt.OpenBOMVersion(
                            CopyStr(RecipeNo, 1, MaxStrLen(VariantRecipeNo)),
                            RevisionNo);
                        RefreshWorkspace();
                    end;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            group(ViewMode)
            {
                Caption = 'Переглянути';

                action(TreeView)
                {
                    Caption = 'Дерево';
                    ApplicationArea = All;
                    Image = Hierarchy;
                    Enabled = false;
                }

                action(ListView)
                {
                    Caption = 'Список';
                    ApplicationArea = All;
                    Image = List;

                    trigger OnAction()
                    begin
                        Page.Run(Page::"SI Concrete Recipes");
                    end;
                }
            }

            action(RefreshWorkspaceAction)
            {
                Caption = 'Оновити';
                ApplicationArea = All;
                Image = Refresh;
                ToolTip = 'Оновлює дерево рецептур і обидва гріди ревізій із Business Central без перезавантаження сторінки браузера.';

                trigger OnAction()
                begin
                    RefreshWorkspace();
                end;
            }

            group(TreeActions)
            {
                Caption = 'Дерево';

                action(ExpandAll)
                {
                    Caption = 'Розгорнути все';
                    ApplicationArea = All;
                    Image = ExpandAll;

                    trigger OnAction()
                    begin
                        if TreeReady then
                            CurrPage.RecipeTree.ExpandAll();
                    end;
                }

                action(CollapseAll)
                {
                    Caption = 'Згорнути все';
                    ApplicationArea = All;
                    Image = CollapseAll;

                    trigger OnAction()
                    begin
                        if TreeReady then
                            CurrPage.RecipeTree.CollapseAll();
                    end;
                }
            }

            group(RecipeActions)
            {
                Caption = 'Рецептура';

                action(ViewRecipe)
                {
                    Caption = 'Переглянути';
                    ApplicationArea = All;
                    Image = View;
                    Enabled = RecipeSelected;

                    trigger OnAction()
                    var
                        WorkspaceMgt: Codeunit "SI Recipe Workspace Mgt.";
                    begin
                        WorkspaceMgt.OpenRecipe(SelectedRecipeNo);
                        RefreshWorkspace();
                    end;
                }

                action(CreateRecipe)
                {
                    Caption = 'Створити';
                    ApplicationArea = All;
                    Image = New;

                    trigger OnAction()
                    var
                        ProductSelector: Page "SI Recipe Product Selector";
                        RecipeCreationMgt: Codeunit "SI Recipe Creation Mgt.";
                        RecipeRevision: Record "SI Concrete Recipe Revision";
                        ItemNo: Code[20];
                        VariantCode: Code[10];
                    begin
                        ProductSelector.RunModal();
                        if not ProductSelector.GetSelection(ItemNo, VariantCode) then
                            exit;

                        RecipeCreationMgt.GetOrCreateDraftRevision(
                            ItemNo,
                            VariantCode,
                            RecipeRevision);
                        SelectedRecipeNo := RecipeRevision."Recipe No.";
                        SelectedNodeType := 'Recipe';
                        UpdateSelection();
                        RenderTree();

                        // The recipe/revision creation above performs database writes.
                        // End that transaction before opening a modal page; Business Central
                        // forbids Page.RunModal while a write transaction is active.
                        Commit();
                        Page.RunModal(Page::"SI Recipe Revision Card", RecipeRevision);
                        RefreshWorkspace();
                    end;
                }
            }
        }

        area(Promoted)
        {
            group(ViewPromoted)
            {
                Caption = 'Переглянути';

                actionref(TreeViewPromoted; TreeView) { }
                actionref(ListViewPromoted; ListView) { }
                actionref(RefreshWorkspacePromoted; RefreshWorkspaceAction) { }
            }

            group(TreePromoted)
            {
                Caption = 'Дерево';

                actionref(ExpandAllPromoted; ExpandAll) { }
                actionref(CollapseAllPromoted; CollapseAll) { }
            }

            group(RecipePromoted)
            {
                Caption = 'Рецептура';

                actionref(ViewRecipePromoted; ViewRecipe) { }
                actionref(CreateRecipePromoted; CreateRecipe) { }
            }
        }
    }

    local procedure UpdateSelection()
    var
        WorkspaceMgt: Codeunit "SI Recipe Workspace Mgt.";
    begin
        RecipeSelected := SelectedRecipeNo <> '';
        WorkspaceMgt.ResolveSelection(
            SelectedRecipeNo,
            BaseRecipeNo,
            VariantRecipeNo);
        RenderRevisionGrids();
    end;

    local procedure RenderTree()
    var
        WorkspaceMgt: Codeunit "SI Recipe Workspace Mgt.";
    begin
        if not TreeReady then
            exit;
        CurrPage.RecipeTree.RenderTree(WorkspaceMgt.BuildRecipeTreeJson());
        if SelectedRecipeNo <> '' then
            CurrPage.RecipeTree.SelectRecipe(SelectedRecipeNo);
    end;

    local procedure RefreshWorkspace()
    begin
        RenderTree();
        RenderRevisionGrids();
    end;

    local procedure RenderRevisionGrids()
    var
        WorkspaceMgt: Codeunit "SI Recipe Workspace Mgt.";
    begin
        if BaseGridReady then
            CurrPage.BaseRevisions.RenderRows(
                WorkspaceMgt.BuildRevisionGridJson(
                    BaseRecipeNo,
                    BaseEmptyTxt));

        if VariantGridReady then
            CurrPage.VariantRevisions.RenderRows(
                WorkspaceMgt.BuildRevisionGridJson(
                    VariantRecipeNo,
                    VariantEmptyTxt));
    end;

    var
        SelectedRecipeNo: Code[50];
        BaseRecipeNo: Code[50];
        VariantRecipeNo: Code[50];
        SelectedNodeType: Text[20];
        TreeReady: Boolean;
        BaseGridReady: Boolean;
        VariantGridReady: Boolean;
        RecipeSelected: Boolean;
        BaseEmptyTxt: Label 'Виберіть базову рецептуру або варіант, щоб показати ревізії базової рецептури.';
        VariantEmptyTxt: Label 'Виберіть рецептуру варіанта, щоб показати її ревізії.';
}
