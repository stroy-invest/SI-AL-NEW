table 61010 "SI Supply Decision Header"
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
            TableRelation = "SI Supply Req Header"."No.";
        }
        field(20; Status; Enum "SI Supply Decision Status")
        {
            Caption = 'Статус';
            Editable = false;
        }
        field(30; "Project No."; Code[20])
        {
            Caption = 'Проєкт';
            TableRelation = Job."No.";
            Editable = false;
        }
        field(40; "Project Location Code"; Code[10])
        {
            Caption = 'Склад / майданчик проєкту';
            TableRelation = Location.Code;
            Editable = false;
        }
        field(50; "Required on Site At"; DateTime)
        {
            Caption = 'Потрібно на об''єкті';
            Editable = false;
        }
        field(60; Comment; Text[250])
        {
            Caption = 'Коментар';
        }
        field(70; "Created By"; Code[50])
        {
            Caption = 'Створено користувачем';
            TableRelation = User."User Name";
            Editable = false;
        }
        field(80; "Created At"; DateTime)
        {
            Caption = 'Створено';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
        key(Request; "Request No.") { Unique = true; }
        key(Project; "Project No.", Status) { }
    }

    trigger OnInsert()
    begin
        if "Created By" = '' then
            "Created By" := CopyStr(UserId(), 1, MaxStrLen("Created By"));
        if "Created At" = 0DT then
            "Created At" := CurrentDateTime();
    end;

    trigger OnModify()
    begin
        TestEditable();
    end;

    trigger OnDelete()
    var
        DecisionLine: Record "SI Supply Decision Line";
        Allocation: Record "SI Supply Allocation";
    begin
        TestEditable();

        Allocation.SetRange("Decision No.", "No.");
        Allocation.DeleteAll(true);

        DecisionLine.SetRange("Decision No.", "No.");
        DecisionLine.DeleteAll(true);
    end;

    procedure MarkReady()
    begin
        TestField(Status, Status::Draft);
        Status := Status::Ready;
        // Controlled lifecycle transition. Do not run OnModify, which intentionally
        // protects every subsequent edit once the plan is frozen.
        Modify(false);
    end;

    procedure TestEditable()
    begin
        if Status <> Status::Draft then
            Error('Рішення %1 не можна редагувати у статусі %2.', "No.", Format(Status));
    end;
}
