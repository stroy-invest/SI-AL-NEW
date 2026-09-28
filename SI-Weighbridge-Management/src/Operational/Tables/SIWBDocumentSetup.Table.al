table 59120 "SI WB Document Setup"
{
    Caption = 'Налаштування документів вагової';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Ключ';
        }

        field(10; "TTN Nos."; Code[20])
        {
            Caption = 'Серія номерів ТТН';
            TableRelation = "No. Series".Code;
        }

        field(11; "Delivery Note Nos."; Code[20])
        {
            Caption = 'Серія номерів видаткових накладних';
            TableRelation = "No. Series".Code;
        }

        field(12; "Product Passport Nos."; Code[20])
        {
            Caption = 'Серія номерів паспортів якості';
            TableRelation = "No. Series".Code;
        }

        field(13; "Internal Transfer Nos."; Code[20])
        {
            Caption = 'Серія номерів внутрішніх переміщень';
            TableRelation = "No. Series".Code;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    procedure GetOrCreate()
    begin
        if Get('SETUP') then
            exit;

        Init();
        "Primary Key" := 'SETUP';
        Insert(true);
    end;
}
