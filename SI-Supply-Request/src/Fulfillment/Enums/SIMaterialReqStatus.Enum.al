enum 61015 "SI Material Req Status"
{
    Extensible = true;
    Caption = 'Статус потреби в матеріалах';

    value(0; "Not Calculated") { Caption = 'Не розраховано'; }
    value(1; Available) { Caption = 'Забезпечено'; }
    value(2; Shortage) { Caption = 'Є дефіцит'; }
    value(3; Error) { Caption = 'Помилка'; }
}
