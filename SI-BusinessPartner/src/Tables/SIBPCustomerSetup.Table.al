table 54010 "SI BP Customer Setup"
{
    Caption = 'Business Partner Customer Setup';
    DataClassification = CustomerContent;
    ObsoleteState = Pending;
    ObsoleteReason = 'Legacy prototype role setup. ERP role configuration is owned by SI BP Role and standard BC Customer/Vendor Templates.';

    fields
    {
        field(1; "Business Partner No."; Code[20])
        {
            Caption = 'Business Partner No.';
            DataClassification = CustomerContent;
            TableRelation = "SI Business Partner"."No.";
        }

        field(10; "Is Inactive"; Boolean)
        {
            Caption = 'Is Inactive';
            DataClassification = CustomerContent;
            InitValue = false;
        }

        field(20; "Customer Posting Group"; Code[20])
        {
            Caption = 'Customer Posting Group';
            DataClassification = CustomerContent;
            TableRelation = "Customer Posting Group".Code;
        }

        field(30; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            DataClassification = CustomerContent;
            TableRelation = "Gen. Business Posting Group".Code;
        }

        field(40; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            DataClassification = CustomerContent;
            TableRelation = "VAT Business Posting Group".Code;
        }

        field(50; "Payment Terms Code"; Code[10])
        {
            Caption = 'Payment Terms Code';
            DataClassification = CustomerContent;
            TableRelation = "Payment Terms".Code;
        }

        field(60; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';
            DataClassification = CustomerContent;
            TableRelation = "Payment Method".Code;
        }

        field(70; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = CustomerContent;
            TableRelation = Currency.Code;
        }

        field(80; "Salesperson Code"; Code[20])
        {
            Caption = 'Salesperson Code';
            DataClassification = CustomerContent;
            TableRelation = "Salesperson/Purchaser".Code;
        }

        field(90; "Credit Limit (LCY)"; Decimal)
        {
            Caption = 'Credit Limit (LCY)';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 2;
            MinValue = 0;
        }

        field(100; "Price Calculation Method"; Enum "Price Calculation Method")
        {
            Caption = 'Price Calculation Method';
            DataClassification = CustomerContent;
        }

        field(110; "Customer Price Group"; Code[10])
        {
            Caption = 'Customer Price Group';
            DataClassification = CustomerContent;
            TableRelation = "Customer Price Group".Code;
        }

        field(120; "Customer Discount Group"; Code[20])
        {
            Caption = 'Customer Discount Group';
            DataClassification = CustomerContent;
            TableRelation = "Customer Discount Group".Code;
        }

        field(130; "Allow Line Disc."; Boolean)
        {
            Caption = 'Allow Line Discount';
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