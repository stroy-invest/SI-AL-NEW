page 55003 "SI Manufacturer Product Card"
{
    PageType = Card;
    SourceTable = "SI Manufacturer Product";
    ApplicationArea = All;

    Caption = 'Продукт виробника';

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
                    ToolTip = 'Код продукту виробника.';
                }

                field("Manufacturer Code"; Rec."Manufacturer Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Код виробника продукту.';
                }

                field("Manufacturer Item No."; Rec."Manufacturer Item No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Артикул або SKU продукту у виробника.';
                }

                field("Manufacturer Item Variant No."; Rec."Manufacturer Item Variant No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Артикул або код варіанта продукту у виробника.';
                }

                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    MultiLine = true;
                    ToolTip = 'Комерційна назва продукту виробника.';
                }

                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає, чи заблоковано продукт виробника для подальшого використання.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ApprovedMappings)
            {
                ApplicationArea = All;
                Caption = 'Схвалені зв''язки';
                Image = Link;

                ToolTip = 'Відкрити список зв''язків цього продукту виробника з товарами та варіантами.';

                trigger OnAction()
                var
                    ApprovedManufacturerProd: Record "SI Approved Manufacturer Prod.";
                begin
                    ApprovedManufacturerProd.SetRange(
                        "Manufacturer Product Code",
                        Rec.Code);

                    Page.Run(
                        Page::"SI Approved Mfr. Products",
                        ApprovedManufacturerProd);
                end;
            }
        }
    }
}