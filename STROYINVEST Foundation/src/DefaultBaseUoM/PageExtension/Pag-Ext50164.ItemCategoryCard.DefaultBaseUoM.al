pageextension 50164 "SI Item Category Card Def UoM" extends "Item Category Card"
{
    layout
    {
        addafter(Description)
        {
            field("SI Default Base UoM Code"; Rec."SI Default Base UoM Code")
            {
                ApplicationArea = All;
                ToolTip = 'Визначає базову одиницю виміру, яка автоматично призначається новим товарам цієї категорії.';
            }
        }
    }
}