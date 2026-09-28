page 55001 "SI Manufacturer Card"
{
    PageType = Card;
    SourceTable = "SI Manufacturer";
    ApplicationArea = All;

    Caption = 'Виробник';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Загальні відомості';

                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Код виробника.';
                }

                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Назва виробника.';
                }

                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Код країни або регіону виробника.';
                }

                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає, чи заблоковано виробника для подальшого використання.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ManufacturerProducts)
            {
                ApplicationArea = All;
                Caption = 'Продукти виробника';
                Image = Item;

                ToolTip = 'Відкрити список продуктів цього виробника.';

                trigger OnAction()
                var
                    ManufacturerProduct: Record "SI Manufacturer Product";
                begin
                    ManufacturerProduct.SetRange(
                        "Manufacturer Code",
                        Rec.Code);

                    Page.Run(
                        Page::"SI Manufacturer Products",
                        ManufacturerProduct);
                end;
            }

            action(AllowedCategories)
            {
                ApplicationArea = All;
                Caption = 'Дозволені категорії';
                Image = Category;

                ToolTip = 'Відкрити список категорій товарів, для яких цей виробник дозволений.';

                trigger OnAction()
                var
                    CategoryManufacturer: Record "SI Category Manufacturer";
                begin
                    CategoryManufacturer.SetRange(
                        "Manufacturer Code",
                        Rec.Code);

                    Page.Run(
                        Page::"SI Category Manufacturers",
                        CategoryManufacturer);
                end;
            }
        }
    }
}