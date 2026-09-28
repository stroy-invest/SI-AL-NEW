table 61003 "SI Supply Req Parameter"
{
    Caption = 'Параметр заявки на забезпечення';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Request No."; Code[20])
        {
            Caption = '№ заявки';
            TableRelation = "SI Supply Req Header"."No.";
        }
        field(2; "Request Line No."; Integer)
        {
            Caption = '№ рядка';
            TableRelation = "SI Supply Req Line"."Line No." where("Request No." = field("Request No."));
        }
        field(10; "Parameter Code"; Code[50])
        {
            Caption = 'Код параметра';
        }
        field(20; "Value Type"; Enum "SI Supply Req Param Value Type")
        {
            Caption = 'Тип значення';
        }
        field(30; "Requested Code Value"; Code[100])
        {
            Caption = 'Запитане значення (код)';
        }
        field(40; "Requested Decimal Value"; Decimal)
        {
            Caption = 'Запитане значення (число)';
            DecimalPlaces = 0 : 5;
        }
        field(50; "Requested Text Value"; Text[250])
        {
            Caption = 'Запитане значення (текст)';
        }
        field(60; "Requested Bool Value"; Boolean)
        {
            Caption = 'Запитане значення (Так/Ні)';
        }
        field(70; "Requested Date Value"; Date)
        {
            Caption = 'Запитане значення (дата)';
        }
        field(80; "Requested DateTime Value"; DateTime)
        {
            Caption = 'Запитане значення (дата й час)';
        }
        field(90; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Од. вим.';
            TableRelation = "Unit of Measure".Code;
        }
        field(100; Source; Enum "SI Supply Req Param Source")
        {
            Caption = 'Джерело';
        }
        field(110; "Created At"; DateTime)
        {
            Caption = 'Створено';
            Editable = false;
        }
        field(120; "Created By User ID"; Code[50])
        {
            Caption = 'Створено користувачем';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Request No.", "Request Line No.", "Parameter Code") { Clustered = true; }
    }

    trigger OnInsert()
    begin
        TestHeaderEditable();
        if "Created At" = 0DT then
            "Created At" := CurrentDateTime();
        if "Created By User ID" = '' then
            "Created By User ID" := CopyStr(UserId(), 1, MaxStrLen("Created By User ID"));
    end;

    trigger OnModify()
    begin
        TestHeaderEditable();
    end;

    trigger OnDelete()
    begin
        TestHeaderEditable();
    end;

    local procedure TestHeaderEditable()
    var
        Header: Record "SI Supply Req Header";
    begin
        if Header.Get("Request No.") then
            Header.TestEditable();
    end;
}
