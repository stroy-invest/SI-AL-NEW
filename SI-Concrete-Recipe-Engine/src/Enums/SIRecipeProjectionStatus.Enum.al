namespace STROYINVEST.ConcreteRecipeEngine;

enum 62003 "SI Recipe Projection Status"
{
    Extensible = false;
    Caption = 'Статус проєкції рецептури';

    value(0; "Not Projected")
    {
        Caption = 'Не спроєктовано';
    }
    value(1; Pending)
    {
        Caption = 'Очікує';
    }
    value(2; Projected)
    {
        Caption = 'Спроєктовано';
    }
    value(3; Error)
    {
        Caption = 'Помилка';
    }
}
