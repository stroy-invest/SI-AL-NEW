page 55006 "SI Add Category Manufacturer"
{
    PageType = StandardDialog;
    ApplicationArea = All;
    Caption = 'Додати дозволеного виробника';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Дозволений виробник категорії';

                field(ItemCategoryDescription; ItemCategoryDescription)
                {
                    ApplicationArea = All;
                    Caption = 'Категорія товару';
                    AssistEdit = true;
                    ToolTip = 'Виберіть категорію товару через єдиний селектор категорій STROYINVEST.';

                    trigger OnAssistEdit()
                    var
                        CategorySelector: Codeunit "SI Category Selector Mgt.";
                    begin
                        if not CategorySelector.SelectCategory(ItemCategoryCode) then
                            exit;

                        ItemCategoryDescription := CategorySelector.GetCategoryDisplayName(ItemCategoryCode);
                        CurrPage.Update(false);
                    end;

                    trigger OnValidate()
                    var
                        CategorySelector: Codeunit "SI Category Selector Mgt.";
                    begin
                        ItemCategoryDescription := CategorySelector.GetCategoryDisplayName(ItemCategoryCode);
                    end;
                }

                field(ManufacturerName; ManufacturerName)
                {
                    ApplicationArea = All;
                    Caption = 'Виробник';
                    Lookup = true;
                    ToolTip = 'Виберіть виробника, дозволеного для цієї категорії товарів.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Manufacturer: Record "SI Manufacturer";
                        Manufacturers: Page "SI Manufacturers";
                    begin
                        Manufacturer.SetRange(Blocked, false);

                        Manufacturers.SetTableView(Manufacturer);
                        Manufacturers.LookupMode(true);

                        if ManufacturerCode <> '' then begin
                            Manufacturer.Reset();

                            if Manufacturer.Get(ManufacturerCode) then
                                Manufacturers.SetRecord(Manufacturer);
                        end;

                        if Manufacturers.RunModal() <> Action::LookupOK then
                            exit(false);

                        Manufacturers.GetRecord(Manufacturer);

                        ManufacturerCode := Manufacturer.Code;
                        ManufacturerName := Manufacturer.Name;

                        Text := ManufacturerName;

                        CurrPage.Update(false);
                        exit(true);
                    end;
                }
            }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = Action::OK then begin
            if ItemCategoryCode = '' then
                Error(ItemCategoryRequiredErr);

            if ManufacturerCode = '' then
                Error(ManufacturerRequiredErr);
        end;

        exit(true);
    end;

    procedure GetSelection(
        var SelectedItemCategoryCode: Code[20];
        var SelectedManufacturerCode: Code[20])
    begin
        SelectedItemCategoryCode := ItemCategoryCode;
        SelectedManufacturerCode := ManufacturerCode;
    end;

    var
        ItemCategoryCode: Code[20];
        ManufacturerCode: Code[20];

        ItemCategoryDescription: Text[100];
        ManufacturerName: Text[100];

        ItemCategoryRequiredErr: Label
            'Необхідно вибрати категорію товару.';

        ManufacturerRequiredErr: Label
            'Необхідно вибрати виробника.';
}