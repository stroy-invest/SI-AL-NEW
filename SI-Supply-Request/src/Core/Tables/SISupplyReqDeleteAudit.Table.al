table 61090 "SI Supply Req Delete Audit"
{
    Caption = 'Журнал адміністративного видалення заявок';
    DataClassification = CustomerContent;
    fields
    {
        field(1; "Entry No."; Integer) { AutoIncrement = true; }
        field(2; "Request No."; Code[20]) { }
        field(3; "Deleted At"; DateTime) { }
        field(4; "Deleted By"; Code[50]) { }
        field(5; "Request Status"; Text[50]) { }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}
