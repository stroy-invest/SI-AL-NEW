enum 50406 "SI EDS Log Cleanup Filter"
{
    Extensible = false;
    Caption = 'Фільтр очищення журналу EDS';

    value(0; All)
    {
        Caption = 'Усі';
    }

    value(1; Errors)
    {
        Caption = 'Помилки';
    }

    value(2; Success)
    {
        Caption = 'Успішні';
    }
}
