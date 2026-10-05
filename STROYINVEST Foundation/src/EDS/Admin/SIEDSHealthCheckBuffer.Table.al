table 50471 "SI EDS Health Check Buffer"
{
    TableType = Temporary;
    Caption = 'EDS Health Check Buffer';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { Caption = '№'; }
        field(2; Severity; Option) { Caption = 'Стан'; OptionMembers = OK,Warning,Error; OptionCaption = 'OK,Попередження,Помилка'; }
        field(3; "Check Area"; Option) { Caption = 'Об''єкт'; OptionMembers = Service,Operation,Provider,Endpoint,Credential,Route,Parameter,RateLimit,AsyncWorker; OptionCaption = 'Сервіс,Операція,Провайдер,Точка підключення,Облікові дані,Маршрут,Параметр,Ліміт запитів,Async Worker'; }
        field(4; "Object Code"; Text[150]) { Caption = 'Код'; }
        field(5; Check; Text[150]) { Caption = 'Перевірка'; }
        field(6; Result; Text[250]) { Caption = 'Результат'; }
    }

    keys { key(PK; "Entry No.") { Clustered = true; } }
}
