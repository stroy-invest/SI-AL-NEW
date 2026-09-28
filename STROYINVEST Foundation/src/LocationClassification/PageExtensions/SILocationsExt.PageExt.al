pageextension 50504 "SI Locations Ext." extends "Location List"
{
    layout
    {
        addafter(Name)
        {
            field("SI Location Type Code"; Rec."SI Location Type Code")
            {
                ApplicationArea = All;
                ToolTip = 'Визначає бізнесовий тип складу для маршрутизації та правил процесів STROYINVEST.';
            }
        }
    }
}
