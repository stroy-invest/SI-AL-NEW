table 61001 "SI Supply Req Header"
{
    Caption = 'Заявка на забезпечення';
    DataClassification = CustomerContent;
    LookupPageId = "SI Supply Req List";
    DrillDownPageId = "SI Supply Req List";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = '№';
        }
        field(10; "Request Type"; Enum "SI Supply Req Type")
        {
            Caption = 'Тип заявки';
        }
        field(20; "Project No."; Code[20])
        {
            Caption = 'Проєкт';
            TableRelation = Job."No.";

            trigger OnValidate()
            var
                Project: Record Job;
                RequestSiteMgt: Codeunit "SI Supply Request Site Mgt.";
            begin
                if "Project No." = '' then begin
                    "Project Location Code" := '';
                    RequestSiteMgt.ClearSites("No.");
                    exit;
                end;

                Project.Get("Project No.");
                Project.TestField("Location Code");
                "Project Location Code" := Project."Location Code";

                // If the header already exists, materialize site context immediately.
                // For programmatic creation that validates Project before Insert,
                // OnInsert performs the same initialization after No. is assigned.
                if "No." <> '' then
                    RequestSiteMgt.InitializeForProject("No.", "Project No.");
            end;
        }
        field(30; "Project Location Code"; Code[10])
        {
            Caption = 'Склад / майданчик проєкту';
            TableRelation = Location.Code;
            Editable = false;
        }
        field(40; "Request Date"; Date)
        {
            Caption = 'Дата заявки';
        }
        field(50; "Required on Site Date"; Date)
        {
            Caption = 'Потрібно на об''єкті (legacy)';
            ObsoleteState = Pending;
            ObsoleteReason = 'Replaced by Required on Site At with DateTime precision.';
        }
        field(51; "Required on Site At"; DateTime)
        {
            Caption = 'Дата потреби';

            trigger OnValidate()
            begin
                ValidateRequiredOnSiteAt("Required on Site At");
            end;
        }
        field(60; Status; Enum "SI Supply Req Status")
        {
            Caption = 'Статус';
            Editable = false;
        }
        field(70; "Requested By User ID"; Code[50])
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
        field(90; Description; Text[250])
        {
            Caption = 'Обґрунтування / опис потреби';
        }
        field(100; "Request Profile"; Enum "SI Supply Req Profile")
        {
            Caption = 'Профіль заявки';
        }
        field(110; "Source Type"; Enum "SI Supply Req Source Type")
        {
            Caption = 'Джерело';
            Editable = false;
        }
        field(120; "External System Code"; Code[20])
        {
            Caption = 'Зовнішня система';
            Editable = false;
        }
        field(130; "External Document ID"; Text[100])
        {
            Caption = 'ID зовнішнього документа';
            Editable = false;
        }
        field(140; "External Document No."; Text[100])
        {
            Caption = '№ зовнішнього документа';
            Editable = false;
        }
        field(150; "External Registered At"; DateTime)
        {
            Caption = 'Зареєстровано у зовнішній системі';
            Editable = false;
        }
        field(160; "Last External Sync At"; DateTime)
        {
            Caption = 'Остання синхронізація';
            Editable = false;
        }
        field(170; "External Sync Status"; Enum "SI Supply Req Ext Sync Status")
        {
            Caption = 'Статус синхронізації';
            Editable = false;
        }
        field(180; "External Sync Message"; Text[250])
        {
            Caption = 'Результат синхронізації';
            Editable = false;
        }
        field(190; "External Payload Hash"; Text[100])
        {
            Caption = 'Відбиток зовнішніх даних';
            Editable = false;
        }
        field(200; "Schrift Request"; Boolean)
        {
            Caption = 'Заявка Schrift';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
        key(Project; "Project No.", Status) { }
        key(RequiredDate; "Required on Site At") { }
        key(ExternalDocument; "External System Code", "External Document ID") { }
    }

    trigger OnInsert()
    var
        NoMgt: Codeunit "SI Supply Req No. Mgt.";
        RequestSiteMgt: Codeunit "SI Supply Request Site Mgt.";
    begin
        NoMgt.InitRequestNo(Rec);

        if "Project No." <> '' then
            RequestSiteMgt.InitializeForProject("No.", "Project No.");

        if "Request Date" = 0D then
            "Request Date" := Today();
        if "Requested By User ID" = '' then
            "Requested By User ID" := CopyStr(UserId(), 1, MaxStrLen("Requested By User ID"));
        if "Created At" = 0DT then
            "Created At" := CurrentDateTime();
    end;

    trigger OnModify()
    begin
        // The previous persisted state governs editability. This allows the controlled
        // Draft -> Approved transition itself, then locks the approved manual request.
        xRec.TestEditable();
    end;

    trigger OnDelete()
    var
        Line: Record "SI Supply Req Line";
        Parameter: Record "SI Supply Req Parameter";
        ConcreteSpec: Record "SI Concrete Supply Spec";
        RequestSite: Record "SI Supply Request Site";
        DecisionHeader: Record "SI Supply Decision Header";
    begin
        TestField(Status, Status::Draft);

        DecisionHeader.SetRange("Request No.", "No.");
        if not DecisionHeader.IsEmpty() then
            Error(RequestHasDecisionDeleteErr, "No.");
        Line.SetRange("Request No.", "No.");
        Line.DeleteAll(true);

        Parameter.SetRange("Request No.", "No.");
        Parameter.DeleteAll(true);

        if ConcreteSpec.Get("No.") then
            ConcreteSpec.Delete(true);

        RequestSite.SetRange("Request No.", "No.");
        RequestSite.DeleteAll();

    end;

    local procedure ValidateRequiredOnSiteAt(RequiredOnSiteAt: DateTime)
    begin
        if RequiredOnSiteAt = 0DT then
            Error('Необхідно вказати дату та час потреби на об''єкті.');

        if DT2Time(RequiredOnSiteAt) = 000000T then
            Error('Необхідно вказати точний час потреби на об''єкті. Значення 00:00 не допускається.');

        if RequiredOnSiteAt < CurrentDateTime() then
            Error('Дата та час потреби на об''єкті не можуть бути раніше поточного часу.');
    end;

    procedure MarkApproved()
    begin
        TestField(Status, Status::Draft);
        Status := Status::Approved;
        Modify(false);
    end;

    procedure TestEditable()
    begin
        if Status = Status::Draft then
            exit;

        // Temporary Schrift bridge: an externally approved Schrift request may be
        // completed/corrected in BC until fulfillment starts. Remove with the bridge.
        if "Schrift Request" and (Status = Status::Approved) then
            exit;

        Error('Заявку %1 не можна редагувати у статусі %2.', "No.", Format(Status));
    end;

    var
        RequestHasDecisionDeleteErr: Label 'Заявку %1 не можна видалити, оскільки для неї вже існує рішення щодо забезпечення. Скасуйте або закрийте заявку замість фізичного видалення.';

}
