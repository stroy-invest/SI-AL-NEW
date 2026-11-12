table 60025 "SI Project Wizard Site"
{
    Caption = 'Майданчик майстра проєкту';
    TableType = Temporary;
    DataClassification = CustomerContent;
    fields
    {
        field(1; "Line No."; Integer) { Caption = '№ рядка'; }
        field(2; Name; Text[100]) { Caption = 'Назва майданчика'; }
        field(3; Description; Text[250]) { Caption = 'Опис'; }
        field(4; "Default"; Boolean) { Caption = 'Основний'; Editable = false; }
        field(5; "Foreman No."; Code[20]) { Caption = 'Виконроб'; TableRelation = Employee."No."; }
        field(10; "Country/Region Code"; Code[10]) { Caption = 'Країна/регіон'; TableRelation = "Country/Region".Code; }
        field(11; "Post Code"; Code[20]) { Caption = 'Поштовий індекс'; }
        field(12; County; Text[30]) { Caption = 'Область'; }
        field(13; District; Text[100]) { Caption = 'Район'; }
        field(14; City; Text[30]) { Caption = 'Місто'; }
        field(15; Address; Text[100]) { Caption = 'Адреса'; }
        field(16; "Address Customized"; Boolean) { Caption = 'Адресу змінено вручну'; Editable = false; }
    }
    keys { key(PK; "Line No.") { Clustered = true; } }
}
