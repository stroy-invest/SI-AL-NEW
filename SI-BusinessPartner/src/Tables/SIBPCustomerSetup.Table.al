table 54010 "SI BP Customer Setup"
{
    Caption = 'Налаштування покупця контрагента';
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

        field(20; "Customer Posting Group"; Code[20])
        {
            Caption = 'Група обліку покупця';
            DataClassification = CustomerContent;
            TableRelation = "Customer Posting Group".Code;
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

        field(80; "Salesperson Code"; Code[20])
        {
            Caption = 'Код продавця';
            DataClassification = CustomerContent;
            TableRelation = "Salesperson/Purchaser".Code;
        }

        field(90; "Credit Limit (LCY)"; Decimal)
        {
            Caption = 'Кредитний ліміт (ЛВ)';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 2;
            MinValue = 0;
        }

        field(100; "Price Calculation Method"; Enum "Price Calculation Method")
        {
            Caption = 'Метод розрахунку ціни';
            DataClassification = CustomerContent;
        }

        field(110; "Customer Price Group"; Code[10])
        {
            Caption = 'Цінова група покупця';
            DataClassification = CustomerContent;
            TableRelation = "Customer Price Group".Code;
        }

        field(120; "Customer Discount Group"; Code[20])
        {
            Caption = 'Група знижок покупця';
            DataClassification = CustomerContent;
            TableRelation = "Customer Discount Group".Code;
        }

        field(130; "Allow Line Disc."; Boolean)
        {
            Caption = 'Дозволити знижку рядка';
            DataClassification = CustomerContent;
            InitValue = true;
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