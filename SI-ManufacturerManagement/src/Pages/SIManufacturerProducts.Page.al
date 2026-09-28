page 55002 "SI Manufacturer Products"
{
    PageType = List;
    SourceTable = "SI Manufacturer Product";
    ApplicationArea = All;
    UsageCategory = Lists;

    Caption = 'Продукти виробників';

    CardPageId = "SI Manufacturer Product Card";

    layout
    {
        area(Content)
        {
            repeater(Products)
            {
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
}