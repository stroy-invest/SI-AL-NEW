table 61000 "SI Supply Req Setup"
{
    Caption = 'Налаштування заявок на забезпечення';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Ключ';
        }
        field(10; "Request Nos."; Code[20])
        {
            Caption = 'Серія номерів заявок';
            TableRelation = "No. Series";
        }
        field(20; "Schrift Enabled"; Boolean)
        {
            Caption = 'Schrift увімкнено';
        }
        field(30; "Schrift Base URL"; Text[250])
        {
            Caption = 'Schrift Base URL';
        }
        field(40; "Schrift Template ID"; Integer)
        {
            Caption = 'Schrift Template ID';
        }
        field(50; "Schrift Document Type ID"; Integer)
        {
            Caption = 'Schrift Document Type ID';
        }
        field(60; "VSC Nos."; Code[20])
        {
            Caption = 'Серія номерів каналів постачання';
            TableRelation = "No. Series";
        }
        field(70; "Planning Forecast Name"; Code[10])
        {
            Caption = 'Прогноз для планових потреб';
            TableRelation = "Production Forecast Name".Name;
        }
    }

    keys
    {
        key(PK; "Primary Key") { Clustered = true; }
    }
}
