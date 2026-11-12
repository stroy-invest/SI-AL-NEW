codeunit 60026 "SI Project Wizard Orch"
{
    Permissions = tabledata Job = rim,
                  tabledata "SI Construction Site" = rim,
                  tabledata "Ship-to Address" = rim,
                  tabledata "SI Project Assignment" = rim,
                  tabledata "SI Site Assignment" = rim;

    procedure CreateProject(var Input: Record "SI Project Wizard Buffer" temporary; var Sites: Record "SI Project Wizard Site" temporary): Code[20]
    var
        Project: Record Job;
        Site: Record "SI Construction Site";
        WizardSite: Record "SI Project Wizard Site" temporary;
        SiteMgt: Codeunit "SI Construction Site Mgt.";
        ProjectMgt: Codeunit "SI Construction Project Mgt.";
        ManagerRole: Record "SI Project Role";
        ForemanRole: Record "SI Project Role";
        DefaultCount: Integer;
    begin
        // Preflight BEFORE any persistent writes. Caller must not commit until complete.
        Input.TestField("Short Name");
        Input.TestField("Full Name");
        Input.TestField("Customer No.");
        Input.TestField("Manager No.");
        Input.TestField("Starting Date");
        Input.TestField("Planned Ending Date");
        if Input."Planned Ending Date" < Input."Starting Date" then
            Error('Дата завершення не може передувати даті початку.');
        Input.TestField("Country/Region Code");
        Input.TestField("Post Code");
        Input.TestField(County);
        Input.TestField(City);
        Input.TestField(Address);
        ValidateCustomer(Input."Customer No.");
        FindPurposeRole("SI Project Role Purpose"::ProjectManager, ManagerRole);
        CheckEmployeeRole(Input."Manager No.", ManagerRole, Input."Starting Date");

        Sites.Reset();
        if not Sites.FindSet() then
            Error('Вкажіть хоча б один майданчик.');
        repeat
            Sites.TestField(Name);
            Sites.TestField("Country/Region Code");
            Sites.TestField("Post Code");
            Sites.TestField(County);
            Sites.TestField(City);
            Sites.TestField(Address);
            if Sites."Default" then
                DefaultCount += 1;
            if Sites."Foreman No." <> '' then begin
                if ForemanRole.Code = '' then
                    FindPurposeRole("SI Project Role Purpose"::SiteSupervisor, ForemanRole);
                CheckEmployeeRole(Sites."Foreman No.", ForemanRole, Input."Starting Date");
            end;
        until Sites.Next() = 0;
        if DefaultCount <> 1 then
            Error('Має бути рівно один основний будмайданчик.');

        Project.Init();
        Project."SI Construction Project" := true;
        Project.Insert(true); // Standard Job numbering via standard OnInsert.
        Project.TestField("No.");
        Project.Validate(Description, CopyStr(Input."Short Name", 1, MaxStrLen(Project.Description)));
        Project."SI Full Name" := Input."Full Name";
        Project.Validate("Sell-to Customer No.", Input."Customer No.");
        Project.Validate("Starting Date", Input."Starting Date");
        Project.Validate("Ending Date", Input."Planned Ending Date");
        Project."SI Country/Region Code" := Input."Country/Region Code";
        Project."SI Post Code" := Input."Post Code";
        Project."SI County" := Input.County;
        Project."SI City" := Input.City;
        Project."SI Address" := Input.Address;
        Project."SI District" := Input.District;
        Project."SI Project Status" := Project."SI Project Status"::Preparation;
        Project.Modify(true);

        // Existing services own Customer, Location, default site and standard Job tasks.
        ProjectMgt.InitializeProject(Project);
        Project.Get(Project."No.");
        Project.TestField("SI Internal Customer No.");
        Project.TestField("Location Code");
        InsertProjectManager(Project."No.", Input."Manager No.", ManagerRole.Code, Input."Starting Date");

        Sites.Reset();
        if Sites.FindSet() then
            repeat
                WizardSite := Sites;
                if WizardSite."Default" then begin
                    if not SiteMgt.FindDefaultSite(Project."No.", Site) then
                        Error('Основний будмайданчик не створено.');
                end else
                    SiteMgt.CreateSite(Project."No.", WizardSite.Name, WizardSite.Description, Site);

                Site.Name := WizardSite.Name;
                Site.Description := WizardSite.Description;
                Site.Modify(true);
                ApplySiteAddress(Project, Site, WizardSite);
                if WizardSite."Foreman No." <> '' then
                    InsertForeman(Project."No.", Site."Site Code", WizardSite."Foreman No.", ForemanRole.Code, Input."Starting Date");
            until Sites.Next() = 0;

        SiteMgt.ValidateProjectSites(Project);
        exit(Project."No.");
    end;

    local procedure ValidateCustomer(CustomerNo: Code[20])
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        if Customer."SI Customer Type" = Customer."SI Customer Type"::"Internal Project" then
            Error('Внутрішній клієнт не може бути замовником проєкту.');
    end;

    local procedure FindPurposeRole(Purpose: Enum "SI Project Role Purpose"; var Role: Record "SI Project Role")
    begin
        Role.Reset();
        Role.SetRange(Purpose, Purpose);
        Role.SetRange(Active, true);
        if not Role.FindFirst() then
            Error('Не налаштовано активну роль для призначення %1.', Format(Purpose));
    end;

    local procedure CheckEmployeeRole(EmployeeNo: Code[20]; Role: Record "SI Project Role"; ContextDate: Date)
    var
        Employee: Record Employee;
        AssignmentMgt: Codeunit "SI Project Assignment Mgt.";
    begin
        Employee.Get(EmployeeNo);
        AssignmentMgt.ValidateEmployeeRoleOnDate(EmployeeNo, Role.Code, ContextDate);
    end;

    local procedure ApplySiteAddress(Project: Record Job; Site: Record "SI Construction Site"; Source: Record "SI Project Wizard Site" temporary)
    var
        ShipTo: Record "Ship-to Address";
    begin
        Site.TestField("Ship-to Code");
        ShipTo.Get(Project."SI Internal Customer No.", Site."Ship-to Code");
        ShipTo.Validate(Name, CopyStr(Site.Name, 1, MaxStrLen(ShipTo.Name)));
        ShipTo.Validate("Country/Region Code", Source."Country/Region Code");
        ShipTo.Validate("Post Code", Source."Post Code");
        ShipTo.Validate(County, Source.County);
        ShipTo.Validate(City, Source.City);
        ShipTo.Validate(Address, Source.Address);
        ShipTo."SI District" := Source.District;
        ShipTo.Validate("Location Code", Project."Location Code");
        ShipTo.Modify(true);
    end;

    local procedure InsertProjectManager(ProjectNo: Code[20]; EmployeeNo: Code[20]; RoleCode: Code[20]; FromDate: Date)
    var
        Assignment: Record "SI Project Assignment";
    begin
        Assignment.Init();
        Assignment."Project No." := ProjectNo;
        Assignment."Line No." := 10000;
        Assignment.Validate("Role Code", RoleCode);
        Assignment.Validate("Employee No.", EmployeeNo);
        Assignment.Validate("Valid From", FromDate);
        Assignment.Primary := true;
        Assignment.Insert(true);
    end;

    local procedure InsertForeman(ProjectNo: Code[20]; SiteCode: Code[20]; EmployeeNo: Code[20]; RoleCode: Code[20]; FromDate: Date)
    var
        Assignment: Record "SI Site Assignment";
    begin
        Assignment.Init();
        Assignment."Project No." := ProjectNo;
        Assignment."Site Code" := SiteCode;
        Assignment."Line No." := 10000;
        Assignment.Validate("Role Code", RoleCode);
        Assignment.Validate("Employee No.", EmployeeNo);
        Assignment.Validate("Valid From", FromDate);
        Assignment.Primary := true;
        Assignment.Insert(true);
    end;
}
