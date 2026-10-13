table 50571 "SI App Dependency Buffer"
{
    Caption = 'SI App Dependency Buffer';
    TableType = Temporary;
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "Line No."; Integer) { Caption = '№'; }
        field(2; "Dependency App ID"; Guid) { Caption = 'App ID залежності'; }
        field(3; "Dependency Name"; Text[250]) { Caption = 'Залежність'; }
        field(4; Publisher; Text[250]) { Caption = 'Видавець'; }
        field(5; Installed; Boolean) { Caption = 'Встановлено'; }
        field(6; "Installed Version"; Text[50]) { Caption = 'Встановлена версія'; }
        field(7; Status; Text[50]) { Caption = 'Стан'; }
    }
    keys { key(PK; "Line No.") { Clustered = true; } }
}
