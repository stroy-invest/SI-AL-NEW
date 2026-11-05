enum 57105 "SI Prok Execution Evidence"
{
    Extensible = false;
    value(0; NotAssessed) { Caption = 'Перевірку не виконано'; }
    value(1; Unavailable) { Caption = 'Фактичні показники відсутні'; }
    value(2; ZeroObserved) { Caption = 'Отримані фактичні показники нульові'; }
    value(3; PositiveObserved) { Caption = 'Є позитивні показники подачі'; }
    value(4; Inconsistent) { Caption = 'Некоректні або суперечливі показники'; }
}
