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
        field(30; "Document No. Series"; Code[20])
        {
            Caption = 'Серія номерів облікових документів';
            TableRelation = "No. Series".Code;
        }
        field(50; "Process Template"; Code[10])
        {
            Caption = 'Шаблон SI Process Production';
            TableRelation = "Item Journal Template".Name;
        }
        field(51; "Process Batch"; Code[10])
        {
            Caption = 'Пакет SI Process Production';
            TableRelation = "Item Journal Batch".Name where("Journal Template Name" = field("Process Template"));
        }
        field(52; "Process Business Group"; Code[20])
        {
            Caption = 'Загальна бізнес-група Process';
            TableRelation = "Gen. Business Posting Group".Code;
        }
        field(40; "Posting Date Policy"; Enum "SI Prok Posting Date Policy")
        {
            Caption = 'Політика дати обліку';
            ToolTip = 'Дата фізичного виробництва зберігається окремо. Політика визначає дату обліку під час підготовки журналів або керованої зміни дати непроведених журналів.';
        }
        field(41; "Specified Posting Date"; Date)
        {
            Caption = 'Задана дата обліку';
            ToolTip = 'Використовується тільки за політики «Задана дата». Не змінює дату виробничого факту.';
        }
    }
    keys { key(PK; "Primary Key") { Clustered = true; } }
}
