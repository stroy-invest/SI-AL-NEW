tableextension 60002 "SI Job Task Ext." extends "Job Task"
{
    fields
    {
        field(60000; "SI Site Code"; Code[20])
        {
            Caption = 'Будівельний майданчик';
            DataClassification = CustomerContent;
            TableRelation = "SI Construction Site"."Site Code" where("Project No." = field("Job No."), Status = const(Active));

            trigger OnValidate()
            var
                Project: Record Job;
                Site: Record "SI Construction Site";
            begin
                if "SI Site Code" = '' then begin
                    if Project.Get("Job No.") and Project."SI Construction Project" then
                        Error('Для роботи будівельного проєкту SI будівельний майданчик є обов''язковим.');
                    exit;
                end;

                if not Project.Get("Job No.") then
                    exit;
                if not Project."SI Construction Project" then
                    Error('Будівельний майданчик SI можна вказувати лише для будівельного проєкту SI.');

                if not Site.Get("Job No.", "SI Site Code") then
                    Error('Будівельний майданчик %1 не належить проєкту %2.', "SI Site Code", "Job No.");
                if Site.Status <> Site.Status::Active then
                    Error('Для нових операцій можна використовувати лише активний будівельний майданчик. Майданчик %1 має стан %2.', Site.Name, Site.Status);
            end;
        }
        field(60001; "SI Lifecycle Status"; Enum "SI Object Lifecycle Status")
        {
            Caption = 'Стан SI';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                Project: Record Job;
            begin
                if not Project.Get("Job No.") then
                    exit;
                if not Project."SI Construction Project" then
                    exit;
                if "SI Lifecycle Status" = xRec."SI Lifecycle Status" then
                    exit;

                case xRec."SI Lifecycle Status" of
                    xRec."SI Lifecycle Status"::Active:
                        if "SI Lifecycle Status" <> "SI Lifecycle Status"::Freezed then
                            Error('Активну роботу можна лише заморозити.');
                    xRec."SI Lifecycle Status"::Freezed:
                        if not ("SI Lifecycle Status" in ["SI Lifecycle Status"::Active, "SI Lifecycle Status"::Annulated]) then
                            Error('Заморожену роботу можна відновити або анулювати.');
                    xRec."SI Lifecycle Status"::Annulated:
                        Error('Анульована робота є кінцевим станом і не може бути відновлена.');
                end;
            end;
        }
    }
}
