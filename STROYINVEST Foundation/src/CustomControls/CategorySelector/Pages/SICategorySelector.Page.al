page 50191 "SI Category Selector"
{
    PageType = NavigatePage;
    ApplicationArea = All;
    Caption = 'Вибір категорії товару';
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(CategoryArea)
            {
                Caption = 'Категорія';

                field(SelectedCategoryName; SelectedCategoryName)
                {
                    ApplicationArea = All;
                    Caption = 'Вибрана категорія';
                    Editable = false;
                }

                usercontrol(ItemGroupTree; "SI Item Group Tree")
                {
                    ApplicationArea = All;

                    trigger ControlReady()
                    begin
                        TreeReady := true;
                        CurrPage.ItemGroupTree.SetSelectionMode(true);
                        CurrPage.ItemGroupTree.RenderTree(CategorySelectorMgt.GetCategoryTreeJson());
                        RestoreInitialSelection();
                    end;

                    trigger NodeSelected(GroupCode: Text)
                    begin
                        SelectedCategoryCode := CopyStr(GroupCode, 1, MaxStrLen(SelectedCategoryCode));
                        SelectedCategoryName := CategorySelectorMgt.GetCategoryDisplayName(SelectedCategoryCode);
                        CurrPage.Update(false);
                    end;

                    trigger NodeOpenRequested(GroupCode: Text)
                    begin
                    end;

                    trigger AddCategoryRequested(GroupCode: Text)
                    begin
                    end;

                    trigger DeleteCategoryRequested(GroupCode: Text)
                    begin
                    end;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(CancelSelection)
            {
                ApplicationArea = All;
                Caption = 'Скасувати';
                Image = Cancel;
                InFooterBar = true;

                trigger OnAction()
                begin
                    SelectionAccepted := false;
                    CurrPage.Close();
                end;
            }

            action(SelectCategory)
            {
                ApplicationArea = All;
                Caption = 'Вибрати';
                Image = SelectLineToApply;
                InFooterBar = true;
                Enabled = SelectedCategoryCode <> '';

                trigger OnAction()
                begin
                    if SelectedCategoryCode = '' then
                        Error('Виберіть категорію товару.');
                    SelectionAccepted := true;
                    CurrPage.Close();
                end;
            }
        }
    }

    var
        SelectedCategoryCode: Code[20];
        SelectedCategoryName: Text[250];
        InitialCategoryCode: Code[20];
        TreeReady: Boolean;
        SelectionAccepted: Boolean;
        CategorySelectorMgt: Codeunit "SI Category Selector Mgt.";

    procedure SetInitialSelection(CategoryCode: Code[20])
    begin
        InitialCategoryCode := CategoryCode;
        SelectedCategoryCode := CategoryCode;
        SelectedCategoryName := CategorySelectorMgt.GetCategoryDisplayName(CategoryCode);
    end;

    local procedure RestoreInitialSelection()
    begin
        if TreeReady and (InitialCategoryCode <> '') then
            CurrPage.ItemGroupTree.SelectNode(InitialCategoryCode);
    end;
    procedure TryGetSelection(var CategoryCode: Code[20]): Boolean
    begin
        if not SelectionAccepted then
            exit(false);

        CategoryCode := SelectedCategoryCode;
        exit(CategoryCode <> '');
    end;

}
