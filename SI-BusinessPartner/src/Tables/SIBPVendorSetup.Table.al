table 54011 "SI BP Vendor Setup"
{
    Caption = 'Business Partner Vendor Setup';
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

        field(20; "Vendor Posting Group"; Code[20])
        {
            Caption = 'Vendor Posting Group';
            DataClassification = CustomerContent;
            TableRelation = "Vendor Posting Group".Code;
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

        field(80; "Purchaser Code"; Code[20])
        {
            Caption = 'Purchaser Code';
            DataClassification = CustomerContent;
            TableRelation = "Salesperson/Purchaser".Code;
        }

        field(90; "Lead Time Calculation"; DateFormula)
        {
            Caption = 'Lead Time Calculation';
            DataClassification = CustomerContent;
        }

        field(100; "Shipment Method Code"; Code[10])
        {
            Caption = 'Shipment Method Code';
            DataClassification = CustomerContent;
            TableRelation = "Shipment Method".Code;
        }

        field(110; "Payment Discount %"; Decimal)
        {
            Caption = 'Payment Discount %';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 100;
        }

        field(120; "Priority"; Integer)
        {
            Caption = 'Priority';
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