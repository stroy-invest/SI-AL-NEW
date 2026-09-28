page 53023 "SI Item Category Tree Select"
{
    PageType = StandardDialog;
    ApplicationArea = All;
    Caption = 'Вибір категорії товару';

    layout
    {
        area(Content)
        {
            group(Selection)
            {
                Caption = 'Вибрана категорія';

                field(SelectedCategoryCodeField; SelectedCategoryCode)
                {
                    ApplicationArea = All;
                    Caption = 'Код';
                    Editable = false;
                    Importance = Promoted;
                }

                field(SelectedCategoryDescriptionField;
                    SelectedCategoryDescription)
                {
                    ApplicationArea = All;
                    Caption = 'Назва';
                    Editable = false;
                    Importance = Promoted;
                }
            }

            usercontrol(CategoryTree; "SI Product Category Tree")
            {
                ApplicationArea = All;

                trigger ControlReady()
                begin
                    CurrPage.CategoryTree.RenderTree(
                        GetCategoryTreeJson());
                end;

                trigger NodeSelected(CategoryCode: Text)
                begin
                    SelectCategory(
                        CopyStr(
                            CategoryCode,
                            1,
                            MaxStrLen(SelectedCategoryCode)));

                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = Action::OK then
            if SelectedCategoryCode = '' then
                Error(CategoryMustBeSelectedErr);

        exit(true);
    end;

    procedure SetSelectedCategory(
        ItemCategoryCode: Code[20])
    begin
        if ItemCategoryCode = '' then
            exit;

        SelectCategory(ItemCategoryCode);
    end;

    procedure GetSelectedCategory(
        var ItemCategoryCode: Code[20];
        var ItemCategoryDescription: Text[100])
    begin
        ItemCategoryCode := SelectedCategoryCode;
        ItemCategoryDescription :=
            SelectedCategoryDescription;
    end;

    local procedure SelectCategory(
        ItemCategoryCode: Code[20])
    var
        ItemCategory: Record "Item Category";
    begin
        ItemCategory.Get(ItemCategoryCode);

        SelectedCategoryCode := ItemCategory.Code;
        SelectedCategoryDescription :=
            ItemCategory.Description;
    end;

    local procedure GetCategoryTreeJson(): Text
    var
        ItemCategory: Record "Item Category";
    begin
        ItemCategory.SetCurrentKey("Parent Category", Code);
        ItemCategory.SetRange("Parent Category", '');

        exit(BuildCategoryJson(ItemCategory));
    end;

    local procedure BuildCategoryJson(
        var ItemCategory: Record "Item Category"): Text
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

                JsonText +=
                    BuildCategoryNodeJson(ItemCategory);
                IsFirst := false;
            until ItemCategory.Next() = 0;

        JsonText += ']';
        exit(JsonText);
    end;

    local procedure BuildCategoryNodeJson(
        ItemCategory: Record "Item Category"): Text
    var
        ChildCategory: Record "Item Category";
        NodeName: Text;
    begin
        NodeName := ItemCategory.Description;

        if NodeName = '' then
            NodeName := ItemCategory.Code;

        ChildCategory.SetCurrentKey(
            "Parent Category",
            Code);
        ChildCategory.SetRange(
            "Parent Category",
            ItemCategory.Code);

        exit(
            '{' +
                '"code":"' +
                    JsonEscape(ItemCategory.Code) +
                    '",' +
                '"name":"' +
                    JsonEscape(NodeName) +
                    '",' +
                '"children":' +
                    BuildCategoryJson(ChildCategory) +
            '}');
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
        SelectedCategoryCode: Code[20];
        SelectedCategoryDescription: Text[100];

        CategoryMustBeSelectedErr: Label
            'Виберіть категорію товару.';
}
