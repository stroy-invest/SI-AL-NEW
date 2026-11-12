page 60025 "SI Project Wizard Sites"
{
    PageType = List;
    SourceTable = "SI Project Wizard Site";
    SourceTableTemporary = true;
    ApplicationArea = All;
    Caption = 'Майданчики проєкту';
    UsageCategory = None;
    DelayedInsert = true;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Sites)
            {
                field("Default"; Rec."Default") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; ShowMandatory = true; }
                field(Description; Rec.Description) { ApplicationArea = All; }
                field("Foreman No."; Rec."Foreman No.")
                {
                    ApplicationArea = All;
                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        SelectForeman();
                        Text := Rec."Foreman No.";
                        exit(true);
                    end;
                    trigger OnValidate()
                    begin
                        if Rec."Foreman No." <> '' then
                            ValidateForeman(Rec."Foreman No.");
                    end;
                }
                field("Country/Region Code"; Rec."Country/Region Code") { ApplicationArea = All; ShowMandatory = true; }
                field("Post Code"; Rec."Post Code") { ApplicationArea = All; ShowMandatory = true; }
                field(County; Rec.County) { ApplicationArea = All; ShowMandatory = true; }
                field(District; Rec.District) { ApplicationArea = All; }
                field(City; Rec.City) { ApplicationArea = All; ShowMandatory = true; }
                field(Address; Rec.Address) { ApplicationArea = All; ShowMandatory = true; }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(AddSite)
            {
                Caption = 'Додати майданчик';
                ApplicationArea = All;
                Image = New;
                trigger OnAction()
                var
                    Site: Record "SI Project Wizard Site" temporary;
                begin
                    ValidateSites();
                    Rec.Reset();
                    if Rec.FindLast() then
                        NextLineNo := Rec."Line No." + 10000
                    else
                        NextLineNo := 10000;
                    Site.Init();
                    Site."Line No." := NextLineNo;
                    Site."Country/Region Code" := DefaultCountry;
                    Site.Insert();
                    Rec.Copy(Site, true);
                    CurrPage.Update(false);
                end;
            }
            action(RemoveSite)
            {
                Caption = 'Видалити додатковий майданчик';
                ApplicationArea = All;
                Image = Delete;
                trigger OnAction()
                begin
                    if Rec."Default" then
                        Error('Основний майданчик видаляти не можна.');
                    Rec.Delete();
                    CurrPage.Update(false);
                end;
            }
        }
    }
    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction in [Action::OK, Action::LookupOK] then
            ValidateSites();
        exit(true);
    end;

    procedure LoadSites(var Source: Record "SI Project Wizard Site" temporary; CountryCode: Code[10]; StartingDate: Date)
    begin
        DefaultCountry := CountryCode;
        EligibilityDate := StartingDate;
        Rec.Reset();
        Rec.DeleteAll();
        if Source.FindSet() then
            repeat
                Rec := Source;
                Rec.Insert();
            until Source.Next() = 0;
    end;

    procedure ExportSites(var Target: Record "SI Project Wizard Site" temporary)
    begin
        Target.Reset();
        Target.DeleteAll();
        Rec.Reset();
        if Rec.FindSet() then
            repeat
                Target := Rec;
                Target.Insert();
            until Rec.Next() = 0;
    end;

    local procedure SelectForeman()
    var
        Role: Record "SI Project Role";
        Eligible: Record Employee;
        EmployeeList: Page "Employee List";
        AssignmentMgt: Codeunit "SI Project Assignment Mgt.";
    begin
        AssignmentMgt.RequireRoleByPurpose("SI Project Role Purpose"::SiteSupervisor, Role);
        if not AssignmentMgt.CollectEligibleEmployees(Role.Code, EligibilityDate, Eligible) then
            Error('Немає співробітників із компетенцією для ролі "%1".', Role.Description);
        Clear(EmployeeList);
        EmployeeList.LookupMode(true);
        EmployeeList.SetTableView(Eligible);
        if EmployeeList.RunModal() = Action::LookupOK then begin
            EmployeeList.GetRecord(Eligible);
            ValidateForeman(Eligible."No.");
            Rec.Validate("Foreman No.", Eligible."No.");
        end;
    end;

    local procedure ValidateForeman(EmployeeNo: Code[20])
    var
        Role: Record "SI Project Role";
        AssignmentMgt: Codeunit "SI Project Assignment Mgt.";
    begin
        AssignmentMgt.RequireRoleByPurpose("SI Project Role Purpose"::SiteSupervisor, Role);
        AssignmentMgt.ValidateEmployeeRoleOnDate(EmployeeNo, Role.Code, EligibilityDate);
    end;

    local procedure ValidateSites()
    var
        Site: Record "SI Project Wizard Site" temporary;
        DefaultCount: Integer;
    begin
        Rec.Reset();
        if not Rec.FindFirst() then
            Error('Додайте хоча б основний майданчик.');
        if Rec.FindSet() then
            repeat
                Rec.TestField(Name);
                Rec.TestField("Country/Region Code");
                Rec.TestField("Post Code");
                Rec.TestField(County);
                Rec.TestField(City);
                Rec.TestField(Address);
                if Rec."Foreman No." <> '' then
                    ValidateForeman(Rec."Foreman No.");
                if Rec."Default" then
                    DefaultCount += 1;
            until Rec.Next() = 0;
        if DefaultCount <> 1 then
            Error('Має бути рівно один основний майданчик.');
    end;

    var
        NextLineNo: Integer;
        DefaultCountry: Code[10];
        EligibilityDate: Date;
}
