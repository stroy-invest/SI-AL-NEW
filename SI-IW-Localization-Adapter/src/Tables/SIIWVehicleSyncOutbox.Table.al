table 65002 "SI IW Vehicle Sync Outbox"
{
    Caption = 'SI IW Vehicle Sync Outbox';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Vehicle No."; Code[20])
        {
            Caption = 'Vehicle No.';
            TableRelation = "SI Vehicle Profile"."No.";
            NotBlank = true;
        }
        field(2; Status; Enum "SI IW Vehicle Sync Status")
        {
            Caption = 'Статус';
            InitValue = Pending;
        }
        field(3; "Revision No."; Integer)
        {
            Caption = 'Ревізія';
        }
        field(4; "Attempt Count"; Integer)
        {
            Caption = 'Кількість спроб';
        }
        field(5; "Next Attempt At"; DateTime)
        {
            Caption = 'Наступна спроба';
        }
        field(6; "Last Attempt At"; DateTime)
        {
            Caption = 'Остання спроба';
        }
        field(7; "Last Success At"; DateTime)
        {
            Caption = 'Останній успіх';
        }
        field(8; "Last Error"; Text[2048])
        {
            Caption = 'Остання помилка';
        }
        field(9; "Created At"; DateTime)
        {
            Caption = 'Створено';
        }
        field(10; "Modified At"; DateTime)
        {
            Caption = 'Змінено';
        }
    }
    keys
    {
        key(PK; "Vehicle No.") { Clustered = true; }
        key(Due; Status, "Next Attempt At") { }
    }
}
