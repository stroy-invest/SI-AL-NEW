codeunit 60005 "SI Site Assignment Mgt."
{
    procedure ValidateAssignment(Assignment: Record "SI Site Assignment")
    var
        Site: Record "SI Construction Site";
        ProjectRole: Record "SI Project Role";
        Employee: Record Employee;
        ProjectAssignmentMgt: Codeunit "SI Project Assignment Mgt.";
    begin
        if (Assignment."Valid From" <> 0D) and (Assignment."Valid To" <> 0D) then
            if Assignment."Valid To" < Assignment."Valid From" then
                Error('Дата завершення призначення не може бути раніше дати початку.');

        if (Assignment."Project No." <> '') and (Assignment."Site Code" <> '') then begin
            if not Site.Get(Assignment."Project No.", Assignment."Site Code") then
                Error('Будівельний майданчик %1 не належить проєкту %2.', Assignment."Site Code", Assignment."Project No.");
            if Site.Status <> Site.Status::Active then
                Error('Нові призначення дозволені лише для активного будівельного майданчика.');
        end;

        if Assignment."Role Code" = '' then
            exit;
        if not ProjectRole.Get(Assignment."Role Code") then
            Error('Роль %1 не існує.', Assignment."Role Code");
        if not ProjectRole.Active then
            Error('Роль %1 неактивна.', ProjectRole.Description);
        if ProjectRole."Assignment Scope" <> ProjectRole."Assignment Scope"::Site then
            Error('Роль "%1" не може призначатися на рівні будівельного майданчика.', ProjectRole.Description);

        if Assignment."Employee No." <> '' then begin
            if not Employee.Get(Assignment."Employee No.") then
                Error('Працівник %1 не існує.', Assignment."Employee No.");
            ProjectAssignmentMgt.ValidateEmployeeRoleOnDate(
                Assignment."Employee No.",
                Assignment."Role Code",
                GetEligibilityDate(Assignment));
        end;

        if (Assignment."Project No." = '') or (Assignment."Site Code" = '') or (Assignment."Employee No." = '') then
            exit;

        CheckEmployeeOverlap(Assignment, ProjectRole.Description);
        if Assignment.Primary then
            CheckPrimaryOverlap(Assignment, ProjectRole.Description);
    end;

    local procedure GetEligibilityDate(Assignment: Record "SI Site Assignment"): Date
    begin
        if Assignment."Valid From" <> 0D then
            exit(Assignment."Valid From");

        exit(WorkDate());
    end;

    local procedure CheckEmployeeOverlap(Assignment: Record "SI Site Assignment"; RoleDescription: Text[100])
    var
        Existing: Record "SI Site Assignment";
    begin
        Existing.SetRange("Project No.", Assignment."Project No.");
        Existing.SetRange("Site Code", Assignment."Site Code");
        Existing.SetRange("Role Code", Assignment."Role Code");
        Existing.SetRange("Employee No.", Assignment."Employee No.");
        if Existing.FindSet() then
            repeat
                if Existing."Line No." <> Assignment."Line No." then
                    if PeriodsOverlap(Existing."Valid From", Existing."Valid To", Assignment."Valid From", Assignment."Valid To") then
                        Error('Працівник %1 уже має роль "%2" на цьому майданчику в період, що перетинається.', Assignment."Employee No.", RoleDescription);
            until Existing.Next() = 0;
    end;

    local procedure CheckPrimaryOverlap(Assignment: Record "SI Site Assignment"; RoleDescription: Text[100])
    var
        Existing: Record "SI Site Assignment";
    begin
        Existing.SetRange("Project No.", Assignment."Project No.");
        Existing.SetRange("Site Code", Assignment."Site Code");
        Existing.SetRange("Role Code", Assignment."Role Code");
        Existing.SetRange(Primary, true);
        if Existing.FindSet() then
            repeat
                if Existing."Line No." <> Assignment."Line No." then
                    if PeriodsOverlap(Existing."Valid From", Existing."Valid To", Assignment."Valid From", Assignment."Valid To") then
                        Error('На цьому майданчику вже є основний працівник у ролі "%1" на період, що перетинається.', RoleDescription);
            until Existing.Next() = 0;
    end;

    local procedure PeriodsOverlap(From1: Date; To1: Date; From2: Date; To2: Date): Boolean
    var
        Start1: Date;
        End1: Date;
        Start2: Date;
        End2: Date;
    begin
        Start1 := From1; if Start1 = 0D then Start1 := DMY2Date(1, 1, 1753);
        End1 := To1; if End1 = 0D then End1 := DMY2Date(31, 12, 9999);
        Start2 := From2; if Start2 = 0D then Start2 := DMY2Date(1, 1, 1753);
        End2 := To2; if End2 = 0D then End2 := DMY2Date(31, 12, 9999);
        exit((Start1 <= End2) and (Start2 <= End1));
    end;
}
