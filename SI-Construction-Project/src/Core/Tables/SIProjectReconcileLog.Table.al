table 60030 "SI Project Reconcile Log"
{
    Caption = 'Журнал перевірки проєктів';
    DataClassification = CustomerContent;
    fields
    {
        field(1; "Entry No."; Integer) { Caption = '№ запису'; AutoIncrement = true; }
        field(2; "Run ID"; Guid) { Caption = 'Ідентифікатор запуску'; }
        field(3; "Created At"; DateTime) { Caption = 'Дата й час'; }
        field(4; "Project No."; Code[20]) { Caption = 'Проєкт'; }
        field(5; "Site Code"; Code[20]) { Caption = 'Майданчик'; }
        field(6; Result; Option) { Caption = 'Результат'; OptionMembers = Success,Error; OptionCaption = 'Успішно,Помилка'; }
        field(7; Details; Text[2048]) { Caption = 'Деталі'; }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } key(Run; "Run ID", "Project No.") { } }
}
