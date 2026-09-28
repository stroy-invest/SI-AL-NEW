namespace STROYINVEST.ConcreteRecipeEngine;

permissionset 62300 "SI RECIPE ADMIN"
{
    Assignable = true;
    Caption = 'SI Recipe Engine — адміністратор';

    Permissions =
        table "SI Concrete Recipe" = X,
        tabledata "SI Concrete Recipe" = RIMD,
        table "SI Concrete Recipe Revision" = X,
        tabledata "SI Concrete Recipe Revision" = RIMD,
        table "SI Concrete Recipe Line" = X,
        tabledata "SI Concrete Recipe Line" = RIMD,
        table "SI Concrete Recipe Setup" = X,
        tabledata "SI Concrete Recipe Setup" = RIMD,
        table "SI Recipe Resolver Result" = X,
        table "SI Recipe Admin History" = X,
        tabledata "SI Recipe Admin History" = RIMD,
        tabledata "SI Recipe Resolver Result" = RIMD,
        page "SI Concrete Recipes" = X,
        page "SI Concrete Recipe Card" = X,
        page "SI Recipe Revisions Part" = X,
        page "SI Recipe Revision Card" = X,
        page "SI Recipe Lines Part" = X,
        page "SI Recipe Setup" = X,
        page "SI Recipe Product Selector" = X,
        page "SI Recipe Candidates" = X,
        page "SI Recipe Resolve Date" = X,
        page "SI Concrete Recipes Tree" = X,
        page "SI Recipe Admin History" = X,
        codeunit "SI Recipe Creation Mgt." = X,
        codeunit "SI Recipe Lifecycle Mgt." = X,
        codeunit "SI Recipe Upgrade" = X,
        codeunit "SI Recipe BOM Resolver" = X,
        codeunit "SI Recipe BOM Projection" = X,
        codeunit "SI Recipe Resolver" = X,
        codeunit "SI Recipe Workspace Mgt." = X;
}
