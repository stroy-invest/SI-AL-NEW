table 61055 "SI PO Proposal Alloc. Link"
{
    Caption = 'Походження рядка пропозиції';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Proposal Entry No."; Integer) { Caption = 'Пропозиція'; TableRelation = "SI PO Proposal Header"."Entry No."; }
        field(2; "Proposal Line No."; Integer) { Caption = 'Рядок пропозиції'; }
        field(3; "Allocation Entry No."; Integer) { Caption = 'Розподіл постачання'; TableRelation = "SI Procurement Allocation"."Entry No."; }
        field(10; Quantity; Decimal) { Caption = 'Кількість'; DecimalPlaces = 0 : 5; }
    }

    keys
    {
        key(PK; "Proposal Entry No.", "Proposal Line No.", "Allocation Entry No.") { Clustered = true; }
        key(Allocation; "Allocation Entry No.") { }
    }
}
