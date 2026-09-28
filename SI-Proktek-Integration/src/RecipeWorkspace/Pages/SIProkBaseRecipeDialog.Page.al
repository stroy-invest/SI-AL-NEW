page 57026 "SI Prok Base Recipe Dialog"
{
    PageType = StandardDialog;
    Caption = 'Створення базової рецептури';

    layout
    {
        area(Content)
        {
            group(Recipe)
            {
                Caption = 'Базова рецептура';
                field(ItemNo; ItemNo)
                {
                    ApplicationArea = All;
                    Caption = 'Товар';
                    TableRelation = Item."No.";
                    trigger OnValidate()
                    begin
                        Clear(VariantCode);
                        SuggestBOMNo();
                    end;
                }
                field(VariantCode; VariantCode)
                {
                    ApplicationArea = All;
                    Caption = 'Варіант';
                    TableRelation = "Item Variant".Code;
                    trigger OnValidate()
                    begin
                        SuggestBOMNo();
                    end;
                }
                field(BOMNo; BOMNo)
                {
                    ApplicationArea = All;
                    Caption = 'Код рецептури';
                }
                field(Description; Description)
                {
                    ApplicationArea = All;
                    Caption = 'Назва рецептури';
                }
            }
        }
    }

    procedure GetValues(var NewItemNo: Code[20]; var NewVariantCode: Code[10]; var NewBOMNo: Code[20]; var NewDescription: Text[100])
    begin
        NewItemNo := ItemNo;
        NewVariantCode := VariantCode;
        NewBOMNo := BOMNo;
        NewDescription := Description;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
    begin
        if CloseAction <> Action::OK then
            exit(true);
        if ItemNo = '' then
            Error('Виберіть товар.');
        if BOMNo = '' then
            Error('Вкажіть код рецептури.');
        Item.Get(ItemNo);
        if VariantCode <> '' then begin
            ItemVariant.Get(ItemNo, VariantCode);
            if Description = '' then
                Description := ItemVariant.Description;
        end else
            if Description = '' then
                Description := Item.Description;
        exit(true);
    end;

    local procedure SuggestBOMNo()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        RawCode: Text;
    begin
        if ItemNo = '' then
            exit;
        RawCode := 'BOM-' + ItemNo;
        if VariantCode <> '' then
            RawCode += '-' + VariantCode;
        BOMNo := CopyStr(RawCode, 1, MaxStrLen(BOMNo));
        if VariantCode <> '' then begin
            if ItemVariant.Get(ItemNo, VariantCode) then
                Description := ItemVariant.Description;
        end else
            if Item.Get(ItemNo) then
                Description := Item.Description;
    end;

    var
        ItemNo: Code[20];
        VariantCode: Code[10];
        BOMNo: Code[20];
        Description: Text[100];
}
