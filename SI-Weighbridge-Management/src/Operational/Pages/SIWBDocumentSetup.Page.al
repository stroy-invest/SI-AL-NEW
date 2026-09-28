page 59120 "SI WB Document Setup"
{
    Caption = 'Налаштування документів вагової';
    PageType = Card;
    SourceTable = "SI WB Document Setup";
    ApplicationArea = All;
    UsageCategory = Administration;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(Numbering)
            {
                Caption = 'Нумерація первинних документів';

                field("TTN Nos."; Rec."TTN Nos.")
                {
                    ApplicationArea = All;
                }

                field("Delivery Note Nos."; Rec."Delivery Note Nos.")
                {
                    ApplicationArea = All;
                }

                field("Product Passport Nos."; Rec."Product Passport Nos.")
                {
                    ApplicationArea = All;
                }

                field("Internal Transfer Nos."; Rec."Internal Transfer Nos.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Зарезервовано для майбутнього маршруту Shipment + Internal Transfer.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.GetOrCreate();
    end;
}
