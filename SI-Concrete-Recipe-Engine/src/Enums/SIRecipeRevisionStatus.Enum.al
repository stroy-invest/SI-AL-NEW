namespace STROYINVEST.ConcreteRecipeEngine;

enum 62001 "SI Recipe Revision Status"
{
    Extensible = false;
    Caption = 'Статус ревізії рецептури';

    value(0; Draft)
    {
        Caption = 'Чернетка';
    }
    value(1; Certified)
    {
        Caption = 'Сертифікована';
    }
    value(2; Closed)
    {
        Caption = 'Закрита';
    }
}
