namespace STROYINVEST.ConcreteRecipeEngine;

enum 62010 "SI Recipe Purpose"
{
    Extensible = false;
    Caption = 'Призначення рецептури';

    value(0; Commercial)
    {
        Caption = 'Товарна';
    }
    value(1; Technological)
    {
        Caption = 'Технологічна';
    }
}
