table 65003 "SI IW Setup Check Result"
{
    Caption = 'SI IW Setup Check Result';
    TableType = Temporary;
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "Entry No."; Integer) { Caption = '№'; }
        field(2; "Check Area"; Text[50]) { Caption = 'Область перевірки'; }
        field(3; "Object Code"; Code[50]) { Caption = 'Код'; }
        field(4; "Result"; Text[20]) { Caption = 'Результат'; }
        field(5; "Details"; Text[250]) { Caption = 'Деталі'; }
        field(6; "Recommended Action"; Text[250]) { Caption = 'Рекомендована дія'; }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}
