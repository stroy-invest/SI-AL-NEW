page 60021 "SI Site Assignments Part"
{
    PageType = ListPart;
    SourceTable = "SI Site Assignment";
    ApplicationArea = All;
    Caption = 'Виконроби';
    AutoSplitKey = true;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Foremen)
            {
                field(EmployeeDisplayName; EmployeeDisplayName)
                {
                    ApplicationArea = All;
                    Caption = 'Виконроб';
                    Lookup = true;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookupEmployee(Text));
                    end;
                }
                field("Valid From"; Rec."Valid From") { ApplicationArea = All; }
                field("Valid To"; Rec."Valid To") { ApplicationArea = All; }
                field(Primary; Rec.Primary)
                {
                    ApplicationArea = All;
                    Caption = 'Основний';
                }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        ProjectRole: Record "SI Project Role";
        AssignmentMgt: Codeunit "SI Project Assignment Mgt.";
    begin
        AssignmentMgt.RequireRoleByPurpose("SI Project Role Purpose"::SiteSupervisor, ProjectRole);
        Rec."Role Code" := ProjectRole.Code;
        if Rec."Valid From" = 0D then
            Rec."Valid From" := WorkDate();
        Clear(EmployeeDisplayName);
    end;

    trigger OnAfterGetRecord()
    var
        Employee: Record Employee;
    begin
        Clear(EmployeeDisplayName);
        if (Rec."Employee No." <> '') and Employee.Get(Rec."Employee No.") then
            EmployeeDisplayName := Employee.FullName();
    end;

    local procedure LookupEmployee(var LookupText: Text): Boolean
    var
        Employee: Record Employee;
        EmployeeLookup: Page "SI Eligible Employee Lookup";
        AssignmentMgt: Codeunit "SI Project Assignment Mgt.";
        EligibilityDate: Date;
    begin
        EligibilityDate := Rec."Valid From";
        if EligibilityDate = 0D then
            EligibilityDate := WorkDate();

        if not AssignmentMgt.CollectEligibleEmployees(Rec."Role Code", EligibilityDate, Employee) then
            Error('На дату %1 немає працівників, які мають Workforce-компетенцію для ролі виконроба.', EligibilityDate);

        EmployeeLookup.LoadEligible(Rec."Role Code", EligibilityDate);
        EmployeeLookup.LookupMode(true);
        if EmployeeLookup.RunModal() <> Action::LookupOK then
            exit(false);

        Employee.Get(EmployeeLookup.GetSelectedEmployeeNo());
        Rec.Validate("Employee No.", Employee."No.");
        CurrPage.SaveRecord();
        EmployeeDisplayName := Employee.FullName();
        LookupText := EmployeeDisplayName;
        exit(true);
    end;

    var
        EmployeeDisplayName: Text[100];
}
