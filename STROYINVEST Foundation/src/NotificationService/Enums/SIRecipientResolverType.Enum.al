enum 50203 "SI Recipient Resolver Type"
{
    Extensible = true;
    Caption = 'Тип визначення отримувачів';

    value(0; ExplicitUser)
    {
        Caption = 'Вказаний користувач';
    }

    value(1; UserGroup)
    {
        Caption = 'Група користувачів';
    }

    value(2; CustomProvider)
    {
        Caption = 'Зовнішній провайдер';
    }
}