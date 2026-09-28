namespace STROYINVEST.ConcreteRecipeEngine;

enum 62004 "SI Recipe Admin Status"
{
    Extensible = false;
    Caption = 'Адміністративний статус рецептури';

    value(0; Active)
    {
        Caption = 'Активна';
    }
    value(1; Inactive)
    {
        Caption = 'Неактивна';
    }
}
