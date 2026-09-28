page 55004 "SI Approved Mfr. Products"
{
    PageType = List;
    SourceTable = "SI Approved Manufacturer Prod.";
    ApplicationArea = All;
    UsageCategory = Lists;

    Caption = 'Схвалені продукти виробників';

    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = true;

    layout
    {
        area(Content)
        {
            repeater(ApprovedProducts)
            {
                field("Item Description"; Rec."Item Description")
                {
                    ApplicationArea = All;
                    Caption = 'Товар';
                    Editable = false;
                    ToolTip = 'Товар, для якого визначено схвалений продукт виробника.';
                }

                field("Variant Description"; Rec."Variant Description")
                {
                    ApplicationArea = All;
                    Caption = 'Варіант';
                    Editable = false;
                    ToolTip = 'Варіант товару, для якого визначено схвалений продукт виробника.';
                }

                field(ManufacturerName; ManufacturerName)
                {
                    ApplicationArea = All;
                    Caption = 'Виробник';
                    Editable = false;
                    ToolTip = 'Виробник схваленого продукту.';
                }

                field("Manufacturer Product Desc."; Rec."Manufacturer Product Desc.")
                {
                    ApplicationArea = All;
                    Caption = 'Продукт виробника';
                    Editable = false;
                    ToolTip = 'Конкретний продукт виробника, схвалений для товару або варіанта.';
                }

                field("Approval Status"; Rec."Approval Status")
                {
                    ApplicationArea = All;
                    Caption = 'Статус схвалення';
                    Editable = false;
                    ToolTip = 'Статус допуску продукту виробника для товару або варіанта.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(AddApprovedProduct)
            {
                ApplicationArea = All;
                Caption = 'Додати схвалений продукт';
                Image = New;
                ToolTip = 'Додати схвалений продукт виробника для товару або варіанта.';

                trigger OnAction()
                var
                    AddApprovedMfrProduct: Page "SI Add Approved Mfr. Product";
                    ApprovedManufacturerProd: Record "SI Approved Manufacturer Prod.";
                    ItemNo: Code[20];
                    VariantCode: Code[10];
                    ManufacturerProductCode: Code[20];
                    ApprovalStatus: Enum "SI Manufacturer Approval";
                begin
                    if AddApprovedMfrProduct.RunModal() <> Action::OK then
                        exit;

                    AddApprovedMfrProduct.GetSelection(
                        ItemNo,
                        VariantCode,
                        ManufacturerProductCode,
                        ApprovalStatus);

                    if ApprovedManufacturerProd.Get(
                        ItemNo,
                        VariantCode,
                        ManufacturerProductCode)
                    then
                        Error(
                            ApprovedProductExistsErr,
                            ItemNo,
                            VariantCode,
                            ManufacturerProductCode);

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

                    ApprovedManufacturerProd.Insert(true);

                    CurrPage.Update(false);
                end;
            }

            action(CreateItemVariant)
            {
                ApplicationArea = All;
                Caption = 'Створити варіант товару';
                Image = New;
                ToolTip = 'Створює стандартний варіант для вибраного товару на підставі схваленого продукту виробника та переносить схвалення на створений варіант.';
                AccessByPermission = tabledata "Item Variant" = I;

                trigger OnAction()
                var
                    CreateVariantDialog: Page "SI Create Variant from MfrProd";
                    ManufacturerMgt: Codeunit "SI Manufacturer Mgt.";
                    VariantCode: Code[10];
                    VariantDescription: Text[100];
                begin
                    if Rec."Variant Code" <> '' then
                        Error(VariantAlreadyAssignedErr, Rec."Variant Code");

                    Rec.TestField(
                        "Approval Status",
                        Rec."Approval Status"::Approved);

                    if ManufacturerMgt.TryLinkExistingVariantFromApprovedProduct(
                        Rec,
                        VariantCode)
                    then begin
                        Message(
                            ExistingVariantLinkedMsg,
                            VariantCode,
                            Rec."Manufacturer Product Desc.");
                        CurrPage.Update(false);
                        exit;
                    end;

                    Clear(VariantCode);
                    CreateVariantDialog.SetApprovedProduct(Rec);
                    if CreateVariantDialog.RunModal() <> Action::OK then
                        exit;

                    CreateVariantDialog.GetVariant(
                        VariantCode,
                        VariantDescription);

                    ManufacturerMgt.CreateVariantFromApprovedProduct(
                        Rec,
                        VariantCode,
                        VariantDescription);

                    CurrPage.Update(false);
                end;
            }

            action(OpenManufacturerProduct)
            {
                ApplicationArea = All;
                Caption = 'Відкрити продукт виробника';
                Image = View;
                ToolTip = 'Відкрити картку продукту виробника для вибраного зв''язку.';

                trigger OnAction()
                var
                    ManufacturerProduct: Record "SI Manufacturer Product";
                begin
                    if not ManufacturerProduct.Get(
                        Rec."Manufacturer Product Code")
                    then
                        exit;

                    Page.Run(
                        Page::"SI Manufacturer Product Card",
                        ManufacturerProduct);
                end;
            }

            action(OpenManufacturer)
            {
                ApplicationArea = All;
                Caption = 'Відкрити виробника';
                Image = View;
                ToolTip = 'Відкрити картку виробника вибраного продукту виробника.';

                trigger OnAction()
                var
                    ManufacturerProduct: Record "SI Manufacturer Product";
                    Manufacturer: Record "SI Manufacturer";
                begin
                    if not ManufacturerProduct.Get(
                        Rec."Manufacturer Product Code")
                    then
                        exit;

                    if not Manufacturer.Get(
                        ManufacturerProduct."Manufacturer Code")
                    then
                        exit;

                    Page.Run(
                        Page::"SI Manufacturer Card",
                        Manufacturer);
                end;
            }
        }

        area(Promoted)
        {
            actionref(AddApprovedProductPromoted; AddApprovedProduct)
            {
            }
            actionref(CreateItemVariantPromoted; CreateItemVariant)
            {
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        LoadManufacturerName();
    end;

    local procedure LoadManufacturerName()
    var
        ManufacturerProduct: Record "SI Manufacturer Product";
        Manufacturer: Record "SI Manufacturer";
    begin
        Clear(ManufacturerName);

        if Rec."Manufacturer Product Code" = '' then
            exit;

        if not ManufacturerProduct.Get(
            Rec."Manufacturer Product Code")
        then
            exit;

        if Manufacturer.Get(
            ManufacturerProduct."Manufacturer Code")
        then
            ManufacturerName :=
                Manufacturer.Name;
    end;

    var
        ManufacturerName: Text[100];

        ApprovedProductExistsErr: Label
            'Для товару %1, варіанта %2 продукт виробника %3 уже додано.';

        VariantAlreadyAssignedErr: Label
            'Для вибраного схваленого продукту вже задано варіант %1.';


        ExistingVariantLinkedMsg: Label
            'Варіант %1 уже був створений для схваленого продукту «%2» через конфігуратор. Новий варіант не створювався; наявний варіант додано до схвалених продуктів.';
}