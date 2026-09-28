codeunit 60004 "SI Job Task Mgt."
{
    Permissions =
        tabledata "Job Task" = rim;

    procedure EnsureProjectTasksSite(Project: Record Job)
    var
        JobTask: Record "Job Task";
        DefaultSite: Record "SI Construction Site";
        SiteMgt: Codeunit "SI Construction Site Mgt.";
    begin
        if not Project."SI Construction Project" then
            exit;

        SiteMgt.EnsureDefaultSite(Project, DefaultSite);

        JobTask.SetRange("Job No.", Project."No.");
        JobTask.SetRange("SI Site Code", '');
        if JobTask.FindSet(true) then
            repeat
                JobTask."SI Site Code" := DefaultSite."Site Code";
                JobTask.Modify(true);
            until JobTask.Next() = 0;
    end;

    procedure ValidateProjectTasks(Project: Record Job)
    var
        JobTask: Record "Job Task";
        Site: Record "SI Construction Site";
    begin
        if not Project."SI Construction Project" then
            exit;

        JobTask.SetRange("Job No.", Project."No.");
        if JobTask.FindSet() then
            repeat
                JobTask.TestField("SI Site Code");
                if not Site.Get(Project."No.", JobTask."SI Site Code") then
                    Error('Робота %1 посилається на неіснуючий будівельний майданчик %2.', JobTask."Job Task No.", JobTask."SI Site Code");
            until JobTask.Next() = 0;
    end;

    procedure Freeze(var JobTask: Record "Job Task")
    begin
        EnsureSIConstructionTask(JobTask);
        JobTask.Validate("SI Lifecycle Status", JobTask."SI Lifecycle Status"::Freezed);
        JobTask.Modify(true);
    end;

    procedure Restore(var JobTask: Record "Job Task")
    begin
        EnsureSIConstructionTask(JobTask);
        JobTask.Validate("SI Lifecycle Status", JobTask."SI Lifecycle Status"::Active);
        JobTask.Modify(true);
    end;

    procedure Annulate(var JobTask: Record "Job Task")
    begin
        EnsureSIConstructionTask(JobTask);
        JobTask.Validate("SI Lifecycle Status", JobTask."SI Lifecycle Status"::Annulated);
        JobTask.Modify(true);
    end;

    local procedure EnsureSIConstructionTask(JobTask: Record "Job Task")
    var
        Project: Record Job;
    begin
        JobTask.TestField("Job No.");
        JobTask.TestField("Job Task No.");
        if not Project.Get(JobTask."Job No.") then
            Error('Проєкт %1 не знайдено.', JobTask."Job No.");
        if not Project."SI Construction Project" then
            Error('Керований життєвий цикл SI застосовується лише до робіт будівельних проєктів SI.');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Task", 'OnBeforeInsertEvent', '', false, false)]
    local procedure InitializeConstructionTask(var Rec: Record "Job Task"; RunTrigger: Boolean)
    var
        Project: Record Job;
        DefaultSite: Record "SI Construction Site";
        SiteMgt: Codeunit "SI Construction Site Mgt.";
    begin
        if Rec.IsTemporary then
            exit;
        if Rec."Job No." = '' then
            exit;
        if not Project.Get(Rec."Job No.") then
            exit;
        if not Project."SI Construction Project" then
            exit;

        Rec."SI Lifecycle Status" := Rec."SI Lifecycle Status"::Active;
        if Rec."SI Site Code" = '' then begin
            SiteMgt.EnsureDefaultSite(Project, DefaultSite);
            Rec."SI Site Code" := DefaultSite."Site Code";
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Task", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure PreventConstructionTaskDelete(var Rec: Record "Job Task"; RunTrigger: Boolean)
    var
        Project: Record Job;
    begin
        if Rec.IsTemporary then
            exit;
        if not Project.Get(Rec."Job No.") then
            exit;
        if not Project."SI Construction Project" then
            exit;

        Error(
            'Роботу %1 проєкту %2 не можна фізично видалити. Використовуйте стани Заморожений та Анульований.',
            Rec."Job Task No.", Rec."Job No.");
    end;
}
