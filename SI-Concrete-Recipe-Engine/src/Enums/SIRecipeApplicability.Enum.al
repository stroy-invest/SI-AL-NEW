namespace STROYINVEST.ConcreteRecipeEngine;

enum 62005 "SI Recipe Applicability"
{
    Extensible = false;
    Caption = 'Актуальність рецептури';

    value(0; Future)
    {
        Caption = 'Майбутня';
    }
    value(1; Applicable)
    {
        Caption = 'Актуальна';
    }
    value(2; Expired)
    {
        Caption = 'Прострочена';
    }
    value(3; Inactive)
    {
        Caption = 'Неактуальна';
    }
}
