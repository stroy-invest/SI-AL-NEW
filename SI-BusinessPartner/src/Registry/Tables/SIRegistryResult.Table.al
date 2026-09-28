table 54006 "SI Registry Result"
{
    Caption = 'Registry Result';
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }

        field(2; "Provider Code"; Code[50])
        {
            Caption = 'Provider Code';
        }

        field(3; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
        }

        field(4; "Registration No."; Text[50])
        {
            Caption = 'Registration No.';
        }

        field(5; "Tax Registration No."; Text[50])
        {
            Caption = 'Tax Registration No.';
        }

        field(6; "Legal Name"; Text[500])
        {
            Caption = 'Legal Name';
        }

        field(7; "Registry Short Name"; Text[250])
        {
            Caption = 'Registry Short Name';
        }

        field(8; "Core Name"; Text[250])
        {
            Caption = 'Core Name';
        }

        field(9; "Legal Form Short"; Text[50])
        {
            Caption = 'Legal Form Short';
        }

        field(10; Address; Text[500])
        {
            Caption = 'Legal Address';
        }

        field(11; Director; Text[250])
        {
            Caption = 'Director';
        }

        field(12; "Director Genitive"; Text[250])
        {
            Caption = 'Director (Genitive)';
        }

        field(13; "KVED No."; Text[30])
        {
            Caption = 'Primary KVED No.';
        }

        field(14; "KVED Description"; Text[500])
        {
            Caption = 'Primary KVED';
        }

        field(15; "Registration Date"; Text[30])
        {
            Caption = 'Registration Date';
        }

        field(16; "Tax Registration Date"; Text[30])
        {
            Caption = 'Tax Registration Date';
        }

        field(17; "Registry Last Update"; Text[30])
        {
            Caption = 'Registry Last Update';
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