table 50485 "SI EDS Wiz Param Buffer"
{
    TableType = Temporary;
    Caption = 'Параметри майстра EDS';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { Caption = '№'; }
        field(2; Code; Code[50]) { Caption = 'Код параметра'; NotBlank = true; }
        field(3; Sequence; Integer) { Caption = 'Послідовність'; MinValue = 0; }
        field(4; "External Name"; Text[100]) { Caption = 'Зовнішнє ім''я'; }
        field(5; Location; Enum "SI EDS Param. Location") { Caption = 'Розташування'; }
        field(6; Source; Enum "SI EDS Param. Source") { Caption = 'Джерело значення'; }
        field(7; Format; Enum "SI EDS Param. Format") { Caption = 'Формат'; }
        field(8; "Runtime Key"; Code[50]) { Caption = 'Runtime key'; }
        field(9; Value; Text[250]) { Caption = 'Фіксоване значення'; }
        field(10; "Credential Code"; Code[50]) { Caption = 'Облікові дані'; }
        field(11; "Value Prefix"; Text[50]) { Caption = 'Префікс'; }
        field(12; Required; Boolean) { Caption = 'Обов''язковий'; }
        field(13; "Existing"; Boolean) { Caption = 'Наявний'; }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } key(CodeKey; Code) { } }
}
