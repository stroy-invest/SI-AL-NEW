codeunit 56201 "SI IW Capability Resolver"
{
    procedure ResolveProjectRole(EmployeeNo: Code[20]; ContextDate: Date; RoleCode: Code[20]): Enum "SI Capability Resolve Status"
    var
        Resolution: Record "SI Employment Resolution" temporary;
        PositionRoleMap: Record "SI IW Position Role Map";
        WorkforceProvider: Codeunit "SI IW Workforce Provider";
        EmploymentStatus: Enum "SI Employment Resolve Status";
        CapabilityStatus: Enum "SI Capability Resolve Status";
    begin
        if RoleCode = '' then
            Error('Project Role Code must be specified.');

        EmploymentStatus := WorkforceProvider.ResolveEmployment(EmployeeNo, ContextDate, Resolution);

        case EmploymentStatus of
            EmploymentStatus::"Not Employed":
                exit(CapabilityStatus::"Not Employed");
            EmploymentStatus::Ambiguous:
                exit(CapabilityStatus::"Ambiguous Employment");
            EmploymentStatus::Resolved:
                begin
                    Resolution.FindFirst();
                    PositionRoleMap.SetRange("IW Position Code", Resolution."Position Code");
                    PositionRoleMap.SetRange("SI Project Role Code", RoleCode);
                    PositionRoleMap.SetRange(Active, true);
                    if PositionRoleMap.FindFirst() then
                        exit(CapabilityStatus::Granted);

                    exit(CapabilityStatus::"Not Granted");
                end;
        end;
    end;

    procedure HasProjectRole(EmployeeNo: Code[20]; ContextDate: Date; RoleCode: Code[20]): Boolean
    var
        CapabilityStatus: Enum "SI Capability Resolve Status";
    begin
        exit(ResolveProjectRole(EmployeeNo, ContextDate, RoleCode) = CapabilityStatus::Granted);
    end;
}
