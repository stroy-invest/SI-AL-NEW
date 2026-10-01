interface "SI Workforce Provider"
{
    procedure GetEmployments(EmployeeNo: Code[20]; var EmploymentContext: Record "SI Employment Context");
    procedure ResolveEmploymentContexts(EmployeeNo: Code[20]; ContextDate: Date; var EmploymentContext: Record "SI Employment Context");
}
