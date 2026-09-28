namespace STROYINVEST.ConcreteRecipeEngine;

enum 62008 "SI Recipe Admin Action"
{
    Extensible = false;
    Caption = 'Адміністративна дія рецептури';

    value(0; Activated)
    {
        Caption = 'Активовано';
    }
    value(1; Deactivated)
    {
        Caption = 'Деактивовано';
    }
}
