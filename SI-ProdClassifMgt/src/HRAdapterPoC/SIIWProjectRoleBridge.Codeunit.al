codeunit 56206 "SI IW Project Role Bridge"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SI Project Assignment Mgt.", 'OnResolveEmployeeRoleEligibility', '', false, false)]
    local procedure ResolveEmployeeRole(EmployeeNo: Code[20]; RoleCode: Code[20]; ContextDate: Date; var IsEligible: Boolean; var IsHandled: Boolean)
    var
        CapabilityResolver: Codeunit "SI IW Capability Resolver";
    begin
        IsEligible := CapabilityResolver.HasProjectRole(EmployeeNo, ContextDate, RoleCode);
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SI Project Assignment Mgt.", 'OnCollectEligibleEmployees', '', false, false)]
    local procedure CollectEmployees(RoleCode: Code[20]; ContextDate: Date; var Employee: Record Employee; var HasEligibleEmployees: Boolean; var IsHandled: Boolean)
    var
        Candidate: Record Employee;
        CapabilityResolver: Codeunit "SI IW Capability Resolver";
    begin
        Employee.Reset();
        Employee.ClearMarks();
        HasEligibleEmployees := false;

        if Candidate.FindSet() then
            repeat
                if CapabilityResolver.HasProjectRole(Candidate."No.", ContextDate, RoleCode) then begin
                    Employee.Get(Candidate."No.");
                    Employee.Mark(true);
                    HasEligibleEmployees := true;
                end;
            until Candidate.Next() = 0;

        IsHandled := true;
    end;
}
