table 54014 "SI Foreign Bank"
{
    Caption = 'Закордонні банки';
    DataClassification = CustomerContent;
    DataCaptionFields = Name;

    fields
    {
        field(1; "Id"; Code[10])
        {
            Caption = 'Id';
        }

        field(10; "K040"; Code[3])
        {
            Caption = 'K040';
        }

        field(20; "SWIFT"; Code[11])
        {
            Caption = 'SWIFT';
        }

        field(30; "Source SWIFT"; Text[20])
        {
            Caption = 'Source SWIFT';

            ObsoleteState = Pending;
            ObsoleteReason = 'Raw SWIFT value is no longer stored. SWIFT is normalized by the NBU integration service.';
            ObsoleteTag = '1.0.0.2';
        }

        field(40; "Name"; Text[250])
        {
            Caption = 'Name';
        }

        field(50; "Country Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region".Code;
        }

        field(60; "City Name"; Text[100])
        {
            Caption = 'City Name';
        }

        field(70; "Is Active"; Boolean)
        {
            Caption = 'Active';
        }
    }

    keys
    {
        key(PK; "Id")
        {
            Clustered = true;
        }

        key(SWIFT; "SWIFT")
        {
        }

        key(Country; "Country Code")
        {
        }
    }
}