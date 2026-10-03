codeunit 61062 "SI Supply Req Creator Mgt."
{
    procedure TryGetCreatorDisplay(Request: Record "SI Supply Req Header"; var CreatorDisplay: Text[500]; var WarningText: Text): Boolean
    begin
        Clear(CreatorDisplay);
        Clear(WarningText);

        if TryBuildCreatorDisplay(Request, CreatorDisplay) then
            exit(true);

        WarningText := GetLastErrorText();
        if WarningText = '' then
            WarningText := CreatorContextUnavailableMsg;
        exit(false);
    end;

    [TryFunction]
    local procedure TryBuildCreatorDisplay(Request: Record "SI Supply Req Header"; var CreatorDisplay: Text[500])
    var
        UserRecord: Record User;
        Employee: Record Employee;
        Resolution: Record "SI Employment Resolution" temporary;
        IdentityMgt: Codeunit "SI Org. Identity Mgt.";
        WorkforceMgt: Codeunit "SI Workforce Mgt.";
        IdentityStatus: Enum "SI Identity Resolve Status";
        EmploymentStatus: Enum "SI Employment Resolve Status";
        ContextDate: Date;
    begin
        Request.TestField("Requested By User ID");
        Request.TestField("Created At");

        ContextDate := DT2Date(Request."Created At");
        ResolveTechnicalUser(Request."Requested By User ID", UserRecord);

        IdentityStatus := IdentityMgt.ResolveEmployee(UserRecord."User Security ID", ContextDate, Employee);
        case IdentityStatus of
            IdentityStatus::Resolved:
                ;
            IdentityStatus::Ambiguous:
                Error(IdentityAmbiguousErr, Request."Requested By User ID", ContextDate);
            else
                Error(IdentityMissingErr, Request."Requested By User ID", ContextDate);
        end;

        EmploymentStatus := WorkforceMgt.ResolveEmployment(Employee."No.", ContextDate, Resolution);
        case EmploymentStatus of
            EmploymentStatus::Resolved:
                begin
                    if not Resolution.FindFirst() then
                        Error(ResolvedContextMissingErr, Employee."No.", ContextDate);
                    if Resolution."Position Name" = '' then
                        Error(PositionMissingErr, Employee."No.", ContextDate);
                end;
            EmploymentStatus::Ambiguous:
                Error(EmploymentAmbiguousErr, Employee."No.", ContextDate);
            else
                Error(EmploymentMissingErr, Employee."No.", ContextDate);
        end;

        CreatorDisplay := StrSubstNo('%1 %2', Resolution."Position Name", FormatEmployeeName(Employee));
    end;

    local procedure ResolveTechnicalUser(UserName: Code[50]; var UserRecord: Record User)
    begin
        UserRecord.Reset();
        UserRecord.SetRange("User Name", UserName);
        case UserRecord.Count() of
            0:
                Error(UserNotFoundErr, UserName);
            1:
                UserRecord.FindFirst();
            else
                Error(UserAmbiguousErr, UserName);
        end;
    end;

    local procedure FormatEmployeeName(Employee: Record Employee): Text[150]
    var
        Initials: Text[10];
    begin
        if Employee."Last Name" = '' then
            Error(EmployeeLastNameMissingErr, Employee."No.");
        if Employee."First Name" = '' then
            Error(EmployeeFirstNameMissingErr, Employee."No.");

        Initials := CopyStr(Employee."First Name", 1, 1) + '.';
        if Employee."Middle Name" <> '' then
            Initials += CopyStr(Employee."Middle Name", 1, 1) + '.';

        exit(StrSubstNo('%1 %2', Employee."Last Name", Initials));
    end;

    var
        CreatorContextUnavailableMsg: Label 'Не вдалося визначити бізнес-контекст автора заявки.';
        UserNotFoundErr: Label 'Користувача %1, який створив заявку, не знайдено серед користувачів Business Central.', Comment = '%1 = User Name';
        UserAmbiguousErr: Label 'Для імені користувача %1 знайдено кілька користувачів Business Central. Неможливо однозначно визначити автора заявки.', Comment = '%1 = User Name';
        IdentityMissingErr: Label 'Для користувача %1 на дату %2 не знайдено призначення працівника.', Comment = '%1 = User Name, %2 = Context Date';
        IdentityAmbiguousErr: Label 'Для користувача %1 на дату %2 знайдено неоднозначне призначення працівника.', Comment = '%1 = User Name, %2 = Context Date';
        EmploymentMissingErr: Label 'Для працівника %1 на дату %2 не знайдено чинного контексту зайнятості.', Comment = '%1 = Employee No., %2 = Context Date';
        EmploymentAmbiguousErr: Label 'Для працівника %1 на дату %2 знайдено кілька чинних контекстів зайнятості. Неможливо однозначно визначити посаду автора заявки.', Comment = '%1 = Employee No., %2 = Context Date';
        ResolvedContextMissingErr: Label 'Workforce повернув статус Resolved для працівника %1 на дату %2, але не повернув контекст зайнятості.', Comment = '%1 = Employee No., %2 = Context Date';
        PositionMissingErr: Label 'Для працівника %1 на дату %2 у контексті зайнятості не визначено назву посади.', Comment = '%1 = Employee No., %2 = Context Date';
        EmployeeLastNameMissingErr: Label 'Для працівника %1 не заповнено прізвище. Неможливо сформувати відображення автора заявки.', Comment = '%1 = Employee No.';
        EmployeeFirstNameMissingErr: Label 'Для працівника %1 не заповнено ім’я. Неможливо сформувати відображення автора заявки.', Comment = '%1 = Employee No.';
}
