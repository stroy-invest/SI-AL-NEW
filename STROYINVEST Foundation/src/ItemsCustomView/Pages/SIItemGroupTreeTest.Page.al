page 50180 "SI Item Group Tree Test"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'SI Item Group Tree Test';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Test';

                field(SelectedGroupCode; SelectedGroupCode)
                {
                    ApplicationArea = All;
                    Caption = 'Selected Group Code';
                    Editable = false;
                }

                usercontrol(ItemGroupTree; "SI Item Group Tree")
                {
                    ApplicationArea = All;

                    trigger ControlReady()
                    begin
                        CurrPage.ItemGroupTree.RenderTree(GetTestTreeJson());
                    end;

                    trigger NodeSelected(GroupCode: Text)
                    begin
                        SelectedGroupCode := GroupCode;
                        CurrPage.Update(false);
                    end;
                }
            }
        }
    }

    var
        SelectedGroupCode: Text[50];

    local procedure GetTestTreeJson(): Text
    var
        ItemCategory: Record "Item Category";
    begin
        Clear(ItemCategory);
        ItemCategory.SetRange("Parent Category", '');
        exit(BuildCategoryJson(ItemCategory));
    end;

    local procedure BuildCategoryJson(var ItemCategory: Record "Item Category"): Text
    var
        JsonText: Text;
        IsFirst: Boolean;
    begin
        JsonText := '[';
        IsFirst := true;

        if ItemCategory.FindSet() then
            repeat
                if not IsFirst then
                    JsonText += ',';

                JsonText += BuildCategoryNodeJson(ItemCategory);

                IsFirst := false;
            until ItemCategory.Next() = 0;

        JsonText += ']';

        exit(JsonText);
    end;

    local procedure BuildCategoryNodeJson(ItemCategory: Record "Item Category"): Text
    var
        ChildCategory: Record "Item Category";
        NodeName: Text;
    begin
        NodeName := ItemCategory.Description;
        if NodeName = '' then
            NodeName := ItemCategory.Code;

        ChildCategory.SetRange("Parent Category", ItemCategory.Code);

        exit(
            '{' +
                '"code":"' + JsonEscape(ItemCategory.Code) + '",' +
                '"name":"' + JsonEscape(NodeName) + '",' +
                '"children":' + BuildCategoryJson(ChildCategory) +
            '}'
        );
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
}