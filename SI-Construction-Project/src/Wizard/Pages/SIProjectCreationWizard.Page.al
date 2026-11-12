page 60024 "SI Project Creation Wizard"
{
    PageType = NavigatePage;
    SourceTable = "SI Project Wizard Buffer";
    SourceTableTemporary = true;
    ApplicationArea = All;
    Caption = 'Створення будівельного проєкту';
    UsageCategory = None;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(ProjectDetails)
            {
                Caption = 'Крок 1. Основні дані';
                Visible = Step = 1;
                field("Short Name"; Rec."Short Name") { ApplicationArea = All; ShowMandatory = true; }
                field("Full Name"; Rec."Full Name") { ApplicationArea = All; ShowMandatory = true; }
                field("Customer No."; Rec."Customer No.") { ApplicationArea = All; ShowMandatory = true; }
                field("Starting Date"; Rec."Starting Date") { ApplicationArea = All; ShowMandatory = true; }
                field("Planned Ending Date"; Rec."Planned Ending Date") { ApplicationArea = All; ShowMandatory = true; }
                field("Manager No."; Rec."Manager No.")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        SelectEligibleEmployee("SI Project Role Purpose"::ProjectManager, Rec."Manager No.", Rec."Starting Date");
                        Text := Rec."Manager No.";
                        exit(true);
                    end;
                    trigger OnValidate()
                    begin
                        if Rec."Manager No." <> '' then
                            ValidateEligibleEmployee("SI Project Role Purpose"::ProjectManager, Rec."Manager No.", Rec."Starting Date");
                    end;
                }
            }
            group(ProjectAddress)
            {
                Caption = 'Крок 2. Адреса об''єкта';
                Visible = Step = 2;
                field("Country/Region Code"; Rec."Country/Region Code") { ApplicationArea = All; ShowMandatory = true; }
                field("Post Code"; Rec."Post Code") { ApplicationArea = All; ShowMandatory = true; }
                field(County; Rec.County) { ApplicationArea = All; ShowMandatory = true; }
                field(District; Rec.District) { ApplicationArea = All; }
                field(City; Rec.City) { ApplicationArea = All; ShowMandatory = true; }
                field(Address; Rec.Address) { ApplicationArea = All; ShowMandatory = true; }
            }
            group(SiteEntry)
            {
                Caption = 'Крок 3. Будівельний майданчик';
                Visible = Step = 3;
                field(CurrentSiteNumber; CurrentSiteNumber)
                {
                    ApplicationArea = All;
                    Caption = 'Майданчик №';
                    Editable = false;
                }
                field(SiteIsDefault; SiteIsDefault)
                {
                    ApplicationArea = All;
                    Caption = 'Основний майданчик';
                    Editable = false;
                }
                field(SiteName; SiteName)
                {
                    ApplicationArea = All;
                    Caption = 'Назва';
                    ShowMandatory = true;
                    trigger OnValidate()
                    begin
                        SaveCurrentSite();
                    end;
                }
                field(SiteDescription; SiteDescription)
                {
                    ApplicationArea = All;
                    Caption = 'Опис';
                    trigger OnValidate()
                    begin
                        SaveCurrentSite();
                    end;
                }
                field(SiteForemanNo; SiteForemanNo)
                {
                    ApplicationArea = All;
                    Caption = 'Виконроб';
                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        SelectEligibleEmployee("SI Project Role Purpose"::SiteSupervisor, SiteForemanNo, Rec."Starting Date");
                        Text := SiteForemanNo;
                        SaveCurrentSite();
                        exit(true);
                    end;
                    trigger OnValidate()
                    begin
                        if SiteForemanNo <> '' then
                            ValidateEligibleEmployee("SI Project Role Purpose"::SiteSupervisor, SiteForemanNo, Rec."Starting Date");
                        SaveCurrentSite();
                    end;
                }
                group(SiteDeliveryAddress)
                {
                    Caption = 'Адреса доставки';
                    field(SiteCountry; SiteCountry)
                    {
                        ApplicationArea = All;
                        Caption = 'Країна/регіон';
                        ShowMandatory = true;
                        trigger OnValidate() begin SaveCurrentSite(); end;
                    }
                    field(SitePostCode; SitePostCode)
                    {
                        ApplicationArea = All;
                        Caption = 'Поштовий індекс';
                        ShowMandatory = true;
                        trigger OnValidate() begin SaveCurrentSite(); end;
                    }
                    field(SiteCounty; SiteCounty)
                    {
                        ApplicationArea = All;
                        Caption = 'Область';
                        ShowMandatory = true;
                        trigger OnValidate() begin SaveCurrentSite(); end;
                    }
                    field(SiteDistrict; SiteDistrict)
                    {
                        ApplicationArea = All;
                        Caption = 'Район';
                        trigger OnValidate() begin SaveCurrentSite(); end;
                    }
                    field(SiteCity; SiteCity)
                    {
                        ApplicationArea = All;
                        Caption = 'Місто / населений пункт';
                        ShowMandatory = true;
                        trigger OnValidate() begin SaveCurrentSite(); end;
                    }
                    field(SiteAddress; SiteAddress)
                    {
                        ApplicationArea = All;
                        Caption = 'Адреса';
                        ShowMandatory = true;
                        trigger OnValidate() begin SaveCurrentSite(); end;
                    }
                }
            }
            group(Review)
            {
                Caption = 'Крок 4. Перевірка';
                Visible = Step = 4;
                field(ReviewInformation; ReviewInformation)
                {
                    ApplicationArea = All;
                    Caption = 'Підсумок';
                    Editable = false;
                    MultiLine = true;
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(CancelWizard)
            {
                ApplicationArea = All;
                Caption = 'Скасувати';
                InFooterBar = true;
                Image = Cancel;
                trigger OnAction()
                begin
                    CurrPage.Close();
                end;
            }
            action(AddNextSite)
            {
                Caption = 'Додати майданчик';
                ApplicationArea = All;
                Visible = Step = 3;
                InFooterBar = true;
                Image = New;
                trigger OnAction()
                var
                    NewSite: Record "SI Project Wizard Site" temporary;
                    LastLine: Integer;
                begin
                    SaveCurrentSite();
                    ValidateCurrentSite();
                    // When revisiting previous sites, navigate to the existing next site.
                    WizardSites.Reset();
                    WizardSites.SetFilter("Line No.", '>%1', CurrentSiteLineNo);
                    if WizardSites.FindFirst() then begin
                        CurrentSiteLineNo := WizardSites."Line No.";
                    end else begin
                        WizardSites.Reset();
                        if WizardSites.FindLast() then
                            LastLine := WizardSites."Line No.";
                        NewSite.Init();
                        NewSite."Line No." := LastLine + 10000;
                        NewSite."Country/Region Code" := Rec."Country/Region Code";
                        WizardSites := NewSite;
                        WizardSites.Insert();
                        CurrentSiteLineNo := NewSite."Line No.";
                    end;
                    LoadCurrentSite();
                    CurrPage.Update(false);
                end;
            }
            action(FinishCreation)
            {
                Caption = 'Створити проєкт';
                ApplicationArea = All;
                Image = Approve;
                Visible = Step = 4;
                InFooterBar = true;
                trigger OnAction()
                var
                    Orchestrator: Codeunit "SI Project Wizard Orch";
                    ProjectNo: Code[20];
                begin
                    ValidateProjectStep();
                    ValidateAddressStep();
                    SaveCurrentSite();
                    ValidateWizardSites();
                    ProjectNo := Orchestrator.CreateProject(Rec, WizardSites);
                    Message('Будівельний проєкт %1 успішно створено.', ProjectNo);
                    CurrPage.Close();
                end;
            }
            action(PreviousStep)
            {
                ApplicationArea = All;
                Caption = 'Назад';
                Enabled = Step > 1;
                Visible = Step > 1;
                InFooterBar = true;
                Image = PreviousRecord;
                trigger OnAction()
                begin
                    if Step = 3 then begin
                        SaveCurrentSite();
                        WizardSites.Reset();
                        WizardSites.SetFilter("Line No.", '<%1', CurrentSiteLineNo);
                        if WizardSites.FindLast() then begin
                            CurrentSiteLineNo := WizardSites."Line No.";
                            LoadCurrentSite();
                            CurrPage.Update(false);
                            exit;
                        end;
                    end;
                    Step -= 1;
                    CurrPage.Update(false);
                end;
            }
            action(NextStep)
            {
                ApplicationArea = All;
                Caption = 'Далі';
                Enabled = Step < 4;
                Visible = Step < 4;
                InFooterBar = true;
                Image = NextRecord;
                trigger OnAction()
                begin
                    case Step of
                        1: ValidateProjectStep();
                        2: ValidateAddressStep();
                    end;
                    if Step = 3 then begin
                        SaveCurrentSite();
                        ValidateCurrentSite();
                        ValidateWizardSites();
                    end;
                    Step += 1;
                    if Step = 3 then begin
                        EnsureDefaultWizardSite();
                        if CurrentSiteLineNo = 0 then
                            CurrentSiteLineNo := 10000;
                        LoadCurrentSite();
                    end;
                    if Step = 4 then
                        BuildReview();
                    CurrPage.Update(false);
                end;
            }
        }
    }
    trigger OnOpenPage()
    begin
        Step := 1;
        Rec.Init();
        Rec."Entry No." := 1;
        Rec."Country/Region Code" := 'UA';
        Rec.Insert();

    end;

    local procedure SelectEligibleEmployee(Purpose: Enum "SI Project Role Purpose"; var EmployeeNo: Code[20]; ContextDate: Date)
    var
        Role: Record "SI Project Role";
        Eligible: Record Employee;
        EmployeeList: Page "Employee List";
        AssignmentMgt: Codeunit "SI Project Assignment Mgt.";
    begin
        AssignmentMgt.RequireRoleByPurpose(Purpose, Role);
        if not AssignmentMgt.CollectEligibleEmployees(Role.Code, ContextDate, Eligible) then
            Error('Немає співробітників із компетенцією для ролі "%1".', Role.Description);
        Clear(EmployeeList);
        EmployeeList.LookupMode(true);
        EmployeeList.SetTableView(Eligible);
        if EmployeeList.RunModal() = Action::LookupOK then begin
            EmployeeList.GetRecord(Eligible);
            AssignmentMgt.ValidateEmployeeRoleOnDate(Eligible."No.", Role.Code, ContextDate);
            EmployeeNo := Eligible."No.";
        end;
    end;

    local procedure ValidateEligibleEmployee(Purpose: Enum "SI Project Role Purpose"; EmployeeNo: Code[20]; ContextDate: Date)
    var
        Role: Record "SI Project Role";
        AssignmentMgt: Codeunit "SI Project Assignment Mgt.";
    begin
        AssignmentMgt.RequireRoleByPurpose(Purpose, Role);
        AssignmentMgt.ValidateEmployeeRoleOnDate(EmployeeNo, Role.Code, ContextDate);
    end;

    local procedure ValidateProjectStep()
    var
        Customer: Record Customer;
    begin
        Rec.TestField("Short Name");
        Rec.TestField("Full Name");
        Rec.TestField("Customer No.");
        Rec.TestField("Starting Date");
        Rec.TestField("Planned Ending Date");
        Rec.TestField("Manager No.");
        ValidateEligibleEmployee("SI Project Role Purpose"::ProjectManager, Rec."Manager No.", Rec."Starting Date");
        if Rec."Planned Ending Date" < Rec."Starting Date" then
            Error('Планова дата завершення не може передувати даті початку.');
        Customer.Get(Rec."Customer No.");
        if Customer."SI Customer Type" = Customer."SI Customer Type"::"Internal Project" then
            Error('Внутрішній клієнт не може бути замовником проєкту.');
    end;

    local procedure ValidateAddressStep()
    begin
        Rec.TestField("Country/Region Code");
        Rec.TestField("Post Code");
        Rec.TestField(County);
        Rec.TestField(City);
        Rec.TestField(Address);
    end;

    local procedure EnsureDefaultWizardSite()
    begin
        if WizardSites.Get(10000) then
            exit;
        WizardSites.Init();
        WizardSites."Line No." := 10000;
        WizardSites.Name := 'Основний буд. майданчик';
        WizardSites.Description := 'Основний буд. майданчик';
        WizardSites."Default" := true;
        WizardSites."Country/Region Code" := Rec."Country/Region Code";
        WizardSites."Post Code" := Rec."Post Code";
        WizardSites.County := Rec.County;
        WizardSites.District := Rec.District;
        WizardSites.City := Rec.City;
        WizardSites.Address := Rec.Address;
        WizardSites.Insert();
    end;

    local procedure LoadCurrentSite()
    begin
        WizardSites.Reset();
        WizardSites.Get(CurrentSiteLineNo);
        CurrentSiteNumber := CurrentSiteLineNo div 10000;
        SiteIsDefault := WizardSites."Default";
        SiteName := WizardSites.Name;
        SiteDescription := WizardSites.Description;
        SiteForemanNo := WizardSites."Foreman No.";
        SiteCountry := WizardSites."Country/Region Code";
        SitePostCode := WizardSites."Post Code";
        SiteCounty := WizardSites.County;
        SiteDistrict := WizardSites.District;
        SiteCity := WizardSites.City;
        SiteAddress := WizardSites.Address;
    end;

    local procedure SaveCurrentSite()
    begin
        if CurrentSiteLineNo = 0 then
            exit;
        WizardSites.Reset();
        WizardSites.Get(CurrentSiteLineNo);
        WizardSites.Name := SiteName;
        WizardSites.Description := SiteDescription;
        WizardSites."Foreman No." := SiteForemanNo;
        WizardSites."Country/Region Code" := SiteCountry;
        WizardSites."Post Code" := SitePostCode;
        WizardSites.County := SiteCounty;
        WizardSites.District := SiteDistrict;
        WizardSites.City := SiteCity;
        WizardSites.Address := SiteAddress;
        WizardSites.Modify();
    end;

    local procedure ValidateCurrentSite()
    begin
        WizardSites.Reset();
        WizardSites.Get(CurrentSiteLineNo);
        WizardSites.TestField(Name);
        WizardSites.TestField("Country/Region Code");
        WizardSites.TestField("Post Code");
        WizardSites.TestField(County);
        WizardSites.TestField(City);
        WizardSites.TestField(Address);
        if WizardSites."Foreman No." <> '' then
            ValidateEligibleEmployee("SI Project Role Purpose"::SiteSupervisor, WizardSites."Foreman No.", Rec."Starting Date");
    end;

    local procedure ValidateWizardSites()
    var
        DefaultCount: Integer;
    begin
        WizardSites.Reset();
        if not WizardSites.FindSet() then
            Error('Вкажіть хоча б один будівельний майданчик.');
        repeat
            WizardSites.TestField(Name);
            WizardSites.TestField("Country/Region Code");
            WizardSites.TestField("Post Code");
            WizardSites.TestField(County);
            WizardSites.TestField(City);
            WizardSites.TestField(Address);
            if WizardSites."Default" then
                DefaultCount += 1;
        until WizardSites.Next() = 0;
        if DefaultCount <> 1 then
            Error('Має бути рівно один основний майданчик.');
    end;

    local procedure BuildReview()
    begin
        ReviewInformation := CopyStr(
            StrSubstNo('%1 / %2. Замовник: %3. Адреса: %4, %5, %6, %7.',
                Rec."Short Name", Rec."Full Name", Rec."Customer No.",
                Rec."Country/Region Code", Rec."Post Code", Rec.City, Rec.Address),
            1, MaxStrLen(ReviewInformation));
    end;

    var
        WizardSites: Record "SI Project Wizard Site" temporary;
        Step: Integer;
        CurrentSiteLineNo: Integer;
        CurrentSiteNumber: Integer;
        SiteIsDefault: Boolean;
        SiteName: Text[100];
        SiteDescription: Text[250];
        SiteForemanNo: Code[20];
        SiteCountry: Code[10];
        SitePostCode: Code[20];
        SiteCounty: Text[30];
        SiteDistrict: Text[100];
        SiteCity: Text[30];
        SiteAddress: Text[100];
        ReviewInformation: Text[1024];
}
