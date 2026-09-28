table 52040 "SI Supply Decision Header"
{
    Caption = 'Рішення щодо забезпечення';
    DataClassification = CustomerContent;
    LookupPageId = "SI Supply Decisions";
    DrillDownPageId = "SI Supply Decisions";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = '№';
        }
        field(10; "Request No."; Code[20])
        {
            Caption = '№ заявки';
            TableRelation = "SI Request Header"."No.";
        }
        field(20; Status; Enum "SI Supply Decision Status")
        {
            Caption = 'Статус';
            Editable = false;
        }
        field(30; "Construction Object No."; Code[20])
        {
            Caption = 'Об''єкт будівництва';
            TableRelation = "SI Construction Object"."No.";
            Editable = false;
        }
        field(40; "Required Date"; Date)
        {
            Caption = 'Дата потреби';
            Editable = false;
        }
        field(50; "Created By"; Code[50])
        {
            Caption = 'Створено користувачем';
            TableRelation = User."User Name";
            Editable = false;
        }
        field(60; "Created At"; DateTime)
        {
            Caption = 'Дата й час створення';
            Editable = false;
        }
        field(70; "Completed By"; Code[50])
        {
            Caption = 'Опрацьовано користувачем';
            TableRelation = User."User Name";
            Editable = false;
        }
        field(80; "Completed At"; DateTime)
        {
            Caption = 'Дата й час опрацювання';
            Editable = false;
        }
        field(90; Comment; Text[250])
        {
            Caption = 'Коментар';
        }
    }

    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
        key(Request; "Request No.")
        {
            Unique = true;
        }
        key(Status; Status)
        {
        }
    }

    trigger OnInsert()
    begin
        if "Created By" = '' then
            "Created By" := CopyStr(UserId(), 1, MaxStrLen("Created By"));

        if "Created At" = 0DT then
            "Created At" := CurrentDateTime();

        if Status = Status::Cancelled then
            Status := Status::Draft;
    end;

    trigger OnDelete()
    var
        DecisionLine: Record "SI Supply Decision Line";
        Allocation: Record "SI Supply Allocation";
    begin
        TestField(Status, Status::Draft);

        Allocation.SetRange("Document No.", "No.");
        Allocation.DeleteAll(true);

        DecisionLine.SetRange("Document No.", "No.");
        DecisionLine.DeleteAll(true);
    end;
}
