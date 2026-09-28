table 61048 "SI Proc. Plan Run"
{
    Caption = 'Запуски планування закупівель';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Run No."; Integer) { Caption = '№ запуску'; AutoIncrement = true; }
        field(10; "Created At"; DateTime) { Caption = 'Створено'; }
        field(11; "Created By"; Code[50]) { Caption = 'Користувач'; }
        field(20; "Planning Start Date"; Date) { Caption = 'Початок планування'; }
        field(21; "Planning End Date"; Date) { Caption = 'Кінець планування'; }
        field(30; "Forecast Name"; Code[10]) { Caption = 'Прогноз'; }
        field(31; "Worksheet Template Name"; Code[10]) { Caption = 'Шаблон аркуша'; }
        field(32; "Worksheet Batch Name"; Code[10]) { Caption = 'Пакет аркуша'; }
        field(40; "Line Count"; Integer) { Caption = 'Рядків результату'; }
        field(41; "Trace Link Count"; Integer) { Caption = 'Зв’язків із потребами'; }
        field(50; Current; Boolean) { Caption = 'Поточний'; }
    }

    keys
    {
        key(PK; "Run No.") { Clustered = true; }
        key(CurrentRun; Current, "Run No.") { }
    }
}
