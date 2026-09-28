enum 50460 "SI EDS Credential Type"
{
    Extensible = true;
    Caption = 'Тип облікових даних EDS';

    value(0; Password)
    {
        Caption = 'Пароль';
    }
    value(1; "API Key")
    {
        Caption = 'Ключ API';
    }
    value(2; "Client Secret")
    {
        Caption = 'Секрет клієнта';
    }
    value(3; "Access Token")
    {
        Caption = 'Токен доступу';
    }
    value(4; "Refresh Token")
    {
        Caption = 'Токен оновлення';
    }
    value(5; "Session Secret")
    {
        Caption = 'Секрет сеансу';
    }
    value(99; Custom)
    {
        Caption = 'Інший';
    }
}
