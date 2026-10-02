table 50612 "SI Employment Resolution"
{
    Caption = 'SI Employment Resolution';
    DataClassification = CustomerContent;
    TableType = Temporary;

    fields
    {
        field(1; "Entry No."; Integer) { Caption = 'Entry No.'; }
        field(2; Status; Enum "SI Employment Resolve Status") { Caption = 'Status'; }
        field(3; "Context Date"; Date) { Caption = 'Context Date'; }
        field(4; "Employee No."; Code[20]) { Caption = 'Employee No.'; }
        field(5; "Employee Name"; Text[100]) { Caption = 'Employee Name'; }
        field(6; "Employment Context ID"; Code[20]) { Caption = 'Employment Context ID'; }
        field(7; "Employment Type"; Text[50]) { Caption = 'Employment Type'; }
        field(8; "Department Code"; Code[20]) { Caption = 'Department Code'; }
        field(9; "Department Name"; Text[100]) { Caption = 'Department Name'; }
        field(10; "Unit No."; Code[20]) { Caption = 'Unit No.'; }
        field(11; "Unit Name"; Text[250]) { Caption = 'Unit Name'; }
        field(12; "Position Code"; Code[20]) { Caption = 'Position Code'; }
        field(13; "Position Name"; Text[250]) { Caption = 'Position Name'; }
        field(14; "Active Context Count"; Integer) { Caption = 'Active Context Count'; }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}
