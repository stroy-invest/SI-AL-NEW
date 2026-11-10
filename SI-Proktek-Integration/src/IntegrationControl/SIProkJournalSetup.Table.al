table 57120 "SI Prok Journal Setup"
{
    Caption = 'Налаштування журналів Proktek';
    DataClassification = CustomerContent;
    fields
    {
        field(1; "Primary Key"; Code[10]) { Caption = 'Ключ'; }
        field(10; "Output Template"; Code[10]) { Caption = 'Шаблон журналу випуску'; TableRelation = "Item Journal Template".Name; }
        field(11; "Output Batch"; Code[10]) { Caption = 'Пакет журналу випуску'; TableRelation = "Item Journal Batch".Name where("Journal Template Name" = field("Output Template")); }
        field(20; "Consumption Template"; Code[10]) { Caption = 'Шаблон журналу споживання'; TableRelation = "Item Journal Template".Name; }
        field(21; "Consumption Batch"; Code[10]) { Caption = 'Пакет журналу споживання'; TableRelation = "Item Journal Batch".Name where("Journal Template Name" = field("Consumption Template")); }
    }
    keys { key(PK; "Primary Key") { Clustered = true; } }
}
