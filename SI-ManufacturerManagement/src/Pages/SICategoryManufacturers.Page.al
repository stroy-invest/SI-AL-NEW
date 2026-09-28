page 55005 "SI Category Manufacturers"
{
    PageType = List;
    SourceTable = "SI Category Manufacturer";
    ApplicationArea = All;
    UsageCategory = Lists;

    Caption = 'Дозволені виробники категорій';

    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = true;

    layout
    {
        area(Content)
        {
            repeater(CategoryManufacturers)
            {
                field("Item Category Description"; Rec."Item Category Description")
                {
                    ApplicationArea = All;
                    Caption = 'Категорія товару';
                    Editable = false;
                    ToolTip = 'Категорія товару, для якої дозволено виробника.';
                }

                field("Manufacturer Name"; Rec."Manufacturer Name")
                {
                    ApplicationArea = All;
                    Caption = 'Виробник';
                    Editable = false;
                    ToolTip = 'Виробник, дозволений для цієї категорії товарів.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(AddCategoryManufacturer)
            {
                ApplicationArea = All;
                Caption = 'Додати виробника';
                Image = New;
                ToolTip = 'Додати дозволеного виробника для вибраної категорії товару.';

                trigger OnAction()
                var
                    AddCategoryManufacturer: Page "SI Add Category Manufacturer";
                    CategoryManufacturer: Record "SI Category Manufacturer";
                    ItemCategoryCode: Code[20];
                    ManufacturerCode: Code[20];
                begin
                    if AddCategoryManufacturer.RunModal() <> Action::OK then
                        exit;

                    AddCategoryManufacturer.GetSelection(
                        ItemCategoryCode,
                        ManufacturerCode);

                    if CategoryManufacturer.Get(
                        ItemCategoryCode,
                        ManufacturerCode)
                    then
                        Error(
                            CategoryManufacturerExistsErr,
                            ItemCategoryCode,
                            ManufacturerCode);

                    CategoryManufacturer.Init();
                    CategoryManufacturer.Validate(
                        "Item Category Code",
                        ItemCategoryCode);
                    CategoryManufacturer.Validate(
                        "Manufacturer Code",
                        ManufacturerCode);
                    CategoryManufacturer.Insert(true);

                    CurrPage.Update(false);
                end;
            }

            action(OpenManufacturer)
            {
                ApplicationArea = All;
                Caption = 'Відкрити виробника';
                Image = View;
                ToolTip = 'Відкрити картку вибраного виробника.';

                trigger OnAction()
                var
                    Manufacturer: Record "SI Manufacturer";
                begin
                    if not Manufacturer.Get(
                        Rec."Manufacturer Code")
                    then
                        exit;

                    Page.Run(
                        Page::"SI Manufacturer Card",
                        Manufacturer);
                end;
            }

            action(OpenItemCategory)
            {
                ApplicationArea = All;
                Caption = 'Відкрити категорію';
                Image = View;
                ToolTip = 'Відкрити картку вибраної категорії товару.';

                trigger OnAction()
                var
                    ItemCategory: Record "Item Category";
                begin
                    if not ItemCategory.Get(
                        Rec."Item Category Code")
                    then
                        exit;

                    Page.Run(
                        Page::"Item Category Card",
                        ItemCategory);
                end;
            }
        }

        area(Promoted)
        {
            actionref(AddCategoryManufacturerPromoted; AddCategoryManufacturer)
            {
            }
        }
    }

    var
        CategoryManufacturerExistsErr: Label
            'Виробник %2 уже дозволений для категорії товару %1.';
}