codeunit 50616 "SI Workforce Mgt."
{
    procedure ResolveEmploymentContexts(EmployeeNo: Code[20]; ContextDate: Date; var EmploymentContext: Record "SI Employment Context" temporary)
    var
        ProviderCount: Integer;
    begin
        ValidateRequest(EmployeeNo, ContextDate);
        EmploymentContext.Reset();
        EmploymentContext.DeleteAll();

        OnResolveEmploymentContexts(EmployeeNo, ContextDate, EmploymentContext, ProviderCount);
        ValidateProviderCount(ProviderCount);
    end;

    procedure ResolveEmployment(EmployeeNo: Code[20]; ContextDate: Date; var Resolution: Record "SI Employment Resolution" temporary): Enum "SI Employment Resolve Status"
    var
        Status: Enum "SI Employment Resolve Status";
        ProviderCount: Integer;
    begin
        ValidateRequest(EmployeeNo, ContextDate);
        Resolution.Reset();
        Resolution.DeleteAll();

        OnResolveEmployment(EmployeeNo, ContextDate, Resolution, Status, ProviderCount);
        ValidateProviderCount(ProviderCount);
        exit(Status);
    end;

    procedure ResolveCapability(EmployeeNo: Code[20]; ContextDate: Date; CapabilityCode: Code[20]): Enum "SI Capability Resolve Status"
    var
        Capability: Record "SI Workforce Capability";
        Status: Enum "SI Capability Resolve Status";
        ProviderCount: Integer;
    begin
        ValidateRequest(EmployeeNo, ContextDate);
        if CapabilityCode = '' then
            Error(CapabilityRequiredErr);
        if not Capability.Get(CapabilityCode) then
            Error(CapabilityNotFoundErr, CapabilityCode);
        if not Capability.Active then
            Error(CapabilityInactiveErr, CapabilityCode);

        OnResolveCapability(EmployeeNo, ContextDate, CapabilityCode, Status, ProviderCount);
        ValidateProviderCount(ProviderCount);
        exit(Status);
    end;

    procedure HasCapability(EmployeeNo: Code[20]; ContextDate: Date; CapabilityCode: Code[20]): Boolean
    var
        Status: Enum "SI Capability Resolve Status";
    begin
        Status := ResolveCapability(EmployeeNo, ContextDate, CapabilityCode);
        exit(Status = Status::Granted);
    end;

    local procedure ValidateRequest(EmployeeNo: Code[20]; ContextDate: Date)
    var
        Employee: Record Employee;
    begin
        if EmployeeNo = '' then
            Error(EmployeeRequiredErr);
        if ContextDate = 0D then
            Error(ContextDateRequiredErr);
        if not Employee.Get(EmployeeNo) then
            Error(EmployeeNotFoundErr, EmployeeNo);
    end;

    local procedure ValidateProviderCount(ProviderCount: Integer)
    begin
        case ProviderCount of
            0:
                Error(ProviderMissingErr);
            1:
                exit;
            else
                Error(MultipleProvidersErr, ProviderCount);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnResolveEmploymentContexts(EmployeeNo: Code[20]; ContextDate: Date; var EmploymentContext: Record "SI Employment Context" temporary; var ProviderCount: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnResolveEmployment(EmployeeNo: Code[20]; ContextDate: Date; var Resolution: Record "SI Employment Resolution" temporary; var Status: Enum "SI Employment Resolve Status"; var ProviderCount: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnResolveCapability(EmployeeNo: Code[20]; ContextDate: Date; CapabilityCode: Code[20]; var Status: Enum "SI Capability Resolve Status"; var ProviderCount: Integer)
    begin
    end;

    var
        EmployeeRequiredErr: Label 'Employee No. must be specified.';
        ContextDateRequiredErr: Label 'Context Date must be specified.';
        EmployeeNotFoundErr: Label 'Employee %1 does not exist.', Comment = '%1 = Employee No.';
        CapabilityRequiredErr: Label 'Workforce Capability Code must be specified.';
        CapabilityNotFoundErr: Label 'Workforce Capability %1 does not exist.', Comment = '%1 = Capability Code';
        CapabilityInactiveErr: Label 'Workforce Capability %1 is inactive.', Comment = '%1 = Capability Code';
        ProviderMissingErr: Label 'No Workforce provider is installed or active. Install and configure exactly one Workforce provider.';
        MultipleProvidersErr: Label 'More than one Workforce provider handled the request (%1 providers). Exactly one provider must be active.', Comment = '%1 = provider count';
}
