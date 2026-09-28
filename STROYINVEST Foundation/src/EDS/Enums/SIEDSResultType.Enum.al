enum 50401 "SI EDS Result Type"
{
    Extensible = true;
    Caption = 'EDS Result Type';

    value(0; Undefined)
    {
        Caption = 'Не визначено';
    }

    value(1; Success)
    {
        Caption = 'Успішно';
    }

    value(2; "Business Not Found")
    {
        Caption = 'Дані не знайдено';
    }

    value(3; "Business Rejected")
    {
        Caption = 'Відхилено зовнішнім сервісом';
    }

    value(4; "Technical Failure")
    {
        Caption = 'Технічна помилка';
    }

    value(5; "Authentication Failure")
    {
        Caption = 'Помилка авторизації';
    }

    value(6; "Rate Limited")
    {
        Caption = 'Перевищено ліміт запитів';
    }

    value(7; "Invalid Response")
    {
        Caption = 'Некоректна відповідь';
    }
}