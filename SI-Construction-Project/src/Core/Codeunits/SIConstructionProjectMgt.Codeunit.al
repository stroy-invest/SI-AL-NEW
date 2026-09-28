codeunit 60001 "SI Construction Project Mgt."
{
    Permissions =
        tabledata Job = rm,
        tabledata Customer = rim,
        tabledata Location = rim,
        tabledata "SI Location Setup" = r;

    procedure InitializeProject(var Project: Record Job)
    var
        InternalCustomer: Record Customer;
        DefaultSite: Record "SI Construction Site";
    begin
        Project.TestField("No.");

        if not Project."SI Construction Project" then begin
            Project."SI Construction Project" := true;
            Project."SI Project Status" := Project."SI Project Status"::Preparation;
            Project.Modify(true);
        end;

        InternalCustomerMgt.EnsureInternalSICustomer(Project, InternalCustomer);
        EnsureProjectLocation(Project);
        ConstructionSiteMgt.EnsureDefaultSite(Project, DefaultSite);
        ConstructionSiteMgt.MigrateProjectForemenToDefaultSite(Project);
        JobTaskMgt.EnsureProjectTasksSite(Project);
    end;

    procedure ValidateProject(Project: Record Job)
    var
        InternalCustomer: Record Customer;
    begin
        Project.TestField("No.");

        if not Project."SI Construction Project" then
            Error('Проєкт %1 не є будівельним проєктом SI.', Project."No.");

        InternalCustomerMgt.ValidateInternalSICustomer(Project, InternalCustomer);
        ConstructionSiteMgt.ValidateProjectSites(Project);
        JobTaskMgt.ValidateProjectTasks(Project);

        if Project."SI Project Status" <> Project."SI Project Status"::Preparation then
            ValidateOperationalProject(Project);

        if Project."SI Project Status" in [Project."SI Project Status"::Completed, Project."SI Project Status"::Closed] then
            Project.TestField("SI Actual Ending Date");
    end;

    procedure RepairProject(var Project: Record Job)
    var
        InternalCustomer: Record Customer;
        DefaultSite: Record "SI Construction Site";
    begin
        Project.TestField("No.");

        if not Project."SI Construction Project" then
            Error('Проєкт %1 не є будівельним проєктом SI.', Project."No.");

        InternalCustomerMgt.EnsureInternalSICustomer(Project, InternalCustomer);
        EnsureProjectLocation(Project);
        ConstructionSiteMgt.EnsureDefaultSite(Project, DefaultSite);
        ConstructionSiteMgt.MigrateProjectForemenToDefaultSite(Project);
        JobTaskMgt.EnsureProjectTasksSite(Project);
    end;

    procedure IsConstructionProject(Project: Record Job): Boolean
    begin
        exit(Project."SI Construction Project");
    end;

    procedure EnsureProjectLocation(var Project: Record Job)
    var
        Location: Record Location;
        LocationSetup: Record "SI Location Setup";
        NoSeries: Codeunit "No. Series";
        NewLocationNo: Code[20];
    begin
        Project.TestField("No.");

        if Project."Location Code" <> '' then begin
            ValidateProjectLocation(Project."Location Code");
            SyncProjectLocationName(Project);
            exit;
        end;

        if not LocationSetup.Get() then
            Error('Не налаштовано семантичні типи складів у Foundation.');

        LocationSetup.TestField("Project Location Type");
        LocationSetup.TestField("Location No. Series");

        NewLocationNo := NoSeries.GetNextNo(LocationSetup."Location No. Series");
        if StrLen(NewLocationNo) > MaxStrLen(Location.Code) then
            Error(
                'Серія номерів складів %1 сформувала номер %2 довжиною %3 символів. Стандартний код складу Business Central допускає максимум %4 символів.',
                LocationSetup."Location No. Series",
                NewLocationNo,
                StrLen(NewLocationNo),
                MaxStrLen(Location.Code));

        Location.Init();
        Location.Code := CopyStr(NewLocationNo, 1, MaxStrLen(Location.Code));
        Location.Name := BuildProjectLocationName(Project);
        Location."SI Location Type Code" := LocationSetup."Project Location Type";
        Location.Insert(true);

        Project.Validate("Location Code", Location.Code);
        Project.Modify(true);
    end;

    procedure SyncProjectLocationName(Project: Record Job)
    var
        Location: Record Location;
        ExpectedName: Text[100];
    begin
        if not Project."SI Construction Project" then
            exit;
        if Project."Location Code" = '' then
            exit;
        if not Location.Get(Project."Location Code") then
            exit;

        ExpectedName := BuildProjectLocationName(Project);
        if Location.Name = ExpectedName then
            exit;

        Location.Name := ExpectedName;
        Location.Modify(true);
    end;

    local procedure BuildProjectLocationName(Project: Record Job): Text[100]
    var
        Location: Record Location;
    begin
        exit(CopyStr(StrSubstNo('Склад: %1', Project.Description), 1, MaxStrLen(Location.Name)));
    end;

    [EventSubscriber(ObjectType::Table, Database::Location, 'OnBeforeDeleteEvent', '', false, false)]
    local procedure PreventProjectLocationDelete(var Rec: Record Location; RunTrigger: Boolean)
    var
        Project: Record Job;
    begin
        Project.SetRange("SI Construction Project", true);
        Project.SetRange("Location Code", Rec.Code);
        if Project.FindFirst() then
            Error(
                'Склад %1 є системним складом будівельного проєкту %2 і не може бути видалений.',
                Rec.Code,
                Project."No.");
    end;

    procedure ValidateOperationalProject(Project: Record Job)
    begin
        Project.TestField("Location Code");
        ValidateProjectLocation(Project."Location Code");
    end;

    procedure ValidateProjectLocation(LocationCode: Code[10])
    var
        Location: Record Location;
        LocationSetup: Record "SI Location Setup";
    begin
        if LocationCode = '' then
            Error('Для будівельного проєкту необхідно вказати склад проєкту.');

        if not Location.Get(LocationCode) then
            Error('Склад %1 не існує.', LocationCode);

        if not LocationSetup.Get() then
            Error('Не налаштовано семантичні типи складів у Foundation.');

        LocationSetup.TestField("Project Location Type");

        if Location."SI Location Type Code" <> LocationSetup."Project Location Type" then
            Error(
                'Склад %1 має тип %2. Для будівельного проєкту потрібен склад семантичного типу %3.',
                Location.Code,
                Location."SI Location Type Code",
                LocationSetup."Project Location Type");
    end;

    procedure GetProjectLocationType(): Code[20]
    var
        LocationSetup: Record "SI Location Setup";
    begin
        if not LocationSetup.Get() then
            exit('');
        exit(LocationSetup."Project Location Type");
    end;

    [EventSubscriber(ObjectType::Table, Database::Job, 'OnBeforeDeleteEvent', '', false, false)]
    local procedure PreventConstructionProjectDelete(var Rec: Record Job; RunTrigger: Boolean)
    begin
        if Rec."SI Construction Project" then
            Error(
                'Будівельний проєкт SI %1 не може бути фізично видалений. Використовуйте керований життєвий цикл проєкту.',
                Rec."No.");
    end;

    var
        InternalCustomerMgt: Codeunit "SI Internal Customer Mgt.";
        ConstructionSiteMgt: Codeunit "SI Construction Site Mgt.";
        JobTaskMgt: Codeunit "SI Job Task Mgt.";
}
