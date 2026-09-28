table 50214 "SI Notif. Recipient Buffer"
{
    Caption = 'Буфер отримувачів повідомлень';
    DataClassification = CustomerContent;
    TableType = Temporary;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Номер запису';
            AutoIncrement = true;
            DataClassification = SystemMetadata;
        }

        field(10; "Security ID"; Guid)
        {
            Caption = 'Ідентифікатор користувача';
            DataClassification = EndUserPseudonymousIdentifiers;
        }

        field(20; "User Name"; Code[50])
        {
            Caption = 'Ім’я користувача';
            DataClassification = EndUserIdentifiableInformation;
        }

        field(30; "Display Name"; Text[80])
        {
            Caption = 'Ім’я для відображення';
            DataClassification = EndUserIdentifiableInformation;
        }

        field(40; "Recipient Group Code"; Code[50])
        {
            Caption = 'Код групи отримувачів';
        }

        field(50; "Resolver Type"; Enum "SI Recipient Resolver Type")
        {
            Caption = 'Тип визначення отримувачів';
        }

        field(60; "Provider Code"; Code[50])
        {
            Caption = 'Код провайдера';
        }

        field(70; Active; Boolean)
        {
            Caption = 'Активний';
            InitValue = true;
        }

        field(80; "Resolution Trace"; Text[2048])
        {
            Caption = 'Трасування визначення отримувача';
            DataClassification = CustomerContent;
        }

        field(90; "Source Reference"; Text[250])
        {
            Caption = 'Посилання на джерело визначення';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }

        key(SecurityID; "Security ID")
        {
        }

        key(UserName; "User Name")
        {
        }

        key(RecipientGroup; "Recipient Group Code", "Security ID")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "User Name", "Display Name", "Recipient Group Code")
        {
        }
    }
}