table 52005 "SI Request Header"
{
    Caption = 'Заявка на постачання';
    DataClassification = CustomerContent;
    LookupPageId = "SI Request List";
    DrillDownPageId = "SI Request List";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
        }

        field(20; "Creation Date"; Date)
        {
            Caption = 'Дата створення';
        }

        field(30; "Execution Date"; Date)
        {
            Caption = 'Дата виконання';
        }

        field(40; "Construction Object No."; Code[20])
        {
            Caption = 'Об''єкт будівництва';
            TableRelation = "SI Construction Object"."No.";
        }

        field(60; "Requester User ID"; Code[50])
        {
            Caption = 'Requester User ID';
            TableRelation = User."User Name";
        }

        field(65; "Requester Employee No."; Code[20])
        {
            Caption = 'Співробітник-заявник';
            TableRelation = Employee."No.";
        }

        field(66; "Requester Employee Name"; Text[100])
        {
            Caption = 'ПІБ заявника';
            Editable = false;
        }

        field(70; Status; Enum "SI Request Status")
        {
            Caption = 'Статус';
        }

        field(90; Comment; Text[250])
        {
            Caption = 'Коментар';
        }

        field(100; "Submitted At"; DateTime)
        {
            Caption = 'Дата подання';
        }

        field(110; "Submitted By"; Code[50])
        {
            Caption = 'Подано користувачем';
            TableRelation = User."User Name";
        }

        field(120; "Approved At"; DateTime)
        {
            Caption = 'Дата схвалення';
        }

        field(130; "Approved By"; Code[50])
        {
            Caption = 'Схвалено користувачем';
            TableRelation = User."User Name";
        }
    }

    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }

        key(Status; Status)
        {
        }

        key(ExecutionDate; "Execution Date")
        {
        }

        key(Requester; "Requester User ID")
        {
        }
    }

    trigger OnInsert()
    var
        RequestNoMgt: Codeunit "SI Request No. Mgt.";
        RequestStatusMgt: Codeunit "SI Request Status Mgt.";
    begin
        RequestNoMgt.InitRequestNo(Rec);

        if "Creation Date" = 0D then
            "Creation Date" := Today();

        if "Requester User ID" = '' then
            "Requester User ID" := CopyStr(UserId(), 1, MaxStrLen("Requester User ID"));

        ApplyRequesterSetup();

        RequestStatusMgt.LogCreate(Rec);
    end;

    local procedure ApplyRequesterSetup()
    var
        RequesterSetup: Record "SI Requester Setup";
    begin
        if "Requester User ID" = '' then
            exit;

        if not RequesterSetup.Get("Requester User ID") then
            exit;

        if not RequesterSetup.Active then
            exit;

        "Requester Employee No." := RequesterSetup."Employee No.";
        SetRequesterEmployeeName();
        "Construction Object No." := RequesterSetup."Construction Object No.";
    end;

    local procedure SetRequesterEmployeeName()
    var
        Employee: Record Employee;
    begin
        "Requester Employee Name" := '';

        if "Requester Employee No." = '' then
            exit;

        if not Employee.Get("Requester Employee No.") then
            exit;

        "Requester Employee Name" :=
            CopyStr(Employee.FullName(), 1, MaxStrLen("Requester Employee Name"));
    end;
}
