namespace STROYINVEST.ConcreteRecipeEngine;

using Microsoft.Inventory.Item;

page 62106 "SI Recipe Product Selector"
{
    PageType = Card;
    Caption = 'Вибір бетонної продукції';
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(ProductSelection)
            {
                Caption = 'Продукція з бетону';

                usercontrol(ProductTree; "SI Product Tree")
                {
                    ApplicationArea = All;

                    trigger ControlReady()
                    begin
                        EnsureRootCategory();
                        CurrPage.ProductTree.RenderProducts(GetProductTreeJson(RootCategoryCode));
                    end;

                    trigger ProductSelected(NodeType: Text; ItemNo: Text; VariantCode: Text)
                    begin
                        SetSelection(NodeType, ItemNo, VariantCode);
                    end;

                    trigger ProductOpenRequested(NodeType: Text; ItemNo: Text; VariantCode: Text)
                    begin
                        SetSelection(NodeType, ItemNo, VariantCode);
                        ConfirmSelection();
                    end;
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
                Caption = 'Вибрати';
                ApplicationArea = All;
                Image = SelectLineToApply;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;

                trigger OnAction()
                begin
                    ConfirmSelection();
                end;
            }
        }
    }

    procedure GetSelection(var ItemNo: Code[20]; var VariantCode: Code[10]): Boolean
    begin
        if not SelectionConfirmed then
            exit(false);

        ItemNo := SelectedItemNo;
        VariantCode := SelectedVariantCode;
        exit(ItemNo <> '');
    end;

    local procedure EnsureRootCategory()
    var
        RecipeCreationMgt: Codeunit "SI Recipe Creation Mgt.";
    begin
        if RootCategoryCode = '' then
            RootCategoryCode := RecipeCreationMgt.GetConcreteRootCategoryCode();
    end;

    local procedure SetSelection(NodeType: Text; ItemNo: Text; VariantCode: Text)
    begin
        Clear(SelectedItemNo);
        Clear(SelectedVariantCode);

        case NodeType of
            'Item':
                SelectedItemNo := CopyStr(ItemNo, 1, MaxStrLen(SelectedItemNo));
            'Variant':
                begin
                    SelectedItemNo := CopyStr(ItemNo, 1, MaxStrLen(SelectedItemNo));
                    SelectedVariantCode := CopyStr(VariantCode, 1, MaxStrLen(SelectedVariantCode));
                end;
        end;
    end;

    local procedure ConfirmSelection()
    begin
        if SelectedItemNo = '' then
            Error(SelectProductErr);

        SelectionConfirmed := true;
        CurrPage.Close();
    end;

    local procedure GetProductTreeJson(ItemCategoryCode: Code[20]): Text
    var
        JsonText: Text;
        IsFirstItem: Boolean;
    begin
        JsonText := '[';
        IsFirstItem := true;
        AppendCategoryProducts(ItemCategoryCode, JsonText, IsFirstItem, 0);
        JsonText += ']';
        exit(JsonText);
    end;

    local procedure AppendCategoryProducts(ItemCategoryCode: Code[20]; var JsonText: Text; var IsFirstItem: Boolean; Depth: Integer)
    var
        Item: Record Item;
        ChildCategory: Record "Item Category";
    begin
        if Depth > 100 then
            Error(CategoryHierarchyTooDeepErr);

        Item.SetRange("Item Category Code", ItemCategoryCode);
        Item.SetRange(Blocked, false);
        Item.SetCurrentKey("Item Category Code", "No.");
        if Item.FindSet() then
            repeat
                if not IsFirstItem then
                    JsonText += ',';

                JsonText += BuildProductNodeJson(Item);
                IsFirstItem := false;
            until Item.Next() = 0;

        ChildCategory.SetRange("Parent Category", ItemCategoryCode);
        if ChildCategory.FindSet() then
            repeat
                AppendCategoryProducts(ChildCategory.Code, JsonText, IsFirstItem, Depth + 1);
            until ChildCategory.Next() = 0;
    end;

    local procedure BuildProductNodeJson(Item: Record Item): Text
    var
        ItemVariant: Record "Item Variant";
        ItemName: Text;
        VariantsJson: Text;
        IsFirstVariant: Boolean;
    begin
        ItemName := Item.Description;
        if ItemName = '' then
            ItemName := Item."No.";

        VariantsJson := '[';
        IsFirstVariant := true;

        ItemVariant.SetRange("Item No.", Item."No.");
        ItemVariant.SetCurrentKey("Item No.", Code);
        if ItemVariant.FindSet() then
            repeat
                if not IsFirstVariant then
                    VariantsJson += ',';

                VariantsJson +=
                    '{' +
                        '"variantCode":"' + JsonEscape(ItemVariant.Code) + '",' +
                        '"name":"' + JsonEscape(GetVariantDisplayName(ItemVariant)) + '"' +
                    '}';
                IsFirstVariant := false;
            until ItemVariant.Next() = 0;

        VariantsJson += ']';

        exit(
            '{' +
                '"itemNo":"' + JsonEscape(Item."No.") + '",' +
                '"name":"' + JsonEscape(ItemName) + '",' +
                '"baseUomCode":"' + JsonEscape(Item."Base Unit of Measure") + '",' +
                '"children":' + VariantsJson +
            '}');
    end;

    local procedure GetVariantDisplayName(ItemVariant: Record "Item Variant"): Text
    begin
        if ItemVariant.Description <> '' then
            exit(ItemVariant.Description);

        exit(ItemVariant.Code);
    end;

    local procedure JsonEscape(Value: Text): Text
    begin
        Value := Value.Replace('\', '\\');
        Value := Value.Replace('"', '\"');
        Value := Value.Replace('/', '\/');
        Value := Value.Replace('<', '\u003C');
        Value := Value.Replace('>', '\u003E');
        Value := Value.Replace('&', '\u0026');
        exit(Value);
    end;

    var
        RootCategoryCode: Code[20];
        SelectedItemNo: Code[20];
        SelectedVariantCode: Code[10];
        SelectionConfirmed: Boolean;
        SelectProductErr: Label 'Виберіть товар або його варіант.';
        CategoryHierarchyTooDeepErr: Label 'Ієрархія категорій товарів надто глибока або містить циклічне посилання.';
}
