table 63206 "SI Vehicle Setup"
{
    Caption = 'Налаштування транспорту';
    DataClassification = CustomerContent;
    fields
    {
        field(1; "Primary Key"; Code[10]) { Caption = 'Ключ'; }
        field(2; "Vehicle Nos."; Code[20])
        {
            Caption = 'Серія номерів транспорту';
            TableRelation = "No. Series".Code;
        }
    }
    keys { key(PK; "Primary Key") { Clustered = true; } }
}
