codeunit 51000 "SI IW Workforce Provider"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SI Workforce Mgt.", 'OnResolveEmploymentContexts', '', false, false)]
    local procedure HandleResolveContexts(EmployeeNo: Code[20]; ContextDate: Date; var EmploymentContext: Record "SI Employment Context" temporary; var ProviderCount: Integer)
    begin
        ProviderCount += 1;
        ResolveEmploymentContexts(EmployeeNo, ContextDate, EmploymentContext);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SI Workforce Mgt.", 'OnResolveEmployment', '', false, false)]
    local procedure HandleResolveEmployment(EmployeeNo: Code[20]; ContextDate: Date; var Resolution: Record "SI Employment Resolution" temporary; var Status: Enum "SI Employment Resolve Status"; var ProviderCount: Integer)
    begin
        ProviderCount += 1;
        Status := ResolveEmployment(EmployeeNo, ContextDate, Resolution);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SI Workforce Mgt.", 'OnResolveCapability', '', false, false)]
    local procedure HandleResolveCapability(EmployeeNo: Code[20]; ContextDate: Date; CapabilityCode: Code[20]; var Status: Enum "SI Capability Resolve Status"; var ProviderCount: Integer)
    begin
        ProviderCount += 1;
        Status := ResolveCapability(EmployeeNo, ContextDate, CapabilityCode);
    end;

    procedure ResolveEmploymentContexts(EmployeeNo: Code[20]; ContextDate: Date; var EmploymentContext: Record "SI Employment Context" temporary)
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

        if not Employee.Get(EmployeeNo) then
            Error(EmployeeNotFoundErr, EmployeeNo);

        StaffEmployee.SetRange("Person No.", EmployeeNo);
        if not StaffEmployee.FindSet() then
            exit;

        repeat
            if FindLastLedgerEntryOnDate(StaffEmployee."No.", ContextDate, EmployeeLedgerEntry) then
                if IsActiveContextEntry(EmployeeLedgerEntry) then begin
                    NextEntryNo += 1;
                    EmploymentContext.Init();
                    EmploymentContext."Entry No." := NextEntryNo;
                    EmploymentContext."Employee No." := StaffEmployee."Person No.";
                    EmploymentContext."Employee Name" := CopyStr(Employee.FullName(), 1, MaxStrLen(EmploymentContext."Employee Name"));
                    EmploymentContext."Employment Context ID" := StaffEmployee."No.";
                    EmploymentContext."Employment Type" := CopyStr(Format(EmployeeLedgerEntry."Employment Type"), 1, MaxStrLen(EmploymentContext."Employment Type"));
                    EmploymentContext."Context Date" := ContextDate;

                    FillFromLedgerEntry(EmploymentContext, EmployeeLedgerEntry);
                    FillNames(EmploymentContext, ManningUnit, Position, Department);
                    EmploymentContext.Insert();
                end;
        until StaffEmployee.Next() = 0;
    end;

    procedure ResolveEmployment(EmployeeNo: Code[20]; ContextDate: Date; var Resolution: Record "SI Employment Resolution" temporary): Enum "SI Employment Resolve Status"
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

    procedure ResolveCapability(EmployeeNo: Code[20]; ContextDate: Date; CapabilityCode: Code[20]): Enum "SI Capability Resolve Status"
    var
        Resolution: Record "SI Employment Resolution" temporary;
        PositionCapMap: Record "SI IW Position Cap. Map";
        EmploymentStatus: Enum "SI Employment Resolve Status";
        CapabilityStatus: Enum "SI Capability Resolve Status";
    begin
        EmploymentStatus := ResolveEmployment(EmployeeNo, ContextDate, Resolution);

        case EmploymentStatus of
            EmploymentStatus::"Not Employed":
                exit(CapabilityStatus::"Not Employed");
            EmploymentStatus::Ambiguous:
                exit(CapabilityStatus::"Ambiguous Employment");
            EmploymentStatus::Resolved:
                begin
                    Resolution.FindFirst();
                    PositionCapMap.SetRange("IW Position Code", Resolution."Position Code");
                    PositionCapMap.SetRange("Capability Code", CapabilityCode);
                    PositionCapMap.SetRange(Active, true);
                    if PositionCapMap.FindFirst() then
                        exit(CapabilityStatus::Granted);

                    exit(CapabilityStatus::"Not Granted");
                end;
        end;
    end;

    local procedure FindLastLedgerEntryOnDate(StaffEmployeeNo: Code[20]; ContextDate: Date; var EmployeeLedgerEntry: Record "IWSP Employee Ledger Entry2"): Boolean
    var
        LatestPostingDate: Date;
    begin
        EmployeeLedgerEntry.Reset();
        EmployeeLedgerEntry.SetCurrentKey("Staff Employee No.", "Posting Date");
        EmployeeLedgerEntry.SetRange("Staff Employee No.", StaffEmployeeNo);
        EmployeeLedgerEntry.SetRange(Canceled, false);
        EmployeeLedgerEntry.SetFilter("Posting Date", '..%1', ContextDate);

        if not EmployeeLedgerEntry.FindLast() then
            exit(false);

        LatestPostingDate := EmployeeLedgerEntry."Posting Date";

        EmployeeLedgerEntry.Reset();
        EmployeeLedgerEntry.SetCurrentKey("Entry No.");
        EmployeeLedgerEntry.SetRange("Staff Employee No.", StaffEmployeeNo);
        EmployeeLedgerEntry.SetRange(Canceled, false);
        EmployeeLedgerEntry.SetRange("Posting Date", LatestPostingDate);

        exit(EmployeeLedgerEntry.FindLast());
    end;

    local procedure IsActiveContextEntry(EmployeeLedgerEntry: Record "IWSP Employee Ledger Entry2"): Boolean
    begin
        case EmployeeLedgerEntry."Entry Type" of
            EmployeeLedgerEntry."Entry Type"::Employment,
            EmployeeLedgerEntry."Entry Type"::Assignment,
            EmployeeLedgerEntry."Entry Type"::"App. Parametres Change":
                exit(true);
            EmployeeLedgerEntry."Entry Type"::Resignation,
            EmployeeLedgerEntry."Entry Type"::Termination:
                exit(false);
        end;

        Error(UnsupportedEntryTypeErr, Format(EmployeeLedgerEntry."Entry Type"), EmployeeLedgerEntry."Entry No.");
    end;

    local procedure FillFromLedgerEntry(var EmploymentContext: Record "SI Employment Context" temporary; EmployeeLedgerEntry: Record "IWSP Employee Ledger Entry2")
    begin
        EmploymentContext."Department Code" := EmployeeLedgerEntry."Department Code";
        EmploymentContext."Unit No." := EmployeeLedgerEntry."Unit No.";
        EmploymentContext."Position Code" := EmployeeLedgerEntry."Position Code";
    end;

    local procedure FillNames(var EmploymentContext: Record "SI Employment Context" temporary; var ManningUnit: Record "IWSP Manning Table"; var Position: Record "IWSP Position"; var Department: Record "IWSP HR Department")
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

    var
        EmployeeNotFoundErr: Label 'Employee %1 does not exist.', Comment = '%1 = Employee No.';
        UnsupportedEntryTypeErr: Label 'Unsupported IW employee ledger entry type %1 in entry %2.', Comment = '%1 = Entry Type, %2 = Entry No.';
}
