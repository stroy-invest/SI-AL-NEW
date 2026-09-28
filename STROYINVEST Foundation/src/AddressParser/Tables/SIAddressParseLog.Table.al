table 50192 "SI Address Parse Log"
{
    Caption = 'SI Address Parse Log';
    DataClassification = CustomerContent;
    // DrillDownPageId = "SI Address Parse Log";
    // LookupPageId = "SI Address Parse Log";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
            AutoIncrement = true;
        }

        field(10; "Created At"; DateTime)
        {
            Caption = 'Created At';
            DataClassification = SystemMetadata;
        }

        field(20; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
        }

        field(30; Source; Code[50])
        {
            Caption = 'Source';
            DataClassification = SystemMetadata;
        }

        field(40; "Source Record No."; Code[50])
        {
            Caption = 'Source Record No.';
            DataClassification = CustomerContent;
        }

        field(50; "Raw Address"; Text[2048])
        {
            Caption = 'Raw Address';
            DataClassification = CustomerContent;
        }

        field(60; "Parse Message"; Text[2048])
        {
            Caption = 'Parse Message';
            DataClassification = SystemMetadata;
        }

        field(70; "Unrecognized Fragment"; Text[2048])
        {
            Caption = 'Unrecognized Fragment';
            DataClassification = CustomerContent;
        }

        field(100; "Parsed Country Name"; Text[250])
        {
            Caption = 'Parsed Country Name';
            DataClassification = CustomerContent;
        }

        field(110; "Parsed Post Code"; Text[250])
        {
            Caption = 'Parsed Post Code';
            DataClassification = CustomerContent;
        }

        field(120; "Parsed Region Name"; Text[250])
        {
            Caption = 'Parsed Region Name';
            DataClassification = CustomerContent;
        }

        field(130; "Parsed District Name"; Text[250])
        {
            Caption = 'Parsed District Name';
            DataClassification = CustomerContent;
        }

        field(140; "Parsed City Name"; Text[250])
        {
            Caption = 'Parsed City Name';
            DataClassification = CustomerContent;
        }

        field(150; "Parsed Street"; Text[250])
        {
            Caption = 'Parsed Street';
            DataClassification = CustomerContent;
        }

        field(160; "Parsed Building No."; Text[250])
        {
            Caption = 'Parsed Building No.';
            DataClassification = CustomerContent;
        }

        field(170; "Parsed Office"; Text[250])
        {
            Caption = 'Parsed Office';
            DataClassification = CustomerContent;
        }

        field(180; "Parsed Apartment"; Text[250])
        {
            Caption = 'Parsed Apartment';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }

        key(SourceRecord; Source, "Source Record No.", "Created At")
        {
        }

        key(CreatedAt; "Created At")
        {
        }
    }
}