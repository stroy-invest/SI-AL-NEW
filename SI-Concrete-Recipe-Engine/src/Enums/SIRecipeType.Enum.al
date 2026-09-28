namespace STROYINVEST.ConcreteRecipeEngine;

enum 62000 "SI Recipe Type"
{
    Extensible = false;
    Caption = 'Тип рецептури';

    value(0; Base)
    {
        Caption = 'Базова';
    }
    value(1; Variant)
    {
        Caption = 'Варіант';
    }
}
