table 61015 "SI Procurement Batch"
{
    Caption = 'Підготовка закупівлі';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { Caption = '№ підготовки'; }
        field(10; Status; Enum "SI Proc. Batch Status") { Caption = 'Статус'; }
        field(20; "Created By User ID"; Text[50]) { Caption = 'Створив'; Editable = false; }
        field(21; "Created At"; DateTime) { Caption = 'Створено'; Editable = false; }
        field(30; "Last Modified At"; DateTime) { Caption = 'Змінено'; Editable = false; }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
        key(UserDraft; "Created By User ID", Status) { }
    }
}
