namespace STROYINVEST.ConcreteRecipeEngine;

enum 62007 "SI Recipe Resolve Outcome"
{
    Extensible = false;
    Caption = 'Результат визначення рецептури';

    value(0; "No Recipe")
    {
        Caption = 'Немає рецептури';
    }
    value(1; "No Applicable Revision")
    {
        Caption = 'Немає актуальної ревізії';
    }
    value(2; "Single Candidate")
    {
        Caption = 'Один кандидат';
    }
    value(3; "Multiple Candidates")
    {
        Caption = 'Кілька кандидатів';
    }
}
