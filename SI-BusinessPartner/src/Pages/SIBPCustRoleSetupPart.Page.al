page 54044 "SI BP Cust. Role Setup Part"
{
    PageType = CardPart;
    SourceTable = "SI BP Cust. Role Setup";

    Caption = 'Налаштування ролі покупця';
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(Setup)
            {
                ShowCaption = false;


                field("Customer Posting Group"; Rec."Customer Posting Group")
                {
                    ApplicationArea = All;
                }

                field("Gen. Bus. Posting Group"; Rec."Gen. Bus. Posting Group")
                {
                    ApplicationArea = All;
                }

                field("VAT Bus. Posting Group"; Rec."VAT Bus. Posting Group")
                {
                    ApplicationArea = All;
                }

                field("Payment Terms Code"; Rec."Payment Terms Code")
                {
                    ApplicationArea = All;
                }

                field("Payment Method Code"; Rec."Payment Method Code")
                {
                    ApplicationArea = All;
                }

                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = All;
                }

                field("Shipment Method Code"; Rec."Shipment Method Code")
                {
                    ApplicationArea = All;
                }

                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}