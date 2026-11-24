pageextension 50504 "SI Locations Ext." extends "Location List"
{
    layout
    {
        addafter(Name)
        {
            field("SI Location Spec. Code"; Rec."SI Location Spec. Code")
            {
                ApplicationArea = All;
                ToolTip = 'Спеціалізація складу незалежно від його функціонального типу.';
            }
            field("SI Location Type Code"; Rec."SI Location Type Code")
            {
                ApplicationArea = All;
                ToolTip = 'Визначає бізнесовий тип складу для маршрутизації та правил процесів STROYINVEST.';
            }
        }
    }
}
