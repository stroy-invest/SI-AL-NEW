table 50782 "SI EDS Transport Preview"
{
    Caption = 'EDS: попередній перегляд';
    DataClassification = CustomerContent;
    fields
    {
        field(1; "Entry No."; Integer) { Caption = '№'; }
        field(2; "Entity Name"; Text[100]) { Caption = 'Сутність'; }
        field(3; "Record Key"; Text[250]) { Caption = 'Ключ запису'; }
        field(4; "Field No."; Text[10]) { Caption = '№ поля'; }
        field(5; "Field Caption"; Text[150]) { Caption = 'Поле'; }
        field(6; "Current Value"; Text[2048]) { Caption = 'Поточне значення'; }
        field(7; "Package Value"; Text[2048]) { Caption = 'Значення пакета'; }
        field(8; Status; Option) { Caption = 'Стан'; OptionMembers = Create,Update,Unchanged; OptionCaption = 'Створити,Оновити,Без змін'; }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}
