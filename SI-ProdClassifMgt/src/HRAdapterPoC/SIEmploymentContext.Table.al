table 56200 "SI Employment Context"
{
    Caption = 'SI Employment Context';
    DataClassification = CustomerContent;
    TableType = Temporary;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Person No."; Code[20])
        {
            Caption = 'Person No.';
        }
        field(3; "Person Name"; Text[100])
        {
            Caption = 'Person Name';
        }
        field(4; "Employment Context ID"; Code[20])
        {
            Caption = 'Employment Context ID';
        }
        field(5; "Employment Status"; Text[50])
        {
            Caption = 'Employment Status';
        }
        field(6; "Employment Type"; Text[50])
        {
            Caption = 'Employment Type';
        }
        field(7; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
        field(8; "Employment Date"; Date)
        {
            Caption = 'Employment Date';
        }
        field(9; "Has Actual Context"; Boolean)
        {
            Caption = 'Has Actual Context';
        }
        field(10; "Ledger Entry No."; Integer)
        {
            Caption = 'Ledger Entry No.';
        }
        field(11; "Context Posting Date"; Date)
        {
            Caption = 'Context Posting Date';
        }
        field(12; "Context Ending Date"; Date)
        {
            Caption = 'Context Ending Date';
        }
        field(13; "Department Code"; Code[20])
        {
            Caption = 'Department Code';
        }
        field(14; "Department Name"; Text[100])
        {
            Caption = 'Department Name';
        }
        field(15; "Unit No."; Code[20])
        {
            Caption = 'Unit No.';
        }
        field(16; "Unit Name"; Text[250])
        {
            Caption = 'Unit Name';
        }
        field(17; "Position Code"; Code[20])
        {
            Caption = 'Position Code';
        }
        field(18; "Position Name"; Text[250])
        {
            Caption = 'Position Name';
        }
        field(19; "Ledger Entry Type"; Text[50])
        {
            Caption = 'Ledger Entry Type';
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
