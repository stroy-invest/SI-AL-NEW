page 50190 "SI Product Selector Test"
{
    PageType = Card;
    ApplicationArea = All;
    Caption = 'Тест вибору продукту';
    UsageCategory = Tasks;

    layout
    {
        area(Content)
        {
            group(Selection)
            {
                Caption = 'Результат вибору';

                field(ItemName; ItemName)
                {
                    ApplicationArea = All;
                    Caption = 'Товар';
                    Editable = false;
                }

                field(VariantName; VariantName)
                {
                    ApplicationArea = All;
                    Caption = 'Варіант';
                    Editable = false;
                }

                field(ProductDisplayName; ProductDisplayName)
                {
                    ApplicationArea = All;
                    Caption = 'Продукт';
                    Editable = false;
                }

                group(TechnicalKeys)
                {
                    Caption = 'Технічні ключі';

                    field(ItemNo; ItemNo)
                    {
                        ApplicationArea = All;
                        Caption = 'Item No.';
                        Editable = false;
                    }

                    field(VariantCode; VariantCode)
                    {
                        ApplicationArea = All;
                        Caption = 'Variant Code';
                        Editable = false;
                    }
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SelectProduct)
            {
                ApplicationArea = All;
                Caption = 'Вибрати продукт';
                Image = SelectLineToApply;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;

                trigger OnAction()
                var
                    ProductSelectorMgt: Codeunit "SI Product Selector Mgt.";
                begin
                    if ProductSelectorMgt.SelectProduct(ItemNo, VariantCode) then begin
                        RefreshDisplayValues();
                        CurrPage.Update(false);
                    end;
                end;
            }

            action(ClearSelection)
            {
                ApplicationArea = All;
                Caption = 'Очистити';
                Image = ClearFilter;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;

                trigger OnAction()
                begin
                    Clear(ItemNo);
                    Clear(VariantCode);
                    Clear(ItemName);
                    Clear(VariantName);
                    Clear(ProductDisplayName);
                    CurrPage.Update(false);
                end;
            }
        }
    }

    var
        ItemNo: Code[20];
        VariantCode: Code[10];
        ItemName: Text[100];
        VariantName: Text[100];
        ProductDisplayName: Text[500];

    local procedure RefreshDisplayValues()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ProductSelectorMgt: Codeunit "SI Product Selector Mgt.";
    begin
        Clear(ItemName);
        Clear(VariantName);

        if (ItemNo <> '') and Item.Get(ItemNo) then begin
            ItemName := Item.Description;
            if ItemName = '' then
                ItemName := Item."No.";
        end;

        if (ItemNo <> '') and (VariantCode <> '') and ItemVariant.Get(ItemNo, VariantCode) then begin
            VariantName := ItemVariant.Description;
            if VariantName = '' then
                VariantName := ItemVariant.Code;
        end;

        ProductDisplayName := ProductSelectorMgt.GetProductDisplayName(ItemNo, VariantCode);
    end;
}
