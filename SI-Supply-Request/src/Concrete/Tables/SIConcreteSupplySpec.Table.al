table 61004 "SI Concrete Supply Spec"
{
    Caption = 'Параметри постачання бетону';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Request No."; Code[20])
        {
            Caption = '№ заявки';
            TableRelation = "SI Supply Req Header"."No.";
        }
        field(10; "Truck Interval Minutes"; Integer)
        {
            Caption = 'Інтервал між машинами, хв';
            MinValue = 0;
        }
        field(20; "Delivery Address"; Text[250]) { Caption = 'Адреса доставки'; }
        field(30; "Entry Restrictions"; Text[250]) { Caption = 'Обмеження в''їзду'; }
        field(40; "Access Road Conditions"; Text[250]) { Caption = 'Стан / умови під''їзду'; }
        field(50; "Unloading Method"; Enum "SI Concrete Unloading Method") { Caption = 'Спосіб вивантаження'; }
        field(60; "Concrete Pump Required"; Boolean) { Caption = 'Потрібен бетононасос'; }
        field(70; "Pump Type"; Enum "SI Concrete Pump Type") { Caption = 'Тип бетононасоса'; }
        field(80; "Pump Boom Length"; Decimal)
        {
            Caption = 'Довжина стріли / траси, м';
            DecimalPlaces = 0 : 2;
            MinValue = 0;
        }
        field(90; "Additional Chute Required"; Boolean) { Caption = 'Потрібен додатковий жолоб'; }
        field(100; "Discharge Pipe Required"; Boolean) { Caption = 'Потрібна розвантажувальна труба'; }
        field(110; "Contact Name"; Text[100]) { Caption = 'Контактна особа'; }
        field(120; "Contact Phone"; Text[50]) { Caption = 'Телефон'; }
        field(130; "Contact E-Mail"; Text[100]) { Caption = 'E-mail'; }
        field(140; "Special Instructions"; Text[250]) { Caption = 'Особливі умови доставки'; }
        field(150; "Payment Method Text"; Text[100]) { Caption = 'Умови оплати'; }
    }

    keys
    {
        key(PK; "Request No.") { Clustered = true; }
    }

    trigger OnInsert()
    begin
        TestHeaderEditable();
    end;

    trigger OnModify()
    begin
        TestHeaderEditable();
    end;

    trigger OnDelete()
    begin
        TestHeaderEditable();
    end;

    local procedure TestHeaderEditable()
    var
        Header: Record "SI Supply Req Header";
    begin
        if Header.Get("Request No.") then
            Header.TestEditable();
    end;
}
