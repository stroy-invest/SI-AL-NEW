enum 50405 "SI EDS Exec Log Result Filter"
{
    Extensible = false;
    Caption = 'Фільтр результату EDS';

    value(0; All)
    {
        Caption = 'Усі';
    }
    value(1; Undefined)
    {
        Caption = 'Не визначено';
    }
    value(2; Success)
    {
        Caption = 'Успішно';
    }
    value(3; "Business Not Found")
    {
        Caption = 'Дані не знайдено';
    }
    value(4; "Business Rejected")
    {
        Caption = 'Відхилено зовнішнім сервісом';
    }
    value(5; "Technical Failure")
    {
        Caption = 'Технічна помилка';
    }
    value(6; "Authentication Failure")
    {
        Caption = 'Помилка авторизації';
    }
    value(7; "Rate Limited")
    {
        Caption = 'Перевищено ліміт запитів';
    }
    value(8; "Invalid Response")
    {
        Caption = 'Некоректна відповідь';
    }
}
