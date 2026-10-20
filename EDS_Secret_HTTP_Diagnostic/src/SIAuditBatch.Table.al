table 70003 "SI Audit Batch"
{
    Caption = 'Пакет перевірки ЄДРПОУ';
    DataClassification = CustomerContent;
    fields
    {
        field(1; "No."; Code[20]) { Caption = 'Пакет'; }
        field(2; Description; Text[150]) { Caption = 'Опис'; }
        field(3; Status; Option) { Caption = 'Стан'; OptionMembers = Draft,Ready,Running,Completed,Stopped; OptionCaption = 'Чернетка,Готовий,Виконується,Завершено,Зупинено'; }
        field(4; "Created At"; DateTime) { Caption = 'Створено'; }
        field(5; "Provider Code"; Code[50]) { Caption = 'Провайдер'; }
        field(6; "Request Interval Sec."; Integer) { Caption = 'Інтервал між запитами (с)'; InitValue = 12; }
        field(7; "Batch Size"; Integer) { Caption = 'Запитів за запуск'; InitValue = 5; }
        field(8; "EDS Service Code"; Code[50]) { Caption = 'EDS Service'; InitValue = 'UA-REGISTRY'; }
        field(9; "EDS Operation Code"; Code[50]) { Caption = 'EDS Operation'; }
        field(10; "EDS Runtime Key"; Code[50]) { Caption = 'Ключ параметра ЄДРПОУ'; }
    }
    keys { key(PK; "No.") { Clustered = true; } }
    trigger OnInsert()
    begin
        if "Created At" = 0DT then
            "Created At" := CurrentDateTime();
    end;
}
