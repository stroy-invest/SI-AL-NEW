page 60011 "SI Construction Project Card"
{
    PageType = Card;
    SourceTable = Job;
    ApplicationArea = All;
    UsageCategory = None;
    Caption = 'Картка будівельного проєкту';
    DelayedInsert = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Загальне';

                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    Caption = '№ проєкту';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Коротка назва';
                }
                field("SI Full Name"; Rec."SI Full Name")
                {
                    ApplicationArea = All;
                    Caption = 'Повна назва об''єкта';
                }
                field("SI Project Status"; Rec."SI Project Status")
                {
                    ApplicationArea = All;
                    Caption = 'Статус';
                }
                field(CustomerDisplayName; CustomerDisplayName)
                {
                    ApplicationArea = All;
                    Caption = 'Замовник';
                    Lookup = true;
                    ToolTip = 'Визначає зовнішнього замовника проєкту. У картці відображається назва, а в Project зберігається стандартний код клієнта.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookupCustomer());
                    end;

                    trigger OnValidate()
                    begin
                        ValidateCustomerDisplayName();
                    end;
                }
                field(LocationDisplayName; LocationDisplayName)
                {
                    ApplicationArea = All;
                    Caption = 'Склад проєкту';
                    Editable = false;
                    ToolTip = 'Показує системний склад будівельного проєкту. Склад створюється та прив''язується автоматично.';
                }
            }
            group(ConstructionSites)
            {
                Caption = 'Будівельні майданчики';

                usercontrol(SitesGrid; SIConstructionSitesGrid)
                {
                    ApplicationArea = All;

                    trigger ControlReady()
                    begin
                        SitesGridReady := true;
                        RefreshSitesGrid();
                    end;

                    trigger AddSite()
                    begin
                        AddConstructionSite();
                    end;

                    trigger OpenSite(SiteCode: Text)
                    begin
                        OpenConstructionSite(SiteCode);
                    end;

                    trigger ToggleShowAll(ShowAll: Boolean)
                    begin
                        SitesShowingAll := ShowAll;
                        RefreshSitesGrid();
                    end;

                    trigger SetDefaultSite(SiteCode: Text)
                    begin
                        SetDefaultConstructionSite(SiteCode);
                    end;

                    trigger FreezeSite(SiteCode: Text)
                    begin
                        ChangeConstructionSiteStatus(SiteCode, 1);
                    end;

                    trigger RestoreSite(SiteCode: Text)
                    begin
                        ChangeConstructionSiteStatus(SiteCode, 0);
                    end;

                    trigger AnnulateSite(SiteCode: Text)
                    begin
                        AnnulateConstructionSite(SiteCode);
                    end;
                }
            }
            group(Responsibilities)
            {
                Caption = 'Керівництво проєкту';

                usercontrol(ResponsibilityGrid; SIProjectRespGrid)
                {
                    ApplicationArea = All;

                    trigger ControlReady()
                    begin
                        RespGridReady := true;
                        RefreshResponsibilityGrid();
                    end;

                    trigger AddAssignment()
                    begin
                        AddProjectAssignment();
                    end;

                    trigger DeleteAssignment(LineNo: Integer)
                    begin
                        DeleteProjectAssignment(LineNo);
                    end;

                    trigger LookupRole(LineNo: Integer)
                    begin
                        LookupAssignmentRole(LineNo);
                    end;

                    trigger LookupEmployee(LineNo: Integer)
                    begin
                        LookupAssignmentEmployee(LineNo);
                    end;

                    trigger UpdateValidFrom(LineNo: Integer; NewValue: Text)
                    begin
                        UpdateAssignmentDate(LineNo, NewValue, true);
                    end;

                    trigger UpdateValidTo(LineNo: Integer; NewValue: Text)
                    begin
                        UpdateAssignmentDate(LineNo, NewValue, false);
                    end;

                    trigger UpdatePrimary(LineNo: Integer; NewValue: Boolean)
                    begin
                        UpdateAssignmentPrimary(LineNo, NewValue);
                    end;
                }
            }
            group(Dates)
            {
                Caption = 'Строки';

                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = All;
                    Caption = 'Дата початку';
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = All;
                    Caption = 'Планова дата завершення';
                }
                field("SI Actual Ending Date"; Rec."SI Actual Ending Date")
                {
                    ApplicationArea = All;
                    Caption = 'Фактична дата завершення';
                }
            }
            group(Address)
            {
                Caption = 'Адреса об''єкта';

                field("SI Country/Region Code"; Rec."SI Country/Region Code")
                {
                    ApplicationArea = All;
                    Caption = 'Країна/регіон';
                }
                field("SI Post Code"; Rec."SI Post Code")
                {
                    ApplicationArea = All;
                    Caption = 'Поштовий індекс';
                }
                field("SI County"; Rec."SI County")
                {
                    ApplicationArea = All;
                    Caption = 'Область';
                }
                field("SI City"; Rec."SI City")
                {
                    ApplicationArea = All;
                    Caption = 'Місто';
                }
                field("SI Address"; Rec."SI Address")
                {
                    ApplicationArea = All;
                    Caption = 'Адреса';
                }
                field("SI Address 2"; Rec."SI Address 2")
                {
                    ApplicationArea = All;
                    Caption = 'Адреса 2';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {

            action(ValidateProject)
            {
                ApplicationArea = All;
                Caption = 'Перевірити проєкт';
                Image = Check;

                trigger OnAction()
                begin
                    ConstructionProjectMgt.ValidateProject(Rec);
                    Message('Проєкт %1 пройшов перевірку.', Rec."No.");
                end;
            }
        }
        area(Navigation)
        {
            action(OpenBCProject)
            {
                ApplicationArea = All;
                Caption = 'Відкрити проєкт BC';

                trigger OnAction()
                begin
                    Page.Run(Page::"Job Card", Rec);
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        AssignmentMgt: Codeunit "SI Project Assignment Mgt.";
    begin
        AssignmentMgt.EnsureDefaultRoles();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."SI Construction Project" := true;
        Rec."SI Project Status" := Rec."SI Project Status"::Preparation;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Rec."SI Construction Project" := true;
        Rec."SI Project Status" := Rec."SI Project Status"::Preparation;
        exit(true);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        EnsureInitializedProject();
        RefreshDisplayValues();
        RefreshResponsibilityGrid();
        RefreshSitesGrid();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        EnsureInitializedProject();
        exit(true);
    end;


    local procedure RefreshSitesGrid()
    var
        Site: Record "SI Construction Site";
        Data: JsonArray;
        Row: JsonObject;
        JsonText: Text;
    begin
        if not SitesGridReady then
            exit;

        Clear(Data);
        if Rec."No." <> '' then begin
            Site.SetRange("Project No.", Rec."No.");
            if not SitesShowingAll then
                Site.SetFilter(Status, '<>%1', Site.Status::Annulated);

            if Site.FindSet() then
                repeat
                    Clear(Row);
                    Row.Add('siteCode', Site."Site Code");
                    Row.Add('name', Site.Name);
                    Row.Add('isDefault', Site."Default");
                    Row.Add('status', Format(Site.Status));
                    // Action availability is authoritative in AL. Do not make the
                    // JavaScript layer interpret localized enum captions.
                    Row.Add('canSetDefault', (Site.Status = Site.Status::Active) and (not Site."Default"));
                    Row.Add('canFreeze', (Site.Status = Site.Status::Active) and (not Site."Default"));
                    Row.Add('canRestore', Site.Status = Site.Status::Freezed);
                    Row.Add('canAnnulate', Site.Status = Site.Status::Freezed);
                    Data.Add(Row);
                until Site.Next() = 0;
        end;

        Data.WriteTo(JsonText);
        CurrPage.SitesGrid.SetSites(JsonText, SitesShowingAll);
    end;

    local procedure AddConstructionSite()
    var
        CreatedSite: Record "SI Construction Site";
        SiteToOpen: Record "SI Construction Site";
        SiteMgt: Codeunit "SI Construction Site Mgt.";
        NewSiteDialog: Page "SI New Construction Site";
        ProjectNo: Code[20];
        NewSiteCode: Code[20];
    begin
        Rec.TestField("No.");
        ProjectNo := Rec."No.";
        EnsureInitializedProject();

        // Initialization and the user dialog are separate transactions.
        Commit();

        Clear(NewSiteDialog);
        if NewSiteDialog.RunModal() <> Action::OK then begin
            RefreshSitesGrid();
            exit;
        end;

        // Create through a clean domain buffer. The currently selected Site from
        // the control add-in/page is deliberately not involved in this path.
        Clear(CreatedSite);
        SiteMgt.CreateSite(
            ProjectNo,
            NewSiteDialog.GetSiteName(),
            NewSiteDialog.GetSiteDescription(),
            CreatedSite);
        NewSiteCode := CreatedSite."Site Code";

        // Finish the INSERT, then resolve the exact persisted Site again by full PK
        // before opening the card. This prevents any page/selection buffer leakage.
        Commit();
        Clear(SiteToOpen);
        if not SiteToOpen.Get(ProjectNo, NewSiteCode) then
            Error('Створений будівельний майданчик %1 проєкту %2 не знайдено.', NewSiteCode, ProjectNo);

        Page.RunModal(Page::"SI Construction Site Card", SiteToOpen);
        RefreshSitesGrid();
    end;

    local procedure OpenConstructionSite(SiteCodeText: Text)
    var
        Site: Record "SI Construction Site";
        SiteCode: Code[20];
    begin
        Rec.TestField("No.");
        SiteCode := CopyStr(SiteCodeText, 1, MaxStrLen(SiteCode));
        if SiteCode = '' then
            exit;
        if not Site.Get(Rec."No.", SiteCode) then
            Error('Будівельний майданчик %1 проєкту %2 не знайдено.', SiteCode, Rec."No.");

        Page.RunModal(Page::"SI Construction Site Card", Site);
        RefreshSitesGrid();
    end;

    local procedure GetConstructionSite(SiteCodeText: Text; var Site: Record "SI Construction Site")
    var
        SiteCode: Code[20];
    begin
        Rec.TestField("No.");
        SiteCode := CopyStr(SiteCodeText, 1, MaxStrLen(SiteCode));
        if (SiteCode = '') or not Site.Get(Rec."No.", SiteCode) then
            Error('Будівельний майданчик %1 проєкту %2 не знайдено.', SiteCodeText, Rec."No.");
    end;

    local procedure SetDefaultConstructionSite(SiteCodeText: Text)
    var
        Site: Record "SI Construction Site";
        SiteMgt: Codeunit "SI Construction Site Mgt.";
    begin
        GetConstructionSite(SiteCodeText, Site);
        SiteMgt.SetDefaultSite(Site);
        RefreshSitesGrid();
    end;

    local procedure ChangeConstructionSiteStatus(SiteCodeText: Text; NewStatusOrdinal: Integer)
    var
        Site: Record "SI Construction Site";
    begin
        GetConstructionSite(SiteCodeText, Site);
        case NewStatusOrdinal of
            0:
                Site.Validate(Status, Site.Status::Active);
            1:
                Site.Validate(Status, Site.Status::Freezed);
            else
                Error('Непідтримувана зміна стану майданчика.');
        end;
        Site.Modify(true);
        RefreshSitesGrid();
    end;

    local procedure AnnulateConstructionSite(SiteCodeText: Text)
    var
        Site: Record "SI Construction Site";
    begin
        GetConstructionSite(SiteCodeText, Site);
        if not Confirm('Анулювати будівельний майданчик %1? Цю дію неможливо скасувати.', false, Site.Name) then
            exit;
        Site.Validate(Status, Site.Status::Annulated);
        Site.Modify(true);
        RefreshSitesGrid();
    end;

    local procedure RefreshResponsibilityGrid()
    var
        Assignment: Record "SI Project Assignment";
        ProjectRole: Record "SI Project Role";
        Employee: Record Employee;
        Data: JsonArray;
        Row: JsonObject;
        RoleName: Text[100];
        EmployeeName: Text[100];
        JsonText: Text;
    begin
        if not RespGridReady then
            exit;

        Clear(Data);
        if Rec."No." <> '' then begin
            Assignment.SetRange("Project No.", Rec."No.");
            Assignment.SetRange("Role Code", 'PROJECT_MANAGER');
            if Assignment.FindSet() then
                repeat
                    Clear(RoleName);
                    Clear(EmployeeName);
                    if (Assignment."Role Code" <> '') and ProjectRole.Get(Assignment."Role Code") then
                        RoleName := ProjectRole.Description;
                    if (Assignment."Employee No." <> '') and Employee.Get(Assignment."Employee No.") then
                        EmployeeName := Employee.FullName();

                    Clear(Row);
                    Row.Add('lineNo', Assignment."Line No.");
                    Row.Add('role', RoleName);
                    Row.Add('employee', EmployeeName);
                    Row.Add('validFrom', DateToIsoText(Assignment."Valid From"));
                    Row.Add('validTo', DateToIsoText(Assignment."Valid To"));
                    Row.Add('primary', Assignment.Primary);
                    Data.Add(Row);
                until Assignment.Next() = 0;
        end;

        Data.WriteTo(JsonText);
        CurrPage.ResponsibilityGrid.SetAssignments(JsonText);
    end;

    local procedure AddProjectAssignment()
    var
        Assignment: Record "SI Project Assignment";
        LastAssignment: Record "SI Project Assignment";
        ProjectRole: Record "SI Project Role";
        ProjectRoles: Page "SI Project Roles";
        AssignmentMgt: Codeunit "SI Project Assignment Mgt.";
        NextLineNo: Integer;
    begin
        CurrPage.SaveRecord();
        if Rec."No." = '' then
            Error('Спочатку створіть проєкт.');

        AssignmentMgt.EnsureDefaultRoles();
        ProjectRole.SetRange(Active, true);
        ProjectRole.SetRange("Assignment Scope", ProjectRole."Assignment Scope"::Project);
        ProjectRoles.SetTableView(ProjectRole);
        ProjectRoles.LookupMode(true);
        if ProjectRoles.RunModal() <> Action::LookupOK then
            exit;
        ProjectRoles.GetRecord(ProjectRole);

        LastAssignment.SetRange("Project No.", Rec."No.");
        if LastAssignment.FindLast() then
            NextLineNo := LastAssignment."Line No." + 10000
        else
            NextLineNo := 10000;

        Assignment.Init();
        Assignment."Project No." := Rec."No.";
        Assignment."Line No." := NextLineNo;
        Assignment."Valid From" := WorkDate();
        Assignment.Validate("Role Code", ProjectRole.Code);
        Assignment.Insert(true);
        RefreshResponsibilityGrid();
    end;

    local procedure DeleteProjectAssignment(LineNo: Integer)
    var
        Assignment: Record "SI Project Assignment";
    begin
        if not Assignment.Get(Rec."No.", LineNo) then
            exit;
        if not Confirm('Видалити призначення відповідального?', false) then
            exit;

        Assignment.Delete(true);
        RefreshResponsibilityGrid();
    end;

    local procedure LookupAssignmentRole(LineNo: Integer)
    var
        Assignment: Record "SI Project Assignment";
        ProjectRole: Record "SI Project Role";
        ProjectRoles: Page "SI Project Roles";
        AssignmentMgt: Codeunit "SI Project Assignment Mgt.";
    begin
        if not Assignment.Get(Rec."No.", LineNo) then
            exit;

        AssignmentMgt.EnsureDefaultRoles();
        ProjectRole.SetRange(Active, true);
        ProjectRole.SetRange("Assignment Scope", ProjectRole."Assignment Scope"::Project);
        ProjectRoles.SetTableView(ProjectRole);
        ProjectRoles.LookupMode(true);
        if ProjectRoles.RunModal() <> Action::LookupOK then
            exit;

        ProjectRoles.GetRecord(ProjectRole);
        Assignment.Validate("Role Code", ProjectRole.Code);
        Assignment.Modify(true);
        RefreshResponsibilityGrid();
    end;

    local procedure LookupAssignmentEmployee(LineNo: Integer)
    var
        Assignment: Record "SI Project Assignment";
        Employee: Record Employee;
        EmployeeProjectRole: Record "SI Employee Project Role";
        EmployeeList: Page "Employee List";
        HasEligibleEmployees: Boolean;
    begin
        if not Assignment.Get(Rec."No.", LineNo) then
            exit;
        if Assignment."Role Code" = '' then
            Error('Спочатку виберіть роль у проєкті.');

        EmployeeProjectRole.SetRange("Role Code", Assignment."Role Code");
        if EmployeeProjectRole.FindSet() then
            repeat
                if Employee.Get(EmployeeProjectRole."Employee No.") then begin
                    Employee.Mark(true);
                    HasEligibleEmployees := true;
                end;
            until EmployeeProjectRole.Next() = 0;

        if not HasEligibleEmployees then
            Error('Для вибраної ролі не налаштовано жодного допустимого працівника.');

        Employee.MarkedOnly(true);
        EmployeeList.SetTableView(Employee);
        EmployeeList.LookupMode(true);
        if EmployeeList.RunModal() <> Action::LookupOK then
            exit;

        EmployeeList.GetRecord(Employee);
        Assignment.Validate("Employee No.", Employee."No.");
        Assignment.Modify(true);
        RefreshResponsibilityGrid();
    end;

    local procedure UpdateAssignmentDate(LineNo: Integer; NewValue: Text; IsValidFrom: Boolean)
    var
        Assignment: Record "SI Project Assignment";
        NewDate: Date;
    begin
        if not Assignment.Get(Rec."No.", LineNo) then
            exit;

        if NewValue <> '' then
            NewDate := IsoTextToDate(NewValue);

        if IsValidFrom then
            Assignment.Validate("Valid From", NewDate)
        else
            Assignment.Validate("Valid To", NewDate);
        Assignment.Modify(true);
        RefreshResponsibilityGrid();
    end;

    local procedure UpdateAssignmentPrimary(LineNo: Integer; NewValue: Boolean)
    var
        Assignment: Record "SI Project Assignment";
    begin
        if not Assignment.Get(Rec."No.", LineNo) then
            exit;

        Assignment.Validate(Primary, NewValue);
        Assignment.Modify(true);
        RefreshResponsibilityGrid();
    end;

    local procedure IsoTextToDate(Value: Text): Date
    var
        YearNo: Integer;
        MonthNo: Integer;
        DayNo: Integer;
    begin
        if StrLen(Value) <> 10 then
            Error('Некоректна дата %1.', Value);
        if (CopyStr(Value, 5, 1) <> '-') or (CopyStr(Value, 8, 1) <> '-') then
            Error('Некоректна дата %1.', Value);
        if not Evaluate(YearNo, CopyStr(Value, 1, 4)) then
            Error('Некоректна дата %1.', Value);
        if not Evaluate(MonthNo, CopyStr(Value, 6, 2)) then
            Error('Некоректна дата %1.', Value);
        if not Evaluate(DayNo, CopyStr(Value, 9, 2)) then
            Error('Некоректна дата %1.', Value);
        exit(DMY2Date(DayNo, MonthNo, YearNo));
    end;

    local procedure DateToIsoText(Value: Date): Text
    begin
        if Value = 0D then
            exit('');
        exit(Format(Value, 0, '<Year4>-<Month,2>-<Day,2>'));
    end;

    local procedure EnsureInitializedProject()
    var
        PersistedProject: Record Job;
    begin
        if Rec.IsTemporary then
            exit;
        if Rec."No." = '' then
            exit;

        // Initialize only after the Job has actually been inserted.
        // OnInsertRecord sets the SI marker/status; OnAfterGetCurrRecord or
        // OnQueryClosePage then performs the system projection safely.
        if not PersistedProject.Get(Rec."No.") then
            exit;

        ConstructionProjectMgt.InitializeProject(PersistedProject);

        // Reflect values written by the application service on the current page
        // without issuing another Modify from the UI layer.
        Rec."SI Construction Project" := PersistedProject."SI Construction Project";
        Rec."SI Project Status" := PersistedProject."SI Project Status";
        Rec."SI Internal Customer No." := PersistedProject."SI Internal Customer No.";
        Rec."Location Code" := PersistedProject."Location Code";
    end;

    local procedure RefreshDisplayValues()
    var
        Customer: Record Customer;
        Location: Record Location;
    begin
        Clear(CustomerDisplayName);
        Clear(LocationDisplayName);

        if (Rec."Sell-to Customer No." <> '') and Customer.Get(Rec."Sell-to Customer No.") then
            CustomerDisplayName := Customer.Name;

        if (Rec."Location Code" <> '') and Location.Get(Rec."Location Code") then
            LocationDisplayName := Location.Name;
    end;

    local procedure LookupCustomer(): Boolean
    var
        Customer: Record Customer;
        CustomerList: Page "Customer List";
    begin
        Customer.SetFilter(
            "SI Customer Type",
            '<>%1',
            Customer."SI Customer Type"::"Internal Project");
        CustomerList.SetTableView(Customer);
        CustomerList.LookupMode(true);
        if CustomerList.RunModal() <> Action::LookupOK then
            exit(false);

        CustomerList.GetRecord(Customer);
        Rec.Validate("Sell-to Customer No.", Customer."No.");
        CustomerDisplayName := Customer.Name;
        CurrPage.SaveRecord();
        exit(true);
    end;

    local procedure ValidateCustomerDisplayName()
    var
        Customer: Record Customer;
    begin
        if CustomerDisplayName = '' then begin
            Rec.Validate("Sell-to Customer No.", '');
            CurrPage.Update(false);
            exit;
        end;

        Customer.SetRange(Name, CustomerDisplayName);
        Customer.SetFilter(
            "SI Customer Type",
            '<>%1',
            Customer."SI Customer Type"::"Internal Project");
        if Customer.FindFirst() then begin
            Rec.Validate("Sell-to Customer No.", Customer."No.");
            CustomerDisplayName := Customer.Name;
            CurrPage.SaveRecord();
            exit;
        end;

        Error('Виберіть замовника зі списку.');
    end;

    var
        SitesGridReady: Boolean;
        SitesShowingAll: Boolean;
        ConstructionProjectMgt: Codeunit "SI Construction Project Mgt.";
        CustomerDisplayName: Text[100];
        LocationDisplayName: Text[100];
        RespGridReady: Boolean;
}
