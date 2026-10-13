table 50570 "SI App Registry Buffer"
{
    Caption = 'SI Application Registry Buffer';
    TableType = Temporary;
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "App ID"; Guid) { Caption = 'App ID'; }
        field(2; "App Name"; Text[250]) { Caption = 'Назва'; }
        field(3; Publisher; Text[250]) { Caption = 'Видавець'; }
        field(4; "App Version"; Text[50]) { Caption = 'Версія додатка'; }
        field(5; "Data Version"; Text[50]) { Caption = 'Версія даних'; }
        field(6; "Package ID"; Guid) { Caption = 'Package ID'; }
        field(7; "Upgrade Pending"; Boolean) { Caption = 'Оновлення даних очікується'; }
        field(8; "Dependency Count"; Integer) { Caption = 'Залежностей'; }
        field(9; "Missing Dependencies"; Integer) { Caption = 'Відсутніх залежностей'; }
    }
    keys { key(PK; "App ID") { Clustered = true; } }
}
