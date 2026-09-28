pageextension 50162 "SI Item Categories Default UoM" extends "Item Categories"
{
    layout
    {
        addafter(Description)
        {
            field("SI Default Base UoM Code"; Rec."SI Default Base UoM Code")
            {
                ApplicationArea = All;
                ToolTip = 'Визначає стандартну базову одиницу виміру, яка автоматично призначається до нових товарів, створених у цій категорії товарів.';
            }
        }
    }
}