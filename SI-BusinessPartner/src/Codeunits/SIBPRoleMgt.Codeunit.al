codeunit 54030 "SI BP Role Mgt."
{
    procedure CreateRole(
        BusinessPartnerNo: Code[20];
        RoleType: Enum "SI BP Role Type";
        var Role: Record "SI BP Role")
    var
        BusinessPartner: Record "SI Business Partner";
        ExistingRole: Record "SI BP Role";
    begin
        if BusinessPartnerNo = '' then
            Error(
                'Не зазначено контрагента.');

        if not BusinessPartner.Get(
            BusinessPartnerNo)
        then
            Error(
                'Контрагента %1 не знайдено.',
                BusinessPartnerNo);

        ExistingRole.SetRange(
            "Business Partner No.",
            BusinessPartnerNo);

        ExistingRole.SetRange(
            "Role Type",
            RoleType);

        ExistingRole.SetFilter(
            Status,
            '<>%1&<>%2',
            ExistingRole.Status::Inactive,
            ExistingRole.Status::Closed);

        if ExistingRole.FindFirst() then
            Error(
                'Для контрагента %1 вже існує поточна роль типу %2 (%3). Спочатку завершіть її життєвий цикл.',
                BusinessPartnerNo,
                Format(RoleType),
                ExistingRole.Code);

        Role.Init();

        Role.Code :=
            GenerateRoleCode(
                BusinessPartnerNo,
                RoleType);

        Role."Business Partner No." :=
            BusinessPartnerNo;

        Role."Role Type" :=
            RoleType;

        Role.Status :=
            Role.Status::Draft;

        Role.Insert(true);

    end;

    procedure SubmitRole(
        var Role: Record "SI BP Role";
        Reason: Text;
        Comment: Text)
    begin
        ChangeStatus(
            Role,
            Role.Status::Configured,
            Reason,
            Comment,
            Enum::"SI BP Role Chg. Source"::Manual);
    end;

    procedure ReturnToDraft(
        var Role: Record "SI BP Role";
        Reason: Text;
        Comment: Text)
    begin
        ChangeStatus(
            Role,
            Role.Status::Draft,
            Reason,
            Comment,
            Enum::"SI BP Role Chg. Source"::Manual);
    end;

    procedure ActivateRole(
        var Role: Record "SI BP Role";
        Reason: Text;
        Comment: Text)
    var
        BPBankMgt: Codeunit "SI BP Bank Mgt.";
    begin
        BPBankMgt.ValidateBankingReady(
            Role);

        ChangeStatus(
            Role,
            Role.Status::Active,
            Reason,
            Comment,
            Enum::"SI BP Role Chg. Source"::Manual);
    end;

    procedure BlockRole(
        var Role: Record "SI BP Role";
        Reason: Text;
        Comment: Text)
    begin
        ChangeStatus(
            Role,
            Role.Status::Blocked,
            Reason,
            Comment,
            Enum::"SI BP Role Chg. Source"::Manual);
    end;

    procedure UnblockRole(
        var Role: Record "SI BP Role";
        Reason: Text;
        Comment: Text)
    begin
        ChangeStatus(
            Role,
            Role.Status::Active,
            Reason,
            Comment,
            Enum::"SI BP Role Chg. Source"::Manual);
    end;

    procedure DeactivateRole(
        var Role: Record "SI BP Role";
        Reason: Text;
        Comment: Text)
    begin
        ChangeStatus(
            Role,
            Role.Status::Inactive,
            Reason,
            Comment,
            Enum::"SI BP Role Chg. Source"::Manual);
    end;

    procedure ChangeStatus(
        var Role: Record "SI BP Role";
        NewStatus: Enum "SI BP Role Status";
        Reason: Text;
        Comment: Text;
        Source: Enum "SI BP Role Chg. Source")
    var
        OldStatus: Enum "SI BP Role Status";
    begin
        Role.TestField(Code);

        if not Role.Get(
            Role.Code)
        then
            Error(
                'Роль %1 не знайдено.',
                Role.Code);

        OldStatus :=
            Role.Status;

        if not CanTransition(
            OldStatus,
            NewStatus)
        then
            Error(
                'Перехід ролі зі стану %1 до стану %2 не дозволений.',
                Format(OldStatus),
                Format(NewStatus));

        Role.Status :=
            NewStatus;

        Role."Last Changed At" :=
            CurrentDateTime;

        Role."Last Changed By" :=
            CopyStr(
                UserId(),
                1,
                MaxStrLen(
                    Role."Last Changed By"));

        case NewStatus of
            NewStatus::Active:
                Role."Last Activated At" :=
                    CurrentDateTime;

            NewStatus::Inactive:
                Role."Last Inactivated At" :=
                    CurrentDateTime;
        end;

        Role.Modify(true);

        WriteHistory(
            Role,
            OldStatus,
            NewStatus,
            Reason,
            Comment,
            Source);

        OnAfterRoleStatusChanged(
            Role,
            OldStatus,
            NewStatus);
    end;

    procedure CanTransition(
        OldStatus: Enum "SI BP Role Status";
        NewStatus: Enum "SI BP Role Status"): Boolean
    begin
        case OldStatus of
            OldStatus::Draft:
                exit(NewStatus = NewStatus::Configured);

            OldStatus::Configured:
                exit(
                    (NewStatus = NewStatus::Draft) or
                    (NewStatus = NewStatus::Active));

            OldStatus::Active:
                exit(
                    (NewStatus = NewStatus::Blocked) or
                    (NewStatus = NewStatus::Inactive));

            OldStatus::Blocked:
                exit(
                    (NewStatus = NewStatus::Active) or
                    (NewStatus = NewStatus::Inactive));

            OldStatus::Inactive,
            OldStatus::Closed:
                exit(false);
        end;

        exit(false);
    end;

    local procedure GenerateRoleCode(
        BusinessPartnerNo: Code[20];
        RoleType: Enum "SI BP Role Type"): Code[30]
    var
        ExistingRole: Record "SI BP Role";
        RoleCode: Code[30];
        BaseCode: Text;
        Suffix: Text;
        SequenceNo: Integer;
    begin
        case RoleType of
            RoleType::Customer:
                Suffix := '-CUST';

            RoleType::Vendor:
                Suffix := '-VEND';
        end;

        BaseCode := BusinessPartnerNo + Suffix;

        if StrLen(BaseCode) > MaxStrLen(RoleCode) then
            Error(
                'Неможливо сформувати код ролі для контрагента %1.',
                BusinessPartnerNo);

        RoleCode := CopyStr(BaseCode, 1, MaxStrLen(RoleCode));
        if not ExistingRole.Get(RoleCode) then
            exit(RoleCode);

        for SequenceNo := 2 to 999 do begin
            RoleCode :=
                CopyStr(
                    StrSubstNo('%1-%2', BaseCode, SequenceNo),
                    1,
                    MaxStrLen(RoleCode));

            if not ExistingRole.Get(RoleCode) then
                exit(RoleCode);
        end;

        Error(
            'Не вдалося сформувати унікальний код ролі для контрагента %1.',
            BusinessPartnerNo);
    end;

    local procedure WriteHistory(
        Role: Record "SI BP Role";
        OldStatus: Enum "SI BP Role Status";
        NewStatus: Enum "SI BP Role Status";
        Reason: Text;
        Comment: Text;
        Source: Enum "SI BP Role Chg. Source")
    var
        StatusEntry: Record "SI BP Role Status Entry";
    begin
        StatusEntry.Init();

        StatusEntry."Role Code" :=
            Role.Code;

        StatusEntry."Business Partner No." :=
            Role."Business Partner No.";

        StatusEntry."Role Type" :=
            Role."Role Type";

        StatusEntry."Old Status" :=
            OldStatus;

        StatusEntry."New Status" :=
            NewStatus;

        StatusEntry."Changed At" :=
            CurrentDateTime;

        StatusEntry."Changed By" :=
            CopyStr(
                UserId(),
                1,
                MaxStrLen(
                    StatusEntry."Changed By"));

        StatusEntry.Reason :=
            CopyStr(
                Reason,
                1,
                MaxStrLen(
                    StatusEntry.Reason));

        StatusEntry.Comment :=
            CopyStr(
                Comment,
                1,
                MaxStrLen(
                    StatusEntry.Comment));

        StatusEntry.Source :=
            Source;

        StatusEntry.Insert(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRoleStatusChanged(
        var Role: Record "SI BP Role";
        OldStatus: Enum "SI BP Role Status";
        NewStatus: Enum "SI BP Role Status")
    begin
    end;
}