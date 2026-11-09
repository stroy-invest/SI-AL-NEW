page 61005 "SI Concrete Supply Spec Part"
{
    PageType = CardPart;
    SourceTable = "SI Concrete Supply Spec";
    ApplicationArea = All;
    Caption = 'Постачання бетону';
    InsertAllowed = true;
    ModifyAllowed = true;

    layout
    {
        area(Content)
        {
            group(Delivery)
            {
                Caption = 'Доставка';
                field("Truck Interval Minutes"; Rec."Truck Interval Minutes") { ApplicationArea = All; Editable = true; }
                field("Delivery Address"; Rec."Delivery Address") { ApplicationArea = All; MultiLine = true; Editable = true; }
                field("Entry Restrictions"; Rec."Entry Restrictions") { ApplicationArea = All; MultiLine = true; Editable = true; }
                field("Access Road Conditions"; Rec."Access Road Conditions") { ApplicationArea = All; MultiLine = true; Editable = true; }
                field("Payment Method Text"; Rec."Payment Method Text") { ApplicationArea = All; Editable = true; }
                field("Special Instructions"; Rec."Special Instructions") { ApplicationArea = All; MultiLine = true; Editable = true; }
            }
            group(Unloading)
            {
                Caption = 'Вивантаження';
                field("Unloading Method"; Rec."Unloading Method") { ApplicationArea = All; Editable = true; }
                field("Concrete Pump Required"; Rec."Concrete Pump Required") { ApplicationArea = All; Editable = true; }
                field("Pump Type"; Rec."Pump Type") { ApplicationArea = All; Editable = true; }
                field("Pump Boom Length"; Rec."Pump Boom Length") { ApplicationArea = All; Editable = true; }
                field("Additional Chute Required"; Rec."Additional Chute Required") { ApplicationArea = All; Editable = true; }
                field("Discharge Pipe Required"; Rec."Discharge Pipe Required") { ApplicationArea = All; Editable = true; }
            }
            group(Contact)
            {
                Caption = 'Контакт';
                field("Contact Name"; Rec."Contact Name") { ApplicationArea = All; Editable = true; }
                field("Contact Phone"; Rec."Contact Phone") { ApplicationArea = All; Editable = true; }
                field("Contact E-Mail"; Rec."Contact E-Mail") { ApplicationArea = All; Editable = true; }
            }
        }
    }
}
