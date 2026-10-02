table 60015 "SI Eligible Employee"
{
    Caption = 'Eligible Employee';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Employee No."; Code[20]) { Caption = 'Employee No.'; }
        field(2; "Last Name"; Text[30]) { Caption = 'Прізвище'; }
        field(3; "First Name"; Text[30]) { Caption = 'Ім''я'; }
        field(4; "Middle Name"; Text[30]) { Caption = 'По батькові'; }
        field(5; "Position Name"; Text[250]) { Caption = 'Посада'; }
    }

    keys
    {
        key(PK; "Employee No.") { Clustered = true; }
        key(Name; "Last Name", "First Name", "Middle Name") { }
    }
}
