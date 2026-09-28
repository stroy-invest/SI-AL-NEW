page 60012 "SI Project Assignments Part"
{
    PageType = ListPart;
    SourceTable = "SI Project Assignment";
    ApplicationArea = All;
    Caption = 'Відповідальні';
    AutoSplitKey = true;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Assignments)
            {
                field(RoleDisplayName; RoleDisplayName)
                {
                    ApplicationArea = All;
                    Caption = 'Роль';
                    Lookup = true;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookupRole(Text));
                    end;
                }
                field(EmployeeDisplayName; EmployeeDisplayName)
                {
                    ApplicationArea = All;
                    Caption = 'Працівник';
                    Lookup = true;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookupEmployee(Text));
                    end;
                }
                field("Valid From"; Rec."Valid From")
                {
                    ApplicationArea = All;
                }
                field("Valid To"; Rec."Valid To")
                {
                    ApplicationArea = All;
                }
                field(Primary; Rec.Primary)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        ClearDisplayValues();

        if Rec."Valid From" = 0D then
            Rec."Valid From" := WorkDate();
    end;

    trigger OnAfterGetRecord()
    begin
        RefreshDisplayValues();
    end;

    local procedure LookupRole(var LookupText: Text): Boolean
    var
        ProjectRole: Record "SI Project Role";
        ProjectRoles: Page "SI Project Roles";
        AssignmentMgt: Codeunit "SI Project Assignment Mgt.";
    begin
        AssignmentMgt.EnsureDefaultRoles();
        ProjectRole.SetRange(Active, true);
        ProjectRole.SetRange("Assignment Scope", ProjectRole."Assignment Scope"::Project);
        ProjectRoles.SetTableView(ProjectRole);
        ProjectRoles.LookupMode(true);
        if ProjectRoles.RunModal() <> Action::LookupOK then
            exit(false);

        ProjectRoles.GetRecord(ProjectRole);
        Rec.Validate("Role Code", ProjectRole.Code);
        CurrPage.SaveRecord();
        RoleDisplayName := ProjectRole.Description;
        LookupText := ProjectRole.Description;
        exit(true);
    end;

    local procedure LookupEmployee(var LookupText: Text): Boolean
    var
        Employee: Record Employee;
        EmployeeProjectRole: Record "SI Employee Project Role";
        EmployeeList: Page "Employee List";
        HasEligibleEmployees: Boolean;
    begin
        if Rec."Role Code" = '' then
            Error('Спочатку виберіть роль у проєкті.');

        EmployeeProjectRole.SetRange("Role Code", Rec."Role Code");
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
            exit(false);

        EmployeeList.GetRecord(Employee);
        Rec.Validate("Employee No.", Employee."No.");
        CurrPage.SaveRecord();
        EmployeeDisplayName := Employee.FullName();
        LookupText := EmployeeDisplayName;
        exit(true);
    end;

    local procedure RefreshDisplayValues()
    var
        ProjectRole: Record "SI Project Role";
        Employee: Record Employee;
    begin
        ClearDisplayValues();

        if (Rec."Role Code" <> '') and ProjectRole.Get(Rec."Role Code") then
            RoleDisplayName := ProjectRole.Description;
        if (Rec."Employee No." <> '') and Employee.Get(Rec."Employee No.") then
            EmployeeDisplayName := Employee.FullName();
    end;

    local procedure ClearDisplayValues()
    begin
        Clear(RoleDisplayName);
        Clear(EmployeeDisplayName);
    end;

    var
        RoleDisplayName: Text[100];
        EmployeeDisplayName: Text[100];
}
