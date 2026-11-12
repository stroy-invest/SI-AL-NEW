table 60024 "SI Project Wizard Buffer"
{
    Caption = 'Буфер створення проєкту';
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { Caption = '№ запису'; }
        field(2; "Short Name"; Text[100]) { Caption = 'Коротка назва'; }
        field(3; "Full Name"; Text[250]) { Caption = 'Повна назва'; }
        field(4; "Customer No."; Code[20])
        {
            Caption = 'Замовник';
            TableRelation = Customer."No.";
        }
        field(5; "Starting Date"; Date) { Caption = 'Дата початку'; }
        field(6; "Planned Ending Date"; Date) { Caption = 'Планове завершення'; }
        field(7; "Manager No."; Code[20])
        {
            Caption = 'Керівник проєкту';
            TableRelation = Employee."No.";
        }
        field(10; "Country/Region Code"; Code[10])
        {
            Caption = 'Країна/регіон';
            TableRelation = "Country/Region".Code;
        }
        field(11; "Post Code"; Code[20]) { Caption = 'Поштовий індекс'; }
        field(12; County; Text[30]) { Caption = 'Область'; }
        field(13; District; Text[100]) { Caption = 'Район'; }
        field(14; City; Text[30]) { Caption = 'Місто / населений пункт'; }
        field(15; Address; Text[100]) { Caption = 'Адреса'; }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}
