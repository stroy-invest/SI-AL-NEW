table 54005 "SI EDRPOU Check Buffer"
{
    Caption = 'EDRPOU Check Result';
    DataClassification = CustomerContent;
    TableType = Temporary;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }

        field(2; "Registration No."; Text[50])
        {
            Caption = 'EDRPOU';
        }

        field(3; "Full Name"; Text[500])
        {
            Caption = 'Full Name';
        }

        field(4; "Short Name"; Text[250])
        {
            Caption = 'Short Name';
        }

        field(5; Address; Text[500])
        {
            Caption = 'Legal Address';
        }

        field(6; Director; Text[250])
        {
            Caption = 'Director';
        }

        field(7; "Director Genitive"; Text[250])
        {
            Caption = 'Director (Genitive)';
        }

        field(8; "KVED No."; Text[30])
        {
            Caption = 'Primary KVED No.';
        }

        field(9; "KVED Description"; Text[500])
        {
            Caption = 'Primary KVED';
        }

        field(10; "Tax Registration No."; Text[50])
        {
            Caption = 'VAT Registration No.';
        }

        field(11; "Registration Date"; Text[30])
        {
            Caption = 'Registration Date';
        }

        field(12; "Tax Registration Date"; Text[30])
        {
            Caption = 'VAT Registration Date';
        }

        field(13; "Last Update"; Text[30])
        {
            Caption = 'Registry Last Update';
        }

        field(20; "BP Tax Registration No."; Text[50])
        {
            Caption = 'Our VAT Registration No.';
        }

        field(21; "BP Legal Form Code"; Code[20])
        {
            Caption = 'Our Country Legal Form Code';
        }

        field(22; "BP Legal Form Name"; Text[150])
        {
            Caption = 'Our Country Legal Form';
        }

        field(23; "Registry Legal Form Code"; Code[20])
        {
            Caption = 'Registry Country Legal Form Code';
        }

        field(24; "Registry Legal Form Name"; Text[150])
        {
            Caption = 'Registry Country Legal Form';
        }

        field(25; "VAT Matches"; Boolean)
        {
            Caption = 'VAT Registration No. Matches';
        }

        field(26; "Legal Form Matches"; Boolean)
        {
            Caption = 'Country Legal Form Matches';
        }

        field(27; "Has Differences"; Boolean)
        {
            Caption = 'Has Differences';
        }

        field(28; "Can Apply Corrections"; Boolean)
        {
            Caption = 'Can Apply Corrections';
        }

        field(29; "Comparison Result"; Text[250])
        {
            Caption = 'Comparison Result';
        }

        field(30; "BP Name"; Text[250])
        {
            Caption = 'Our Business Partner Name';
        }

        field(31; "Registry Business Name"; Text[250])
        {
            Caption = 'Registry Business Name';
        }

        field(32; "Name Needs Fill"; Boolean)
        {
            Caption = 'Name Needs Fill';
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
