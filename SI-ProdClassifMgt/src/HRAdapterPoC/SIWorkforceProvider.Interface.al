interface "SI Workforce Provider"
{
    procedure GetEmployments(EmployeeNo: Code[20]; var EmploymentContext: Record "SI Employment Context");
}
