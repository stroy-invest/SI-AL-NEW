pageextension 53020 "SI Product Family ERP Ext." extends "SI Product Family Card"
{
    actions
    {
        addafter(Parameters)
        {
            action(ItemCategory)
            {
                ApplicationArea = All;
                Caption = 'Категорія товару BC';
                Image = Category;
                ToolTip = 'Відкриває стандартну категорію товару, пов’язану із сімейством.';

                trigger OnAction()
                var
                    ItemCategory: Record "Item Category";
                begin
                    Rec.TestField("Item Category Code");
                    ItemCategory.Get(Rec."Item Category Code");
                    Page.Run(Page::"Item Category Card", ItemCategory);
                end;
            }
        }

        addlast(Promoted)
        {
            actionref(ItemCategoryPromoted; ItemCategory)
            {
            }
        }
    }
}
