codeunit 50602 "SI Org. Identity Mgt."
{
    Permissions =
        tabledata User = R,
        tabledata Employee = R,
        tabledata "SI User Employee Link" = R;

    procedure TryGetEmployee(UserSecurityId: Guid; var Employee: Record Employee): Boolean
    var
        UserEmployeeLink: Record "SI User Employee Link";
    begin
        Clear(Employee);

        if IsNullGuid(UserSecurityId) then
            exit(false);

        if not UserEmployeeLink.Get(UserSecurityId) then
            exit(false);

        if UserEmployeeLink."Employee No." = '' then
            exit(false);

        exit(Employee.Get(UserEmployeeLink."Employee No."));
    end;

    procedure TryGetCurrentEmployee(var Employee: Record Employee): Boolean
    begin
        exit(TryGetEmployee(UserSecurityId(), Employee));
    end;

    procedure RequireEmployee(UserSecurityId: Guid; var Employee: Record Employee)
    begin
        if TryGetEmployee(UserSecurityId, Employee) then
            exit;

        Error(EmployeeMappingRequiredErr, UserSecurityId);
    end;

    procedure RequireCurrentEmployee(var Employee: Record Employee)
    begin
        if TryGetCurrentEmployee(Employee) then
            exit;

        Error(CurrentEmployeeMappingRequiredErr, UserId());
    end;

    procedure TryGetUser(EmployeeNo: Code[20]; var UserRecord: Record User): Boolean
    var
        UserEmployeeLink: Record "SI User Employee Link";
    begin
        Clear(UserRecord);

        if EmployeeNo = '' then
            exit(false);

        UserEmployeeLink.SetRange("Employee No.", EmployeeNo);
        if not UserEmployeeLink.FindFirst() then
            exit(false);

        exit(UserRecord.Get(UserEmployeeLink."User Security ID"));
    end;

    procedure RequireUser(EmployeeNo: Code[20]; var UserRecord: Record User)
    begin
        if TryGetUser(EmployeeNo, UserRecord) then
            exit;

        Error(UserMappingRequiredErr, EmployeeNo);
    end;

    var
        EmployeeMappingRequiredErr: Label 'Для користувача з ідентифікатором %1 не налаштовано зв''язок із працівником.', Comment = '%1 = User Security ID';
        CurrentEmployeeMappingRequiredErr: Label 'Для поточного користувача %1 не налаштовано зв''язок із працівником.', Comment = '%1 = User ID';
        UserMappingRequiredErr: Label 'Для працівника %1 не налаштовано зв''язок із користувачем Business Central.', Comment = '%1 = Employee No.';
}
