page 55008 "SI Approved Mfr. Products FB"
{
    PageType = ListPart;
    SourceTable = "SI Approved Manufacturer Prod.";
    ApplicationArea = All;
    Caption = 'Схвалені продукти виробників';

    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    SourceTableView = where("Approval Status" = const(Approved));

    layout
    {
        area(Content)
        {
            repeater(ApprovedProducts)
            {
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
                    ToolTip = 'Конкретний продукт виробника, схвалений для вибраного товару або варіанта.';
                }

                field("Approval Status"; Rec."Approval Status")
                {
                    ApplicationArea = All;
                    Caption = 'Статус';
                    Editable = false;
                }
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

        if not ManufacturerProduct.Get(Rec."Manufacturer Product Code") then
            exit;

        if Manufacturer.Get(ManufacturerProduct."Manufacturer Code") then
            ManufacturerName := Manufacturer.Name;
    end;

    var
        ManufacturerName: Text[100];
}
