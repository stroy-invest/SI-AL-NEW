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
                FillFromLedgerEntry(EmploymentContext, EmployeeLedgerEntry);
                FillNames(EmploymentContext, ManningUnit, Position, Department);
            end;

            EmploymentContext.Insert();
        until StaffEmployee.Next() = 0;
    end;

    procedure ResolveEmploymentContexts(EmployeeNo: Code[20]; ContextDate: Date; var EmploymentContext: Record "SI Employment Context")
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

        if ContextDate = 0D then
            Error('Context Date must be specified.');

        if not Employee.Get(EmployeeNo) then
            Error('Employee %1 does not exist.', EmployeeNo);

        StaffEmployee.SetRange("Person No.", EmployeeNo);
        if not StaffEmployee.FindSet() then
            exit;

        repeat
            if FindLastLedgerEntryOnDate(StaffEmployee."No.", ContextDate, EmployeeLedgerEntry) then
                if IsActiveContextEntry(EmployeeLedgerEntry) then begin
                    NextEntryNo += 1;
                    EmploymentContext.Init();
                    EmploymentContext."Entry No." := NextEntryNo;
                    EmploymentContext."Person No." := StaffEmployee."Person No.";
                    EmploymentContext."Person Name" := CopyStr(Employee.FullName(), 1, MaxStrLen(EmploymentContext."Person Name"));
                    EmploymentContext."Employment Context ID" := StaffEmployee."No.";
                    EmploymentContext."Employment Status" := CopyStr(Format(StaffEmployee.Status), 1, MaxStrLen(EmploymentContext."Employment Status"));
                    EmploymentContext."Employment Type" := CopyStr(Format(EmployeeLedgerEntry."Employment Type"), 1, MaxStrLen(EmploymentContext."Employment Type"));
                    EmploymentContext.Blocked := StaffEmployee.Blocked;
                    EmploymentContext."Employment Date" := StaffEmployee."Employment Date";
                    EmploymentContext."Has Actual Context" := EmployeeLedgerEntry."Actual Record";
                    EmploymentContext."Resolved for Date" := ContextDate;
                    EmploymentContext."Is Active on Context Date" := true;

                    FillFromLedgerEntry(EmploymentContext, EmployeeLedgerEntry);
                    FillNames(EmploymentContext, ManningUnit, Position, Department);
                    EmploymentContext.Insert();
                end;
        until StaffEmployee.Next() = 0;
    end;

    procedure ResolveEmployment(EmployeeNo: Code[20]; ContextDate: Date; var Resolution: Record "SI Employment Resolution"): Enum "SI Employment Resolve Status"
    var
        EmploymentContext: Record "SI Employment Context" temporary;
        Employee: Record Employee;
        ResolutionStatus: Enum "SI Employment Resolve Status";
        ActiveContextCount: Integer;
    begin
        Resolution.Reset();
        Resolution.DeleteAll();

        ResolveEmploymentContexts(EmployeeNo, ContextDate, EmploymentContext);
        ActiveContextCount := EmploymentContext.Count();

        case ActiveContextCount of
            0:
                ResolutionStatus := ResolutionStatus::"Not Employed";
            1:
                ResolutionStatus := ResolutionStatus::Resolved;
            else
                ResolutionStatus := ResolutionStatus::Ambiguous;
        end;

        Resolution.Init();
        Resolution."Entry No." := 1;
        Resolution.Status := ResolutionStatus;
        Resolution."Context Date" := ContextDate;
        Resolution."Employee No." := EmployeeNo;
        Resolution."Active Context Count" := ActiveContextCount;

        if Employee.Get(EmployeeNo) then
            Resolution."Employee Name" := CopyStr(Employee.FullName(), 1, MaxStrLen(Resolution."Employee Name"));

        if ResolutionStatus = ResolutionStatus::Resolved then begin
            EmploymentContext.FindFirst();
            Resolution."Employment Context ID" := EmploymentContext."Employment Context ID";
            Resolution."Employment Type" := EmploymentContext."Employment Type";
            Resolution."Department Code" := EmploymentContext."Department Code";
            Resolution."Department Name" := EmploymentContext."Department Name";
            Resolution."Unit No." := EmploymentContext."Unit No.";
            Resolution."Unit Name" := EmploymentContext."Unit Name";
            Resolution."Position Code" := EmploymentContext."Position Code";
            Resolution."Position Name" := EmploymentContext."Position Name";
        end;

        Resolution.Insert();
        exit(ResolutionStatus);
    end;

    local procedure FindLastLedgerEntryOnDate(StaffEmployeeNo: Code[20]; ContextDate: Date; var EmployeeLedgerEntry: Record "IWSP Employee Ledger Entry2"): Boolean
    begin
        EmployeeLedgerEntry.Reset();
        EmployeeLedgerEntry.SetCurrentKey("Staff Employee No.", "Posting Date");
        EmployeeLedgerEntry.SetRange("Staff Employee No.", StaffEmployeeNo);
        EmployeeLedgerEntry.SetRange(Canceled, false);
        EmployeeLedgerEntry.SetFilter("Posting Date", '..%1', ContextDate);

        // IW-confirmed semantics: Resignation is not a state-bearing employment event.
        // It is a technical closing entry created as part of a transfer and must be
        // excluded from temporal resolution. This deliberately avoids relying on
        // Entry No. ordering between same-day Resignation and Assignment entries.
        EmployeeLedgerEntry.SetFilter(
            "Entry Type",
            '<>%1',
            EmployeeLedgerEntry."Entry Type"::Resignation);

        exit(EmployeeLedgerEntry.FindLast());
    end;

    local procedure IsActiveContextEntry(EmployeeLedgerEntry: Record "IWSP Employee Ledger Entry2"): Boolean
    begin
        case EmployeeLedgerEntry."Entry Type" of
            EmployeeLedgerEntry."Entry Type"::Employment,
            EmployeeLedgerEntry."Entry Type"::Assignment,
            EmployeeLedgerEntry."Entry Type"::"App. Parametres Change":
                exit(true);

            EmployeeLedgerEntry."Entry Type"::Termination:
                exit(false);

            EmployeeLedgerEntry."Entry Type"::Resignation:
                Error(
                    'IW Resignation entry %1 reached state resolution although Resignation must be excluded from temporal candidates.',
                    EmployeeLedgerEntry."Entry No.");
        end;

        Error(
            'Unsupported IW employee ledger entry type %1 in entry %2.',
            Format(EmployeeLedgerEntry."Entry Type"),
            EmployeeLedgerEntry."Entry No.");
    end;

    local procedure FillFromLedgerEntry(var EmploymentContext: Record "SI Employment Context"; EmployeeLedgerEntry: Record "IWSP Employee Ledger Entry2")
    begin
        EmploymentContext."Ledger Entry No." := EmployeeLedgerEntry."Entry No.";
        EmploymentContext."Context Posting Date" := EmployeeLedgerEntry."Posting Date";
        EmploymentContext."Context Ending Date" := EmployeeLedgerEntry."Ending Date";
        EmploymentContext."Department Code" := EmployeeLedgerEntry."Department Code";
        EmploymentContext."Unit No." := EmployeeLedgerEntry."Unit No.";
        EmploymentContext."Position Code" := EmployeeLedgerEntry."Position Code";
        EmploymentContext."Ledger Entry Type" := CopyStr(Format(EmployeeLedgerEntry."Entry Type"), 1, MaxStrLen(EmploymentContext."Ledger Entry Type"));
    end;

    local procedure FillNames(var EmploymentContext: Record "SI Employment Context"; var ManningUnit: Record "IWSP Manning Table"; var Position: Record "IWSP Position"; var Department: Record "IWSP HR Department")
    begin
        Clear(EmploymentContext."Department Name");
        Clear(EmploymentContext."Unit Name");
        Clear(EmploymentContext."Position Name");

        if (EmploymentContext."Department Code" <> '') and Department.Get(EmploymentContext."Department Code") then
            EmploymentContext."Department Name" := Department.Name;

        if (EmploymentContext."Unit No." <> '') and ManningUnit.Get(EmploymentContext."Unit No.") then begin
            EmploymentContext."Unit Name" := ManningUnit.Name;
            if EmploymentContext."Position Code" = '' then
                EmploymentContext."Position Code" := ManningUnit."Position Code";
        end;

        if (EmploymentContext."Position Code" <> '') and Position.Get(EmploymentContext."Position Code") then
            EmploymentContext."Position Name" := Position.Name;
    end;
}
