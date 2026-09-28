pageextension 50121 "SI Item List Ext." extends "Item List"
{
    actions
    {
        addlast(processing)
        {
            action(SINewItem)
            {
                ApplicationArea = All;
                Caption = 'Новий товар';
                Image = NewItem;
                ToolTip = 'Створити новий товар з автоматично згенерованим номером на основі категорії товару.';

                trigger OnAction()
                var
                    NewItemWizard: Page "SI New Item Wizard";
                    Item: Record Item;
                    ItemCodeMgt: Codeunit "SI Item Code Management";
                    ItemNo: Code[20];
                begin
                    if NewItemWizard.RunModal() <> Action::OK then
                        exit;

                    ItemNo := ItemCodeMgt.GenerateItemNo(NewItemWizard.GetItemCategoryCode());

                    Item.Init();
                    Item."No." := ItemNo;
                    Item.Insert(true);

                    Item.Validate("Item Category Code", NewItemWizard.GetItemCategoryCode());
                    Item.Validate(Description, NewItemWizard.GetItemDescription());
                    Item.Modify(true);

                    Commit();

                    Page.Run(Page::"Item Card", Item);
                end;
            }

            action(SIShowItemTree)
            {
                ApplicationArea = All;
                Caption = 'Показати дерево';
                Image = Hierarchy;
                ToolTip = 'Відкрити ієрархічне подання груп товарів, товарів і варіантів товарів.';

                trigger OnAction()
                begin
                    Page.Run(Page::"SI Item Class. Workspace");
                end;
            }
        }
    }
}