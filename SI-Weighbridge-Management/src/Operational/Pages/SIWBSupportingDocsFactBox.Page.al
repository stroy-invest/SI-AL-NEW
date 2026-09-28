page 59103 "SI WB Supporting Docs FactBox"
{
    PageType = CardPart;
    SourceTable = "SI Weighbridge Document";

    ApplicationArea = All;
    UsageCategory = None;

    Caption = 'Супровідні документи';

    layout
    {
        area(Content)
        {
            group(Documents)
            {
                ShowCaption = false;

                field("TTN No."; Rec."TTN No.")
                {
                    ApplicationArea = All;
                    Caption = '№ ТТН';
                }

                field("Vendor Shipment No."; Rec."Vendor Shipment No.")
                {
                    ApplicationArea = All;
                    Caption = '№ видаткової постачальника';
                    Visible = ReceiptVisible;
                }

                field("Delivery Note No."; Rec."Delivery Note No.")
                {
                    ApplicationArea = All;
                    Caption = '№ видаткової накладної';
                    Visible = ShipmentVisible;
                }

                field("Product Passport No."; Rec."Product Passport No.")
                {
                    ApplicationArea = All;
                    Caption = '№ паспорта продукції';
                    Visible = ShipmentVisible;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        ReceiptVisible :=
            Rec."Operation Type" =
            "SI WB Operation Type"::Receipt;

        ShipmentVisible :=
            Rec."Operation Type" =
            "SI WB Operation Type"::Shipment;
    end;

    var
        ReceiptVisible: Boolean;
        ShipmentVisible: Boolean;
}
