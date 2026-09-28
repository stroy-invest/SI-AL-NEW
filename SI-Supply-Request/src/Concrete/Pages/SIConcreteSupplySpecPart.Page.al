page 61005 "SI Concrete Supply Spec Part"
{
    PageType = CardPart;
    SourceTable = "SI Concrete Supply Spec";
    ApplicationArea = All;
    Caption = 'Постачання бетону';

    layout
    {
        area(Content)
        {
            group(Delivery)
            {
                Caption = 'Доставка';
                field("Truck Interval Minutes"; Rec."Truck Interval Minutes") { ApplicationArea = All; }
                field("Delivery Address"; Rec."Delivery Address") { ApplicationArea = All; MultiLine = true; }
                field("Entry Restrictions"; Rec."Entry Restrictions") { ApplicationArea = All; MultiLine = true; }
                field("Access Road Conditions"; Rec."Access Road Conditions") { ApplicationArea = All; MultiLine = true; }
                field("Payment Method Text"; Rec."Payment Method Text") { ApplicationArea = All; }
                field("Special Instructions"; Rec."Special Instructions") { ApplicationArea = All; MultiLine = true; }
            }
            group(Unloading)
            {
                Caption = 'Вивантаження';
                field("Unloading Method"; Rec."Unloading Method") { ApplicationArea = All; }
                field("Concrete Pump Required"; Rec."Concrete Pump Required") { ApplicationArea = All; }
                field("Pump Type"; Rec."Pump Type") { ApplicationArea = All; }
                field("Pump Boom Length"; Rec."Pump Boom Length") { ApplicationArea = All; }
                field("Additional Chute Required"; Rec."Additional Chute Required") { ApplicationArea = All; }
                field("Discharge Pipe Required"; Rec."Discharge Pipe Required") { ApplicationArea = All; }
            }
            group(Contact)
            {
                Caption = 'Контакт';
                field("Contact Name"; Rec."Contact Name") { ApplicationArea = All; }
                field("Contact Phone"; Rec."Contact Phone") { ApplicationArea = All; }
                field("Contact E-Mail"; Rec."Contact E-Mail") { ApplicationArea = All; }
            }
        }
    }
}
