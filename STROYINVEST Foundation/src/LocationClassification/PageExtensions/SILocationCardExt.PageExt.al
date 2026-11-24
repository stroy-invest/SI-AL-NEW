pageextension 50503 "SI Location Card Ext." extends "Location Card"
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
