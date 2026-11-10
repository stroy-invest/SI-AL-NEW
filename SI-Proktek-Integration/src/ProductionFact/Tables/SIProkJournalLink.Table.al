table 57121 "SI Prok Journal Link"
{
    Caption = 'Зв’язок виробничого факту з журналом';
    DataClassification = CustomerContent;
    fields
    {
        field(1; "Fact Entry No."; Integer) { Caption = 'Факт'; TableRelation = "SI Prok Production Fact"."Entry No."; }
        field(2; "Link Line No."; Integer) { Caption = 'Рядок зв’язку'; }
        field(10; "Production UUID"; Guid) { Caption = 'Production UUID'; }
        field(11; "Material Line No."; Integer) { Caption = 'Рядок матеріалу (0 = Output)'; }
        field(20; "Journal Template"; Code[10]) { Caption = 'Шаблон'; }
        field(21; "Journal Batch"; Code[10]) { Caption = 'Пакет'; }
        field(22; "Journal Line No."; Integer) { Caption = 'Рядок журналу'; }
        field(23; "Document No."; Code[20]) { Caption = 'Номер документа'; }
        field(30; "Prepared At"; DateTime) { Caption = 'Створено'; }
        field(31; "Prepared By"; Code[50]) { Caption = 'Користувач'; }
    }
    keys
    {
        key(PK; "Fact Entry No.", "Link Line No.") { Clustered = true; }
        key(UUID; "Production UUID") { }
    }
}
