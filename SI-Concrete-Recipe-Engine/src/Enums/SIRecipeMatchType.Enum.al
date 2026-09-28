namespace STROYINVEST.ConcreteRecipeEngine;

enum 62006 "SI Recipe Match Type"
{
    Extensible = false;
    Caption = 'Тип відповідності рецептури';

    value(0; Exact)
    {
        Caption = 'Точний продукт';
    }
    value(1; "Base Fallback")
    {
        Caption = 'Резервна базова рецептура';
    }
}
