table 50611 "SI Employment Context"
{
    Caption = 'SI Employment Context';
    DataClassification = CustomerContent;
    TableType = Temporary;

    fields
    {
        field(1; "Entry No."; Integer) { Caption = 'Entry No.'; }
        field(2; "Employee No."; Code[20]) { Caption = 'Employee No.'; }
        field(3; "Employee Name"; Text[100]) { Caption = 'Employee Name'; }
        field(4; "Employment Context ID"; Code[20]) { Caption = 'Employment Context ID'; }
        field(5; "Employment Type"; Text[50]) { Caption = 'Employment Type'; }
        field(6; "Department Code"; Code[20]) { Caption = 'Department Code'; }
        field(7; "Department Name"; Text[100]) { Caption = 'Department Name'; }
        field(8; "Unit No."; Code[20]) { Caption = 'Unit No.'; }
        field(9; "Unit Name"; Text[250]) { Caption = 'Unit Name'; }
        field(10; "Position Code"; Code[20]) { Caption = 'Position Code'; }
        field(11; "Position Name"; Text[250]) { Caption = 'Position Name'; }
        field(12; "Context Date"; Date) { Caption = 'Context Date'; }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}
