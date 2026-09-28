namespace STROYINVEST.ConcreteRecipeEngine;

enum 62002 "SI Recipe Validity Type"
{
    Extensible = false;
    Caption = 'Тип валідності рецептури';

    value(0; Permanent)
    {
        Caption = 'Постійна';
    }
    value(1; Temporary)
    {
        Caption = 'Тимчасова';
    }
}
