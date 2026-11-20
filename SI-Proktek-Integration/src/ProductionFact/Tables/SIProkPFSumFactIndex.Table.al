table 57232 "SI Prok PF Sum Fact Index"
{
    Caption = 'Індекс фактів підсумкового звіту';
    TableType = Temporary;
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Group Key"; Text[250]) { Caption = 'Ключ бетону'; }
        field(10; "Fact Entry No."; Integer) { Caption = 'Факт виробництва'; }
    }

    keys
    {
        key(PK; "Group Key", "Fact Entry No.") { Clustered = true; }
    }
}
