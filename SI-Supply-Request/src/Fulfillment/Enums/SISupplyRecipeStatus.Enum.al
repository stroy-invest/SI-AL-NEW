enum 61013 "SI Supply Recipe Status"
{
    Extensible = false;
    Caption = 'Статус визначення рецептури';

    value(0; "Not Resolved") { Caption = 'Не визначено'; }
    value(10; Resolved) { Caption = 'Визначено'; }
    value(20; Ambiguous) { Caption = 'Потрібен вибір'; }
    value(30; Blocked) { Caption = 'Заблоковано'; }
    value(40; "Revalidation Required") { Caption = 'Потрібна повторна перевірка'; }
}
