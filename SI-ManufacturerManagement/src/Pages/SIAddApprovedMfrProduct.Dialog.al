page 55007 "SI Add Approved Mfr. Product"
{
    PageType = StandardDialog;
    ApplicationArea = All;
    Caption = 'Додати схвалений продукт виробника';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Схвалений продукт виробника';

                field(ItemDescription; ItemDescription)
                {
                    ApplicationArea = All;
                    Caption = 'Товар';
                    Lookup = true;
                    ToolTip = 'Виберіть товар, для якого схвалюється продукт виробника.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Item: Record Item;
                        Items: Page "Item List";
                    begin
                        Items.LookupMode(true);

                        if ItemNo <> '' then
                            if Item.Get(ItemNo) then
                                Items.SetRecord(Item);

                        if Items.RunModal() <> Action::LookupOK then
                            exit(false);

                        Items.GetRecord(Item);

                        if ItemNo <> Item."No." then begin
                            Clear(VariantCode);
                            Clear(VariantDescription);
                        end;

                        ItemNo := Item."No.";
                        ItemDescription := Item.Description;

                        Text := ItemDescription;

                        CurrPage.Update(false);
                        exit(true);
                    end;
                }

                field(VariantDescription; VariantDescription)
                {
                    ApplicationArea = All;
                    Caption = 'Варіант';
                    Lookup = true;
                    ToolTip = 'Виберіть варіант товару. Поле можна залишити порожнім, якщо товар не використовує варіанти.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        ItemVariant: Record "Item Variant";
                        ItemVariants: Page "Item Variants";
                    begin
                        if ItemNo = '' then
                            Error(ItemRequiredBeforeVariantErr);

                        ItemVariant.SetRange(
                            "Item No.",
                            ItemNo);

                        ItemVariants.SetTableView(ItemVariant);
                        ItemVariants.LookupMode(true);

                        if ItemVariants.RunModal() <> Action::LookupOK then
                            exit(false);

                        ItemVariants.GetRecord(ItemVariant);

                        VariantCode := ItemVariant.Code;
                        VariantDescription := ItemVariant.Description;

                        Text := VariantDescription;

                        CurrPage.Update(false);
                        exit(true);
                    end;
                }

                field(ManufacturerProductDescription; ManufacturerProductDescription)
                {
                    ApplicationArea = All;
                    Caption = 'Продукт виробника';
                    Lookup = true;
                    ToolTip = 'Виберіть конкретний продукт виробника.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        ManufacturerProduct: Record "SI Manufacturer Product";
                        ManufacturerProducts: Page "SI Manufacturer Products";
                        Manufacturer: Record "SI Manufacturer";
                    begin
                        ManufacturerProduct.SetRange(
                            Blocked,
                            false);

                        ManufacturerProducts.SetTableView(
                            ManufacturerProduct);
                        ManufacturerProducts.LookupMode(true);

                        if ManufacturerProducts.RunModal() <> Action::LookupOK then
                            exit(false);

                        ManufacturerProducts.GetRecord(
                            ManufacturerProduct);

                        ManufacturerProductCode :=
                            ManufacturerProduct.Code;

                        ManufacturerProductDescription :=
                            ManufacturerProduct.Description;

                        Clear(ManufacturerName);

                        if Manufacturer.Get(
                            ManufacturerProduct."Manufacturer Code")
                        then
                            ManufacturerName :=
                                Manufacturer.Name;

                        Text := ManufacturerProductDescription;

                        CurrPage.Update(false);
                        exit(true);
                    end;
                }

                field(ManufacturerName; ManufacturerName)
                {
                    ApplicationArea = All;
                    Caption = 'Виробник';
                    Editable = false;
                    ToolTip = 'Виробник вибраного продукту виробника.';
                }

                field(ApprovalStatus; ApprovalStatus)
                {
                    ApplicationArea = All;
                    Caption = 'Статус схвалення';
                    ToolTip = 'Визначає статус допуску продукту виробника для вибраного товару або варіанта.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        ApprovalStatus :=
            ApprovalStatus::Approved;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        ApprovedManufacturerProd: Record "SI Approved Manufacturer Prod.";
    begin
        if CloseAction <> Action::OK then
            exit(true);

        if ItemNo = '' then
            Error(ItemRequiredErr);

        if ManufacturerProductCode = '' then
            Error(ManufacturerProductRequiredErr);

        ApprovedManufacturerProd.Init();

        ApprovedManufacturerProd.Validate(
            "Item No.",
            ItemNo);

        if VariantCode <> '' then
            ApprovedManufacturerProd.Validate(
                "Variant Code",
                VariantCode);

        ApprovedManufacturerProd.Validate(
            "Manufacturer Product Code",
            ManufacturerProductCode);

        ApprovedManufacturerProd.Validate(
            "Approval Status",
            ApprovalStatus);

        exit(true);
    end;

    procedure GetSelection(
        var SelectedItemNo: Code[20];
        var SelectedVariantCode: Code[10];
        var SelectedManufacturerProductCode: Code[20];
        var SelectedApprovalStatus: Enum "SI Manufacturer Approval")
    begin
        SelectedItemNo := ItemNo;
        SelectedVariantCode := VariantCode;
        SelectedManufacturerProductCode :=
            ManufacturerProductCode;
        SelectedApprovalStatus :=
            ApprovalStatus;
    end;

    var
        ItemNo: Code[20];
        VariantCode: Code[10];
        ManufacturerProductCode: Code[20];

        ApprovalStatus: Enum "SI Manufacturer Approval";

        ItemDescription: Text[100];
        VariantDescription: Text[100];
        ManufacturerProductDescription: Text[100];
        ManufacturerName: Text[100];

        ItemRequiredErr: Label
            'Необхідно вибрати товар.';

        ItemRequiredBeforeVariantErr: Label
            'Спочатку виберіть товар.';

        ManufacturerProductRequiredErr: Label
            'Необхідно вибрати продукт виробника.';
}