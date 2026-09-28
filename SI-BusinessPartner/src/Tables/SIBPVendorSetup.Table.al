table 54011 "SI BP Vendor Setup"
{
    Caption = 'Налаштування постачальника контрагента';
    DataClassification = CustomerContent;
    ObsoleteState = Pending;
    ObsoleteReason = 'Legacy prototype role setup. ERP role configuration is owned by SI BP Role and standard BC Customer/Vendor Templates.';

    fields
    {
        field(1; "Business Partner No."; Code[20])
        {
            Caption = 'Код контрагента';
            DataClassification = CustomerContent;
            TableRelation = "SI Business Partner"."No.";
        }

        field(10; "Is Inactive"; Boolean)
        {
            Caption = 'Неактивний';
            DataClassification = CustomerContent;
            InitValue = false;
        }

        field(20; "Vendor Posting Group"; Code[20])
        {
            Caption = 'Група обліку постачальника';
            DataClassification = CustomerContent;
            TableRelation = "Vendor Posting Group".Code;
        }

        field(30; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Бізнес-група обліку';
            DataClassification = CustomerContent;
            TableRelation = "Gen. Business Posting Group".Code;
        }

        field(40; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'Бізнес-група ПДВ';
            DataClassification = CustomerContent;
            TableRelation = "VAT Business Posting Group".Code;
        }

        field(50; "Payment Terms Code"; Code[10])
        {
            Caption = 'Код умов оплати';
            DataClassification = CustomerContent;
            TableRelation = "Payment Terms".Code;
        }

        field(60; "Payment Method Code"; Code[10])
        {
            Caption = 'Код способу оплати';
            DataClassification = CustomerContent;
            TableRelation = "Payment Method".Code;
        }

        field(70; "Currency Code"; Code[10])
        {
            Caption = 'Код валюти';
            DataClassification = CustomerContent;
            TableRelation = Currency.Code;
        }

        field(80; "Purchaser Code"; Code[20])
        {
            Caption = 'Код закупівельника';
            DataClassification = CustomerContent;
            TableRelation = "Salesperson/Purchaser".Code;
        }

        field(90; "Lead Time Calculation"; DateFormula)
        {
            Caption = 'Розрахунок терміну постачання';
            DataClassification = CustomerContent;
        }

        field(100; "Shipment Method Code"; Code[10])
        {
            Caption = 'Код способу доставки';
            DataClassification = CustomerContent;
            TableRelation = "Shipment Method".Code;
        }

        field(110; "Payment Discount %"; Decimal)
        {
            Caption = 'Знижка за оплату, %';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 100;
        }

        field(120; "Priority"; Integer)
        {
            Caption = 'Пріоритет';
            DataClassification = CustomerContent;
            MinValue = 0;
        }
    }

    keys
    {
        key(PK; "Business Partner No.")
        {
            Clustered = true;
        }

        key(Inactive; "Is Inactive")
        {
        }
    }
}