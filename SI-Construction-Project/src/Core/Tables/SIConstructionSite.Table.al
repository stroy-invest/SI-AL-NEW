table 60013 "SI Construction Site"
{
    Caption = 'Будівельний майданчик SI';
    DataClassification = CustomerContent;
    LookupPageId = "SI Construction Sites";
    DrillDownPageId = "SI Construction Sites";

    fields
    {
        field(1; "Project No."; Code[20])
        {
            Caption = '№ проєкту';
            TableRelation = Job."No." where("SI Construction Project" = const(true));

            trigger OnValidate()
            var
                Project: Record Job;
            begin
                if "Project No." = '' then
                    exit;
                Project.Get("Project No.");
                if not Project."SI Construction Project" then
                    Error('Проєкт %1 не є будівельним проєктом SI.', "Project No.");
            end;
        }
        field(2; "Site Code"; Code[20])
        {
            Caption = 'Код майданчика';
        }
        field(3; Name; Text[100])
        {
            Caption = 'Назва';
        }
        field(4; Description; Text[250])
        {
            Caption = 'Опис';
        }
        field(5; "Default"; Boolean)
        {
            Caption = 'Основний';

            trigger OnValidate()
            var
                OtherSite: Record "SI Construction Site";
            begin
                if not "Default" then
                    exit;

                if Status <> Status::Active then
                    Error('Основним може бути лише активний будівельний майданчик.');

                OtherSite.SetRange("Project No.", "Project No.");
                OtherSite.SetRange("Default", true);
                OtherSite.SetFilter("Site Code", '<>%1', "Site Code");
                if OtherSite.FindFirst() then
                    Error(
                        'Для проєкту %1 уже визначено основний будівельний майданчик %2 (%3).',
                        "Project No.", OtherSite.Name, OtherSite."Site Code");
            end;
        }
        field(6; Status; Enum "SI Object Lifecycle Status")
        {
            Caption = 'Стан';

            trigger OnValidate()
            begin
                if Status = xRec.Status then
                    exit;

                case xRec.Status of
                    xRec.Status::Active:
                        if Status <> Status::Freezed then
                            Error('Активний майданчик можна лише заморозити.');
                    xRec.Status::Freezed:
                        if not (Status in [Status::Active, Status::Annulated]) then
                            Error('Заморожений майданчик можна відновити або анулювати.');
                    xRec.Status::Annulated:
                        Error('Анульований майданчик є кінцевим станом і не може бути відновлений.');
                end;

                if "Default" and (Status <> Status::Active) then
                    Error('Основний майданчик не можна заморозити або анулювати. Спочатку призначте інший активний майданчик основним.');
            end;
        }
        field(10; Address; Text[100])
        {
            Caption = 'Адреса';
        }
        field(11; "Address 2"; Text[50])
        {
            Caption = 'Адреса 2';
        }
        field(12; City; Text[30])
        {
            Caption = 'Місто';
        }
        field(13; "Post Code"; Code[20])
        {
            Caption = 'Поштовий індекс';
            TableRelation = "Post Code".Code;
        }
        field(14; County; Text[30])
        {
            Caption = 'Область';
        }
        field(15; "Country/Region Code"; Code[10])
        {
            Caption = 'Код країни/регіону';
            TableRelation = "Country/Region".Code;
        }
    }

    keys
    {
        key(PK; "Project No.", "Site Code")
        {
            Clustered = true;
        }
        key(ProjectDefault; "Project No.", "Default") { }
        key(ProjectStatus; "Project No.", Status) { }
    }

    trigger OnInsert()
    var
        SiteMgt: Codeunit "SI Construction Site Mgt.";
    begin
        TestField("Project No.");
        if "Site Code" = '' then
            "Site Code" := SiteMgt.GetNextSiteCode("Project No.");
        TestField(Name);
        Status := Status::Active;
    end;

    trigger OnDelete()
    begin
        Error(
            'Будівельний майданчик %1 (%2) не може бути фізично видалений. Використовуйте стани Заморожений та Анульований.',
            Name, "Site Code");
    end;

    trigger OnRename()
    begin
        Error('Код будівельного майданчика є системним і не може бути змінений.');
    end;
}
