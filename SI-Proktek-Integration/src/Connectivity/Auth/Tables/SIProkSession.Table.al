table 57051 "SI Prok Session"
{
    Caption = 'Сеанси Proktek';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Connection Code"; Code[50])
        {
            Caption = 'Профіль підключення';
            TableRelation = "SI Prok Connection".Code;
        }
        field(10; "Session GUID"; Guid)
        {
            Caption = 'GUID сеансу';
        }
        field(11; "Expires At"; DateTime)
        {
            Caption = 'Дійсний до';
        }
        field(12; "Expires At Raw"; Text[80])
        {
            Caption = 'Дійсний до (API)';
        }
        field(13; Username; Text[100])
        {
            Caption = 'Користувач';
        }
        field(14; "Plant IDs"; Text[2048])
        {
            Caption = 'Ідентифікатори вузлів';
        }
        field(15; "Scale IDs"; Text[2048])
        {
            Caption = 'Ідентифікатори ваг';
        }
        field(16; "Logged In At"; DateTime)
        {
            Caption = 'Час входу';
        }
        field(17; "Response Message"; Text[2048])
        {
            Caption = 'Повідомлення Proktek';
        }
    }

    keys
    {
        key(PK; "Connection Code")
        {
            Clustered = true;
        }
    }

    procedure IsUsable(): Boolean
    begin
        if IsNullGuid("Session GUID") then
            exit(false);

        // Якщо expires_at успішно розібрано,
        // перевіряємо реальний строк дії сеансу.
        if "Expires At" <> 0DT then
            exit(CurrentDateTime < "Expires At");

        // Якщо API повернув expires_at, але BC поки не зміг
        // перетворити його на DateTime, сам GUID усе одно
        // вважаємо придатним до першої відмови API.
        //
        // Це важливо, щоб проблема локального parsing DateTime
        // не змушувала нас логінитися перед кожним request.
        exit(true);
    end;

    procedure ClearSession()
    begin
        Clear("Session GUID");
        "Expires At" := 0DT;
        Clear("Expires At Raw");
        Clear(Username);
        Clear("Plant IDs");
        Clear("Scale IDs");
        "Logged In At" := 0DT;
        Clear("Response Message");
        Modify(false);
    end;
}