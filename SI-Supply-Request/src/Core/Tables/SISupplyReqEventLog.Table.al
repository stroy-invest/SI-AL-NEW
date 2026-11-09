table 61091 "SI Supply Req Event Log"
{
    Caption = 'Журнал подій заявок';
    DataClassification = CustomerContent;
    LookupPageId = "SI Supply Req Event Log";
    DrillDownPageId = "SI Supply Req Event Log";

    fields
    {
        field(1; "Entry No."; Integer) { Caption = 'Номер запису'; AutoIncrement = true; }
        field(2; "Request No."; Code[20]) { Caption = 'Номер заявки'; DataClassification = CustomerContent; }
        field(3; "Event Type"; Enum "SI Supply Req Event Type") { Caption = 'Тип події'; }
        field(4; "Event At"; DateTime) { Caption = 'Дата й час події'; }
        field(5; "User ID"; Code[50]) { Caption = 'Користувач'; DataClassification = EndUserIdentifiableInformation; }
        field(6; "Field Name"; Text[100]) { Caption = 'Поле'; }
        field(7; "Old Value"; Text[250]) { Caption = 'Попереднє значення'; DataClassification = CustomerContent; }
        field(8; "New Value"; Text[250]) { Caption = 'Нове значення'; DataClassification = CustomerContent; }
        field(9; Reason; Text[1024]) { Caption = 'Причина'; DataClassification = CustomerContent; }
        field(10; Details; Text[2048]) { Caption = 'Деталі'; DataClassification = CustomerContent; }
        field(11; "Correlation ID"; Guid) { Caption = 'Ідентифікатор операції'; }
    }
    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(RequestHistory; "Request No.", "Event At") { }
        key(OperationHistory; "Correlation ID") { }
    }
}
