codeunit 57072 "SI Prok Naming Mgt."
{
    procedure BuildProjectCustomerName(Project: Record Job): Text
    begin
        exit(CopyStr(StrSubstNo('CUSTOMER: %1', Project.Description), 1, 250));
    end;

    procedure BuildProjectSiteName(Project: Record Job): Text
    begin
        exit(CopyStr(StrSubstNo('SI-PRJ: %1', Project.Description), 1, 250));
    end;
}
