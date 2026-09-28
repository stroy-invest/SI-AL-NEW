table 54043 "SI BP Cust. Role Setup"
{
    Caption = 'Налаштування ролі покупця';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Role Code"; Code[30])
        {
            Caption = 'Код ролі';
            TableRelation = "SI BP Role".Code;
        }

        field(2; "Business Partner No."; Code[20])
        {
            Caption = 'Контрагент';
            TableRelation = "SI Business Partner"."No.";
            Editable = false;
        }


        field(10; "Customer Posting Group"; Code[20])
        {
            Caption = 'Група обліку покупця';
            TableRelation = "Customer Posting Group".Code;
        }

        field(11; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Бізнес-група обліку';
            TableRelation = "Gen. Business Posting Group".Code;
        }

        field(12; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'Бізнес-група ПДВ';
            TableRelation = "VAT Business Posting Group".Code;
        }

        field(20; "Payment Terms Code"; Code[10])
        {
            Caption = 'Умови оплати';
            TableRelation = "Payment Terms".Code;
        }

        field(21; "Payment Method Code"; Code[10])
        {
            Caption = 'Спосіб оплати';
            TableRelation = "Payment Method".Code;
        }

        field(22; "Currency Code"; Code[10])
        {
            Caption = 'Валюта';
            TableRelation = Currency.Code;
        }

        field(23; "Shipment Method Code"; Code[10])
        {
            Caption = 'Спосіб доставки';
            TableRelation = "Shipment Method".Code;
        }

        field(24; "Location Code"; Code[10])
        {
            Caption = 'Код складу';
            TableRelation = Location.Code;
        }

        field(30; "Initialized At"; DateTime)
        {
            Caption = 'Ініціалізовано';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Role Code")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    var
        Role: Record "SI BP Role";
    begin
        Role.Get("Role Code");

        if Role."Role Type" <> Role."Role Type"::Customer then
            Error(
                'Роль %1 не є роллю покупця.',
                "Role Code");

        "Business Partner No." :=
            Role."Business Partner No.";
    end;
}