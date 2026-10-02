codeunit 60002 "SI Project Assignment Mgt."
{
    procedure ApplyRoleDefaults(var Assignment: Record "SI Project Assignment")
    var
        ProjectRole: Record "SI Project Role";
    begin
        if Assignment."Role Code" = '' then
            exit;
        if not ProjectRole.Get(Assignment."Role Code") then
            exit;

        if ProjectRole."Assignment Cardinality" = ProjectRole."Assignment Cardinality"::Single then
            Assignment.Primary := true;
    end;

    procedure ValidateAssignment(Assignment: Record "SI Project Assignment")
    var
        ProjectRole: Record "SI Project Role";
        Employee: Record Employee;
    begin
        if (Assignment."Valid From" <> 0D) and (Assignment."Valid To" <> 0D) then
            if Assignment."Valid To" < Assignment."Valid From" then
                Error('Дата завершення призначення не може бути раніше дати початку.');

        if Assignment."Role Code" = '' then
            exit;

        if not ProjectRole.Get(Assignment."Role Code") then
            Error('Роль проєкту %1 не існує.', Assignment."Role Code");
        if not ProjectRole.Active then
            Error('Роль проєкту %1 неактивна.', ProjectRole.Description);
        if ProjectRole."Assignment Scope" <> ProjectRole."Assignment Scope"::Project then
            Error('Роль "%1" не може призначатися на рівні проєкту.', ProjectRole.Description);

        if Assignment."Employee No." <> '' then
            if not Employee.Get(Assignment."Employee No.") then
                Error('Працівник %1 не існує.', Assignment."Employee No.");

        if (Assignment."Role Code" <> '') and (Assignment."Employee No." <> '') then
            ValidateEmployeeRoleOnDate(Assignment."Employee No.", Assignment."Role Code", GetEligibilityDate(Assignment));

        if (Assignment."Project No." = '') or (Assignment."Employee No." = '') then
            exit;

        CheckEmployeeRoleOverlap(Assignment, ProjectRole);

        if ProjectRole."Assignment Cardinality" = ProjectRole."Assignment Cardinality"::Single then
            CheckSingleRoleOverlap(Assignment, ProjectRole);

        if Assignment.Primary then
            CheckPrimaryOverlap(Assignment, ProjectRole);
    end;

    procedure IsEmployeeEligibleForRole(EmployeeNo: Code[20]; RoleCode: Code[20]): Boolean
    begin
        exit(IsEmployeeEligibleForRoleOnDate(EmployeeNo, RoleCode, WorkDate()));
    end;

    procedure IsEmployeeEligibleForRoleOnDate(EmployeeNo: Code[20]; RoleCode: Code[20]; ContextDate: Date): Boolean
    var
        ProjectRole: Record "SI Project Role";
        WorkforceMgt: Codeunit "SI Workforce Mgt.";
    begin
        if (EmployeeNo = '') or (RoleCode = '') then
            exit(false);
        if ContextDate = 0D then
            ContextDate := WorkDate();

        GetRoleCapability(RoleCode, ProjectRole);
        exit(WorkforceMgt.HasCapability(EmployeeNo, ContextDate, ProjectRole."Required Capability Code"));
    end;

    procedure ValidateEmployeeRoleEligibility(EmployeeNo: Code[20]; RoleCode: Code[20])
    begin
        ValidateEmployeeRoleOnDate(EmployeeNo, RoleCode, WorkDate());
    end;

    procedure ValidateEmployeeRoleOnDate(EmployeeNo: Code[20]; RoleCode: Code[20]; ContextDate: Date)
    var
        Employee: Record Employee;
        ProjectRole: Record "SI Project Role";
    begin
        if IsEmployeeEligibleForRoleOnDate(EmployeeNo, RoleCode, ContextDate) then
            exit;

        Employee.Get(EmployeeNo);
        ProjectRole.Get(RoleCode);
        Error(
            'Працівник %1 не має необхідної компетенції для ролі "%2" на дату %3.',
            Employee.FullName(), ProjectRole.Description, ContextDate);
    end;

    procedure CollectEligibleEmployees(RoleCode: Code[20]; ContextDate: Date; var Employee: Record Employee): Boolean
    var
        ProjectRole: Record "SI Project Role";
        WorkforceMgt: Codeunit "SI Workforce Mgt.";
        HasEligibleEmployees: Boolean;
    begin
        Employee.Reset();
        Employee.ClearMarks();

        if ContextDate = 0D then
            ContextDate := WorkDate();

        GetRoleCapability(RoleCode, ProjectRole);

        if Employee.FindSet() then
            repeat
                if WorkforceMgt.HasCapability(Employee."No.", ContextDate, ProjectRole."Required Capability Code") then begin
                    Employee.Mark(true);
                    HasEligibleEmployees := true;
                end;
            until Employee.Next() = 0;

        Employee.MarkedOnly(true);
        exit(HasEligibleEmployees);
    end;

    procedure FindRoleByPurpose(Purpose: Enum "SI Project Role Purpose"; var ProjectRole: Record "SI Project Role"): Boolean
    begin
        ProjectRole.Reset();
        ProjectRole.SetRange(Purpose, Purpose);
        ProjectRole.SetRange(Active, true);
        exit(ProjectRole.FindFirst());
    end;

    procedure RequireRoleByPurpose(Purpose: Enum "SI Project Role Purpose"; var ProjectRole: Record "SI Project Role")
    begin
        if FindRoleByPurpose(Purpose, ProjectRole) then
            exit;
        Error('Не налаштовано активну роль із системним призначенням "%1". Відкрийте "Ролі проєкту та вимоги до працівників".', Format(Purpose));
    end;

    procedure TryGetPrimaryByPurpose(ProjectNo: Code[20]; Purpose: Enum "SI Project Role Purpose"; AsOfDate: Date; var Employee: Record Employee): Boolean
    var
        ProjectRole: Record "SI Project Role";
    begin
        if not FindRoleByPurpose(Purpose, ProjectRole) then
            exit(false);
        exit(TryGetPrimaryEmployee(ProjectNo, ProjectRole.Code, AsOfDate, Employee));
    end;

    procedure TryGetPrimaryEmployee(ProjectNo: Code[20]; RoleCode: Code[20]; AsOfDate: Date; var Employee: Record Employee): Boolean
    var
        Assignment: Record "SI Project Assignment";
    begin
        if AsOfDate = 0D then
            AsOfDate := WorkDate();

        Assignment.SetRange("Project No.", ProjectNo);
        Assignment.SetRange("Role Code", RoleCode);
        Assignment.SetRange(Primary, true);
        if Assignment.FindSet() then
            repeat
                if IsEffectiveOn(Assignment, AsOfDate) then
                    if Employee.Get(Assignment."Employee No.") then
                        exit(true);
            until Assignment.Next() = 0;

        exit(false);
    end;

    procedure RequirePrimaryEmployee(ProjectNo: Code[20]; RoleCode: Code[20]; AsOfDate: Date; var Employee: Record Employee)
    begin
        if TryGetPrimaryEmployee(ProjectNo, RoleCode, AsOfDate, Employee) then
            exit;

        Error('Для проєкту %1 не визначено чинного основного працівника в ролі %2.', ProjectNo, RoleCode);
    end;

    procedure SetEffectiveAssignments(ProjectNo: Code[20]; RoleCode: Code[20]; AsOfDate: Date; var Assignment: Record "SI Project Assignment")
    begin
        if AsOfDate = 0D then
            AsOfDate := WorkDate();

        Assignment.Reset();
        Assignment.SetRange("Project No.", ProjectNo);
        Assignment.SetRange("Role Code", RoleCode);
        Assignment.SetFilter("Valid From", '%1|<=%2', 0D, AsOfDate);
        Assignment.SetFilter("Valid To", '%1|>=%2', 0D, AsOfDate);
    end;

    local procedure CheckEmployeeRoleOverlap(Assignment: Record "SI Project Assignment"; ProjectRole: Record "SI Project Role")
    var
        Existing: Record "SI Project Assignment";
        Employee: Record Employee;
        EmployeeName: Text[100];
    begin
        Existing.SetRange("Project No.", Assignment."Project No.");
        Existing.SetRange("Role Code", Assignment."Role Code");
        Existing.SetRange("Employee No.", Assignment."Employee No.");

        if Existing.FindSet() then
            repeat
                if not IsSameAssignment(Existing, Assignment) then
                    if PeriodsOverlap(Existing."Valid From", Existing."Valid To", Assignment."Valid From", Assignment."Valid To") then begin
                        EmployeeName := Assignment."Employee No.";
                        if Employee.Get(Assignment."Employee No.") then
                            EmployeeName := Employee.FullName();

                        Error(
                            'Працівник %1 уже має роль "%2" у проєкті %3 на період, що перетинається з цим призначенням.',
                            EmployeeName, ProjectRole.Description, Assignment."Project No.");
                    end;
            until Existing.Next() = 0;
    end;

    local procedure CheckSingleRoleOverlap(Assignment: Record "SI Project Assignment"; ProjectRole: Record "SI Project Role")
    var
        Existing: Record "SI Project Assignment";
    begin
        Existing.SetRange("Project No.", Assignment."Project No.");
        Existing.SetRange("Role Code", Assignment."Role Code");
        if Existing.FindSet() then
            repeat
                if not IsSameAssignment(Existing, Assignment) then
                    if PeriodsOverlap(Existing."Valid From", Existing."Valid To", Assignment."Valid From", Assignment."Valid To") then
                        Error('Для проєкту %1 роль "%2" може мати лише одного чинного працівника. Уже призначено %3.', Assignment."Project No.", ProjectRole.Description, Existing."Employee No.");
            until Existing.Next() = 0;
    end;

    local procedure CheckPrimaryOverlap(Assignment: Record "SI Project Assignment"; ProjectRole: Record "SI Project Role")
    var
        Existing: Record "SI Project Assignment";
    begin
        Existing.SetRange("Project No.", Assignment."Project No.");
        Existing.SetRange("Role Code", Assignment."Role Code");
        Existing.SetRange(Primary, true);
        if Existing.FindSet() then
            repeat
                if not IsSameAssignment(Existing, Assignment) then
                    if PeriodsOverlap(Existing."Valid From", Existing."Valid To", Assignment."Valid From", Assignment."Valid To") then
                        Error('Для проєкту %1 у ролі "%2" вже визначено основного працівника %3 на цей період.', Assignment."Project No.", ProjectRole.Description, Existing."Employee No.");
            until Existing.Next() = 0;
    end;

    local procedure IsSameAssignment(LeftAssignment: Record "SI Project Assignment"; RightAssignment: Record "SI Project Assignment"): Boolean
    begin
        exit((LeftAssignment."Project No." = RightAssignment."Project No.") and
             (LeftAssignment."Line No." = RightAssignment."Line No."));
    end;

    local procedure PeriodsOverlap(From1: Date; To1: Date; From2: Date; To2: Date): Boolean
    var
        EffectiveFrom1: Date;
        EffectiveFrom2: Date;
        EffectiveTo1: Date;
        EffectiveTo2: Date;
    begin
        EffectiveFrom1 := From1;
        EffectiveFrom2 := From2;
        if EffectiveFrom1 = 0D then
            EffectiveFrom1 := DMY2Date(1, 1, 1753);
        if EffectiveFrom2 = 0D then
            EffectiveFrom2 := DMY2Date(1, 1, 1753);

        EffectiveTo1 := To1;
        EffectiveTo2 := To2;
        if EffectiveTo1 = 0D then
            EffectiveTo1 := DMY2Date(31, 12, 9999);
        if EffectiveTo2 = 0D then
            EffectiveTo2 := DMY2Date(31, 12, 9999);

        exit((EffectiveFrom1 <= EffectiveTo2) and (EffectiveFrom2 <= EffectiveTo1));
    end;

    local procedure IsEffectiveOn(Assignment: Record "SI Project Assignment"; AsOfDate: Date): Boolean
    begin
        exit(((Assignment."Valid From" = 0D) or (Assignment."Valid From" <= AsOfDate)) and
             ((Assignment."Valid To" = 0D) or (Assignment."Valid To" >= AsOfDate)));
    end;

    local procedure GetEligibilityDate(Assignment: Record "SI Project Assignment"): Date
    begin
        if Assignment."Valid From" <> 0D then
            exit(Assignment."Valid From");
        exit(WorkDate());
    end;

    local procedure GetRoleCapability(RoleCode: Code[20]; var ProjectRole: Record "SI Project Role")
    begin
        if not ProjectRole.Get(RoleCode) then
            Error('Роль проєкту %1 не існує.', RoleCode);
        if not ProjectRole.Active then
            Error('Роль проєкту %1 неактивна.', ProjectRole.Description);
        if ProjectRole."Required Capability Code" = '' then
            Error('Для ролі "%1" не налаштовано необхідну Workforce-компетенцію.', ProjectRole.Description);
    end;

}
