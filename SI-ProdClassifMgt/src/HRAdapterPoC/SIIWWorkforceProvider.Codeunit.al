codeunit 56200 "SI IW Workforce Provider" implements "SI Workforce Provider"
{
    procedure GetEmployments(EmployeeNo: Code[20]; var EmploymentContext: Record "SI Employment Context")
    var
        Employee: Record Employee;
        StaffEmployee: Record "IWSP Staff Employee";
        EmployeeLedgerEntry: Record "IWSP Employee Ledger Entry2";
        ManningUnit: Record "IWSP Manning Table";
        Position: Record "IWSP Position";
        Department: Record "IWSP HR Department";
        NextEntryNo: Integer;
    begin
        EmploymentContext.Reset();
        EmploymentContext.DeleteAll();

        if EmployeeNo = '' then
            exit;

        if not Employee.Get(EmployeeNo) then
            Error('Employee %1 does not exist.', EmployeeNo);

        StaffEmployee.SetRange("Person No.", EmployeeNo);
        if not StaffEmployee.FindSet() then
            exit;

        repeat
            NextEntryNo += 1;
            EmploymentContext.Init();
            EmploymentContext."Entry No." := NextEntryNo;
            EmploymentContext."Person No." := StaffEmployee."Person No.";
            EmploymentContext."Person Name" := CopyStr(Employee.FullName(), 1, MaxStrLen(EmploymentContext."Person Name"));
            EmploymentContext."Employment Context ID" := StaffEmployee."No.";
            EmploymentContext."Employment Status" := CopyStr(Format(StaffEmployee.Status), 1, MaxStrLen(EmploymentContext."Employment Status"));
            EmploymentContext."Employment Type" := CopyStr(Format(StaffEmployee."Employment Type"), 1, MaxStrLen(EmploymentContext."Employment Type"));
            EmploymentContext.Blocked := StaffEmployee.Blocked;
            EmploymentContext."Employment Date" := StaffEmployee."Employment Date";

            EmployeeLedgerEntry.Reset();
            EmployeeLedgerEntry.SetCurrentKey("Staff Employee No.", "Posting Date");
            EmployeeLedgerEntry.SetRange("Staff Employee No.", StaffEmployee."No.");
            EmployeeLedgerEntry.SetRange(Canceled, false);
            EmployeeLedgerEntry.SetRange("Actual Record", true);
            if EmployeeLedgerEntry.FindLast() then begin
                EmploymentContext."Has Actual Context" := true;
                EmploymentContext."Ledger Entry No." := EmployeeLedgerEntry."Entry No.";
                EmploymentContext."Context Posting Date" := EmployeeLedgerEntry."Posting Date";
                EmploymentContext."Context Ending Date" := EmployeeLedgerEntry."Ending Date";
                EmploymentContext."Department Code" := EmployeeLedgerEntry."Department Code";
                EmploymentContext."Unit No." := EmployeeLedgerEntry."Unit No.";
                EmploymentContext."Position Code" := EmployeeLedgerEntry."Position Code";
                EmploymentContext."Ledger Entry Type" := CopyStr(Format(EmployeeLedgerEntry."Entry Type"), 1, MaxStrLen(EmploymentContext."Ledger Entry Type"));

                if (EmployeeLedgerEntry."Department Code" <> '') and Department.Get(EmployeeLedgerEntry."Department Code") then
                    EmploymentContext."Department Name" := Department.Name;

                if (EmployeeLedgerEntry."Unit No." <> '') and ManningUnit.Get(EmployeeLedgerEntry."Unit No.") then begin
                    EmploymentContext."Unit Name" := ManningUnit.Name;
                    if EmploymentContext."Position Code" = '' then
                        EmploymentContext."Position Code" := ManningUnit."Position Code";
                end;

                if (EmploymentContext."Position Code" <> '') and Position.Get(EmploymentContext."Position Code") then
                    EmploymentContext."Position Name" := Position.Name;
            end;

            EmploymentContext.Insert();
        until StaffEmployee.Next() = 0;
    end;
}
