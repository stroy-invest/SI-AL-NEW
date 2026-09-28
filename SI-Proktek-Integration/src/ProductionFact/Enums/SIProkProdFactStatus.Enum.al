enum 57091 "SI Prok Prod Fact Status"
{
    Extensible = false;

    value(0; Received) { Caption = 'Отримано'; }
    value(1; Partial) { Caption = 'Часткове виробництво'; }
    value(2; Complete) { Caption = 'Виконано'; }
    value(3; Overproduced) { Caption = 'Перевиробництво'; }
    value(4; Blocked) { Caption = 'Заблоковано'; }
}
