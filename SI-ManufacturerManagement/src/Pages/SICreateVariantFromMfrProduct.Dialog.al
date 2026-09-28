page 55009 "SI Create Variant from MfrProd"
{
    PageType = StandardDialog;
    ApplicationArea = All;
    Caption = 'Створити варіант товару';

    layout
    {
        area(Content)
        {
            group(Context)
            {
                Caption = 'Вихідні дані';

                field(ItemDisplay; ItemDisplay)
                {
                    ApplicationArea = All;
                    Caption = 'Товар';
                    Editable = false;
                }

                field(ManufacturerName; ManufacturerName)
                {
                    ApplicationArea = All;
                    Caption = 'Виробник';
                    Editable = false;
                }

                field(ManufacturerProductDescription; ManufacturerProductDescription)
                {
                    ApplicationArea = All;
                    Caption = 'Схвалений продукт виробника';
                    Editable = false;
                }
            }

            group(NewVariant)
            {
                Caption = 'Новий варіант';

                field(VariantCode; VariantCode)
                {
                    ApplicationArea = All;
                    Caption = 'Код варіанта';
                    ToolTip = 'Вкажіть код нового варіанта товару. Запропоноване значення можна змінити.';
                }

                field(VariantDescription; VariantDescription)
                {
                    ApplicationArea = All;
                    Caption = 'Назва варіанта';
                    ToolTip = 'Назва нового варіанта. За замовчуванням використовується назва продукту виробника.';
                }
            }
        }
    }

    procedure SetApprovedProduct(ApprovedProduct: Record "SI Approved Manufacturer Prod.")
    var
        Item: Record Item;
        ManufacturerProduct: Record "SI Manufacturer Product";
        Manufacturer: Record "SI Manufacturer";
    begin
        ApprovedProduct.TestField("Item No.");
        ApprovedProduct.TestField("Manufacturer Product Code");

        if Item.Get(ApprovedProduct."Item No.") then begin
            ItemDisplay := Item.Description;
            if ItemDisplay = '' then
                ItemDisplay := Item."No.";
        end else
            ItemDisplay := ApprovedProduct."Item No.";

        if ManufacturerProduct.Get(ApprovedProduct."Manufacturer Product Code") then begin
            ManufacturerProductDescription := ManufacturerProduct.Description;
            if Manufacturer.Get(ManufacturerProduct."Manufacturer Code") then
                ManufacturerName := Manufacturer.Name;

            VariantDescription := ManufacturerProduct.Description;
            VariantCode := BuildSuggestedVariantCode(ManufacturerProduct);
        end;
    end;

    procedure GetVariant(var NewVariantCode: Code[10]; var NewVariantDescription: Text[100])
    begin
        NewVariantCode := VariantCode;
        NewVariantDescription := VariantDescription;
    end;

    local procedure BuildSuggestedVariantCode(ManufacturerProduct: Record "SI Manufacturer Product"): Code[10]
    var
        SourceCode: Text;
        ResultCode: Code[10];
    begin
        SourceCode := ManufacturerProduct."Manufacturer Item No.";
        if SourceCode = '' then
            SourceCode := ManufacturerProduct.Code;

        SourceCode := DelChr(SourceCode, '<>', ' ');
        ResultCode := CopyStr(SourceCode, 1, MaxStrLen(ResultCode));
        exit(ResultCode);
    end;

    var
        ItemDisplay: Text[120];
        ManufacturerName: Text[100];
        ManufacturerProductDescription: Text[100];
        VariantCode: Code[10];
        VariantDescription: Text[100];
}
