codeunit 50602 "SI Org. Identity Mgt."
{
    Permissions =
        tabledata User = R,
        tabledata Employee = R,
        tabledata "SI User Identity Assignment" = R,
        tabledata "SI User Identity Purpose" = R;

    procedure ResolveEmployee(UserSecurityId: Guid; ContextDate: Date; var Employee: Record Employee): Enum "SI Identity Resolve Status"
    var
        Assignment: Record "SI User Identity Assignment";
        ResolvedEmployeeNo: Code[20];
    begin
        Clear(Employee);

        if IsNullGuid(UserSecurityId) or (ContextDate = 0D) then
            exit(Enum::"SI Identity Resolve Status"::"Not Assigned");

        Assignment.SetRange("User Security ID", UserSecurityId);
        if Assignment.FindSet() then
            repeat
                if IsEffectiveOnDate(Assignment."Valid From", Assignment."Valid To", ContextDate) then begin
                    if ResolvedEmployeeNo = '' then
                        ResolvedEmployeeNo := Assignment."Employee No."
                    else
                        if ResolvedEmployeeNo <> Assignment."Employee No." then
                            exit(Enum::"SI Identity Resolve Status"::Ambiguous);
                end;
            until Assignment.Next() = 0;

        if ResolvedEmployeeNo = '' then
            exit(Enum::"SI Identity Resolve Status"::"Not Assigned");

        if not Employee.Get(ResolvedEmployeeNo) then
            exit(Enum::"SI Identity Resolve Status"::"Not Assigned");

        exit(Enum::"SI Identity Resolve Status"::Resolved);
    end;

    procedure ResolveUser(EmployeeNo: Code[20]; PurposeCode: Code[50]; ContextDate: Date; var UserRecord: Record User): Enum "SI Identity Resolve Status"
    var
        Assignment: Record "SI User Identity Assignment";
        ResolvedUserSecurityId: Guid;
    begin
        Clear(UserRecord);

        if (EmployeeNo = '') or (PurposeCode = '') or (ContextDate = 0D) then
            exit(Enum::"SI Identity Resolve Status"::"Not Assigned");

        Assignment.SetRange("Employee No.", EmployeeNo);
        Assignment.SetRange("Purpose Code", PurposeCode);
        if Assignment.FindSet() then
            repeat
                if IsEffectiveOnDate(Assignment."Valid From", Assignment."Valid To", ContextDate) then begin
                    if IsNullGuid(ResolvedUserSecurityId) then
                        ResolvedUserSecurityId := Assignment."User Security ID"
                    else
                        if ResolvedUserSecurityId <> Assignment."User Security ID" then
                            exit(Enum::"SI Identity Resolve Status"::Ambiguous);
                end;
            until Assignment.Next() = 0;

        if IsNullGuid(ResolvedUserSecurityId) then
            exit(Enum::"SI Identity Resolve Status"::"Not Assigned");

        if not UserRecord.Get(ResolvedUserSecurityId) then
            exit(Enum::"SI Identity Resolve Status"::"Not Assigned");

        exit(Enum::"SI Identity Resolve Status"::Resolved);
    end;

    procedure RequireEmployee(UserSecurityId: Guid; ContextDate: Date; var Employee: Record Employee)
    var
        Status: Enum "SI Identity Resolve Status";
    begin
        Status := ResolveEmployee(UserSecurityId, ContextDate, Employee);
        case Status of
            Status::Resolved:
                exit;
            Status::Ambiguous:
                Error(EmployeeAmbiguousErr, UserSecurityId, ContextDate);
            else
                Error(EmployeeNotAssignedErr, UserSecurityId, ContextDate);
        end;
    end;

    procedure RequireUser(EmployeeNo: Code[20]; PurposeCode: Code[50]; ContextDate: Date; var UserRecord: Record User)
    var
        Status: Enum "SI Identity Resolve Status";
    begin
        Status := ResolveUser(EmployeeNo, PurposeCode, ContextDate, UserRecord);
        case Status of
            Status::Resolved:
                exit;
            Status::Ambiguous:
                Error(UserAmbiguousErr, EmployeeNo, PurposeCode, ContextDate);
            else
                Error(UserNotAssignedErr, EmployeeNo, PurposeCode, ContextDate);
        end;
    end;

    local procedure IsEffectiveOnDate(ValidFrom: Date; ValidTo: Date; ContextDate: Date): Boolean
    begin
        if (ValidFrom = 0D) or (ValidFrom > ContextDate) then
            exit(false);
        if (ValidTo <> 0D) and (ValidTo < ContextDate) then
            exit(false);
        exit(true);
    end;

    var
        EmployeeNotAssignedErr: Label 'Для користувача з ідентифікатором %1 на дату %2 не налаштовано призначення працівника.', Comment = '%1 = User Security ID, %2 = Context Date';
        EmployeeAmbiguousErr: Label 'Для користувача з ідентифікатором %1 на дату %2 знайдено неоднозначне призначення працівника. Перевірте налаштування Organizational Identity.', Comment = '%1 = User Security ID, %2 = Context Date';
        UserNotAssignedErr: Label 'Для працівника %1, функції %2 і дати %3 не налаштовано обліковий запис Business Central.', Comment = '%1 = Employee No., %2 = Purpose Code, %3 = Context Date';
        UserAmbiguousErr: Label 'Для працівника %1, функції %2 і дати %3 знайдено кілька облікових записів Business Central. Перевірте налаштування Organizational Identity.', Comment = '%1 = Employee No., %2 = Purpose Code, %3 = Context Date';
}
