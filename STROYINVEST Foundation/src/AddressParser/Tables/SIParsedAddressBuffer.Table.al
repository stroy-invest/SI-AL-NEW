table 50190 "SI Parsed Address Buffer"
{
    Caption = 'SI Parsed Address Buffer';
    DataClassification = CustomerContent;
    TableType = Temporary;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }

        field(10; "Raw Address"; Text[2048])
        {
            Caption = 'Raw Address';
            DataClassification = CustomerContent;
        }

        field(20; "Country Name"; Text[250])
        {
            Caption = 'Country Name';
            DataClassification = CustomerContent;
        }

        field(30; "Post Code"; Text[250])
        {
            Caption = 'Post Code';
            DataClassification = CustomerContent;
        }

        field(40; "Region Name"; Text[250])
        {
            Caption = 'Region Name';
            DataClassification = CustomerContent;
        }

        field(50; "District Name"; Text[250])
        {
            Caption = 'District Name';
            DataClassification = CustomerContent;
        }

        field(60; "City Name"; Text[250])
        {
            Caption = 'City Name';
            DataClassification = CustomerContent;
        }

        field(70; Street; Text[250])
        {
            Caption = 'Street';
            DataClassification = CustomerContent;
        }

        field(80; "Building No."; Text[250])
        {
            Caption = 'Building No.';
            DataClassification = CustomerContent;
        }

        field(90; Office; Text[250])
        {
            Caption = 'Office';
            DataClassification = CustomerContent;
        }

        field(100; Apartment; Text[250])
        {
            Caption = 'Apartment';
            DataClassification = CustomerContent;
        }

        field(110; "Parse Successful"; Boolean)
        {
            Caption = 'Parse Successful';
            DataClassification = SystemMetadata;
        }

        field(120; "Parse Message"; Text[2048])
        {
            Caption = 'Parse Message';
            DataClassification = SystemMetadata;
        }

        field(130; "Unrecognized Fragment"; Text[2048])
        {
            Caption = 'Unrecognized Fragment';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }
}