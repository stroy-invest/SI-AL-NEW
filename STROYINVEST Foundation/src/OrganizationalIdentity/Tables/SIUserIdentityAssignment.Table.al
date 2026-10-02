table 50600 "SI User Identity Assignment"
{
    Caption = 'Призначення облікового запису';
    DataClassification = CustomerContent;
    DataPerCompany = true;
    LookupPageId = "SI User Identity Assignments";
    DrillDownPageId = "SI User Identity Assignments";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = '№ запису';
            AutoIncrement = true;
            DataClassification = SystemMetadata;
        }
        field(2; "User Security ID"; Guid)
        {
            Caption = 'Ідентифікатор користувача';
            DataClassification = EndUserPseudonymousIdentifiers;

            trigger OnValidate()
            var
                UserRecord: Record User;
            begin
                if IsNullGuid("User Security ID") then
                    exit;

                if not UserRecord.Get("User Security ID") then
                    Error(UserNotFoundErr, "User Security ID");
            end;
        }
        field(3; "Employee No."; Code[20])
        {
            Caption = '№ працівника';
            DataClassification = CustomerContent;
            TableRelation = Employee."No.";
        }
        field(4; "Purpose Code"; Code[50])
        {
            Caption = 'Функція облікового запису';
            DataClassification = CustomerContent;
            TableRelation = "SI User Identity Purpose".Code;
        }
        field(5; "Valid From"; Date)
        {
            Caption = 'Діє з';
            DataClassification = CustomerContent;
        }
        field(6; "Valid To"; Date)
        {
            Caption = 'Діє до';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(UserDate; "User Security ID", "Valid From", "Valid To") { }
        key(EmployeePurposeDate; "Employee No.", "Purpose Code", "Valid From", "Valid To") { }
    }

    trigger OnInsert()
    begin
        ValidateAssignment(true);
    end;

    trigger OnModify()
    begin
        ValidateAssignment("Purpose Code" <> xRec."Purpose Code");
    end;

    local procedure ValidateAssignment(RequireActivePurpose: Boolean)
    begin
        if IsNullGuid("User Security ID") then
            Error(UserRequiredErr);
        TestField("Employee No.");
        TestField("Purpose Code");
        TestField("Valid From");

        Validate("User Security ID");
        ValidatePeriod();
        ValidatePurpose(RequireActivePurpose);
        ValidateUserOwnership();
        ValidateFunctionalUniqueness();
        ValidateDuplicate();
    end;

    local procedure ValidatePeriod()
    begin
        if ("Valid To" <> 0D) and ("Valid To" < "Valid From") then
            Error(InvalidPeriodErr, "Valid From", "Valid To");
    end;

    local procedure ValidatePurpose(RequireActivePurpose: Boolean)
    var
        Purpose: Record "SI User Identity Purpose";
    begin
        if not Purpose.Get("Purpose Code") then
            Error(PurposeNotFoundErr, "Purpose Code");

        if RequireActivePurpose and (not Purpose.Active) then
            Error(InactivePurposeErr, "Purpose Code");
    end;

    local procedure ValidateUserOwnership()
    var
        OtherAssignment: Record "SI User Identity Assignment";
    begin
        OtherAssignment.SetRange("User Security ID", "User Security ID");
        if "Entry No." <> 0 then
            OtherAssignment.SetFilter("Entry No.", '<>%1', "Entry No.");

        if OtherAssignment.FindSet() then
            repeat
                if IntervalsOverlap(OtherAssignment."Valid From", OtherAssignment."Valid To", "Valid From", "Valid To") then
                    if OtherAssignment."Employee No." <> "Employee No." then
                        Error(
                            UserOverlapErr,
                            OtherAssignment."Entry No.",
                            OtherAssignment."Employee No.",
                            OtherAssignment."Valid From",
                            OtherAssignment."Valid To");
            until OtherAssignment.Next() = 0;
    end;

    local procedure ValidateFunctionalUniqueness()
    var
        OtherAssignment: Record "SI User Identity Assignment";
    begin
        OtherAssignment.SetRange("Employee No.", "Employee No.");
        OtherAssignment.SetRange("Purpose Code", "Purpose Code");
        if "Entry No." <> 0 then
            OtherAssignment.SetFilter("Entry No.", '<>%1', "Entry No.");

        if OtherAssignment.FindSet() then
            repeat
                if IntervalsOverlap(OtherAssignment."Valid From", OtherAssignment."Valid To", "Valid From", "Valid To") then
                    if OtherAssignment."User Security ID" <> "User Security ID" then
                        Error(
                            EmployeePurposeOverlapErr,
                            OtherAssignment."Entry No.",
                            OtherAssignment."Valid From",
                            OtherAssignment."Valid To");
            until OtherAssignment.Next() = 0;
    end;

    local procedure ValidateDuplicate()
    var
        OtherAssignment: Record "SI User Identity Assignment";
    begin
        OtherAssignment.SetRange("User Security ID", "User Security ID");
        OtherAssignment.SetRange("Employee No.", "Employee No.");
        OtherAssignment.SetRange("Purpose Code", "Purpose Code");
        if "Entry No." <> 0 then
            OtherAssignment.SetFilter("Entry No.", '<>%1', "Entry No.");

        if OtherAssignment.FindSet() then
            repeat
                if IntervalsOverlap(OtherAssignment."Valid From", OtherAssignment."Valid To", "Valid From", "Valid To") then
                    Error(
                        DuplicateAssignmentErr,
                        OtherAssignment."Entry No.",
                        OtherAssignment."Valid From",
                        OtherAssignment."Valid To");
            until OtherAssignment.Next() = 0;
    end;

    local procedure IntervalsOverlap(From1: Date; To1: Date; From2: Date; To2: Date): Boolean
    begin
        if (To1 <> 0D) and (From2 > To1) then
            exit(false);
        if (To2 <> 0D) and (From1 > To2) then
            exit(false);
        exit(true);
    end;

    var
        UserNotFoundErr: Label 'Користувача з ідентифікатором %1 не знайдено.', Comment = '%1 = User Security ID';
        UserRequiredErr: Label 'Необхідно вибрати користувача Business Central.';
        InvalidPeriodErr: Label 'Дата закінчення %2 не може бути раніше дати початку %1.', Comment = '%1 = Valid From, %2 = Valid To';
        PurposeNotFoundErr: Label 'Функцію облікового запису %1 не знайдено.', Comment = '%1 = Purpose Code';
        InactivePurposeErr: Label 'Функція облікового запису %1 неактивна. Її не можна використовувати для нового призначення.', Comment = '%1 = Purpose Code';
        UserOverlapErr: Label 'Обліковий запис уже призначений іншому працівнику в записі №%1 (працівник %2, період %3–%4). Періоди призначень одного облікового запису різним працівникам не можуть перетинатися.', Comment = '%1 = Entry No., %2 = Employee No., %3 = Valid From, %4 = Valid To';
        EmployeePurposeOverlapErr: Label 'Для цього працівника і функції вже існує інший обліковий запис у записі №%1 (період %2–%3). На одну дату для працівника і функції дозволено лише один обліковий запис.', Comment = '%1 = Entry No., %2 = Valid From, %3 = Valid To';
        DuplicateAssignmentErr: Label 'Таке призначення вже існує в записі №%1 (період %2–%3). Періоди однакових призначень не можуть перетинатися.', Comment = '%1 = Entry No., %2 = Valid From, %3 = Valid To';
}
