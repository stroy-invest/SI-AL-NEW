codeunit 60000 "SI Internal Customer Mgt."
{
    Permissions =
        tabledata Customer = rim,
        tabledata Job = rm;

    procedure EnsureInternalSICustomer(var Project: Record Job; var InternalCustomer: Record Customer)
    begin
        Project.TestField("No.");
        Clear(InternalCustomer);

        if FindInternalSICustomer(Project, InternalCustomer) then begin
            EnsureLinks(Project, InternalCustomer);
            SyncInternalSICustomer(Project, InternalCustomer);
            exit;
        end;

        CreateInternalSICustomer(Project, InternalCustomer);
        EnsureLinks(Project, InternalCustomer);
    end;

    procedure FindInternalSICustomer(Project: Record Job; var InternalCustomer: Record Customer): Boolean
    begin
        Clear(InternalCustomer);

        // 1. Prefer the direct Project -> Customer link when it is valid.
        if Project."SI Internal Customer No." <> '' then
            if InternalCustomer.Get(Project."SI Internal Customer No.") then begin
                ValidateInternalCustomerType(InternalCustomer);

                if (InternalCustomer."SI Project No." <> '') and
                   (InternalCustomer."SI Project No." <> Project."No.")
                then
                    Error(
                        'Внутрішній SI-клієнт %1 уже пов''язаний з іншим проєктом %2.',
                        InternalCustomer."No.", InternalCustomer."SI Project No.");

                exit(true);
            end;

        // 2. Compatibility fallback for dependent apps compiled against the legacy field.
        if Project."SI Project Customer No." <> '' then
            if InternalCustomer.Get(Project."SI Project Customer No.") then begin
                ValidateInternalCustomerType(InternalCustomer);

                if (InternalCustomer."SI Project No." <> '') and
                   (InternalCustomer."SI Project No." <> Project."No.")
                then
                    Error(
                        'Внутрішній SI-клієнт %1 уже пов''язаний з іншим проєктом %2.',
                        InternalCustomer."No.", InternalCustomer."SI Project No.");

                exit(true);
            end;

        // 3. Recover by reverse identity if both direct links are missing/broken.
        InternalCustomer.Reset();
        InternalCustomer.SetRange("SI Customer Type", InternalCustomer."SI Customer Type"::"Internal Project");
        InternalCustomer.SetRange("SI Project No.", Project."No.");
        exit(InternalCustomer.FindFirst());
    end;

    procedure SyncInternalSICustomer(Project: Record Job; var InternalCustomer: Record Customer)
    var
        ExpectedName: Text[100];
        Changed: Boolean;
    begin
        Project.TestField("No.");
        InternalCustomer.TestField("No.");
        ValidateInternalCustomerType(InternalCustomer);

        ExpectedName := BuildInternalCustomerName(Project);
        if InternalCustomer.Name <> ExpectedName then begin
            InternalCustomer.Validate(Name, ExpectedName);
            Changed := true;
        end;

        if InternalCustomer."SI Project No." <> Project."No." then begin
            InternalCustomer.Validate("SI Project No.", Project."No.");
            Changed := true;
        end;

        if Changed then
            InternalCustomer.Modify(true);
    end;

    procedure RepairInternalSICustomer(var Project: Record Job; var InternalCustomer: Record Customer)
    begin
        Project.TestField("No.");

        if FindInternalSICustomer(Project, InternalCustomer) then begin
            EnsureLinks(Project, InternalCustomer);
            SyncInternalSICustomer(Project, InternalCustomer);
            exit;
        end;

        CreateInternalSICustomer(Project, InternalCustomer);
        EnsureLinks(Project, InternalCustomer);
    end;

    procedure ValidateInternalSICustomer(Project: Record Job; var InternalCustomer: Record Customer)
    begin
        Project.TestField("No.");

        if Project."SI Internal Customer No." = '' then
            Error('Для будівельного проєкту %1 не створено внутрішнього SI-клієнта.', Project."No.");

        if not InternalCustomer.Get(Project."SI Internal Customer No.") then
            Error(
                'Для будівельного проєкту %1 вказано внутрішнього SI-клієнта %2, але такого Customer не існує.',
                Project."No.", Project."SI Internal Customer No.");

        ValidateInternalCustomerType(InternalCustomer);

        if InternalCustomer."SI Project No." <> Project."No." then
            Error(
                'Порушено зв''язок 1:1: внутрішній SI-клієнт %1 посилається на проєкт %2 замість %3.',
                InternalCustomer."No.", InternalCustomer."SI Project No.", Project."No.");

        CheckNoOtherInternalCustomer(Project, InternalCustomer);
    end;

    procedure GetProjectionState(Project: Record Job): Text[50]
    var
        InternalCustomer: Record Customer;
    begin
        if Project."SI Internal Customer No." = '' then begin
            if FindByReverseProjectNo(Project."No.", InternalCustomer) then
                exit('Потрібне відновлення зв''язку');
            exit('Не створено');
        end;

        if not InternalCustomer.Get(Project."SI Internal Customer No.") then
            exit('Пошкоджено зв''язок');

        if InternalCustomer."SI Customer Type" <> InternalCustomer."SI Customer Type"::"Internal Project" then
            exit('Некоректний тип Customer');

        if InternalCustomer."SI Project No." <> Project."No." then
            exit('Порушено зв''язок 1:1');

        if InternalCustomer.Name <> BuildInternalCustomerName(Project) then
            exit('Потрібна синхронізація');

        exit('Синхронізовано');
    end;

    local procedure CreateInternalSICustomer(Project: Record Job; var InternalCustomer: Record Customer)
    begin
        InternalCustomer.Init();
        InternalCustomer.Insert(true);
        InternalCustomer.Validate(Name, BuildInternalCustomerName(Project));
        InternalCustomer."SI Customer Type" := InternalCustomer."SI Customer Type"::"Internal Project";
        InternalCustomer.Validate("SI Project No.", Project."No.");
        InternalCustomer.Modify(true);
    end;

    local procedure EnsureLinks(var Project: Record Job; var InternalCustomer: Record Customer)
    var
        Changed: Boolean;
    begin
        ValidateInternalCustomerType(InternalCustomer);

        if InternalCustomer."SI Project No." <> Project."No." then begin
            InternalCustomer.Validate("SI Project No.", Project."No.");
            InternalCustomer.Modify(true);
        end;

        if Project."SI Internal Customer No." <> InternalCustomer."No." then begin
            Project."SI Internal Customer No." := InternalCustomer."No.";
            Changed := true;
        end;

        // Temporary compatibility bridge for already published dependent extensions.
        if Project."SI Project Customer No." <> InternalCustomer."No." then begin
            Project."SI Project Customer No." := InternalCustomer."No.";
            Changed := true;
        end;

        if Changed then
            Project.Modify(true);
    end;

    local procedure ValidateInternalCustomerType(InternalCustomer: Record Customer)
    begin
        if InternalCustomer."SI Customer Type" <> InternalCustomer."SI Customer Type"::"Internal Project" then
            Error(
                'Customer %1 не є внутрішнім SI-клієнтом будівельного проєкту.',
                InternalCustomer."No.");
    end;

    local procedure CheckNoOtherInternalCustomer(Project: Record Job; InternalCustomer: Record Customer)
    var
        OtherCustomer: Record Customer;
    begin
        OtherCustomer.SetRange("SI Customer Type", OtherCustomer."SI Customer Type"::"Internal Project");
        OtherCustomer.SetRange("SI Project No.", Project."No.");
        OtherCustomer.SetFilter("No.", '<>%1', InternalCustomer."No.");
        if OtherCustomer.FindFirst() then
            Error(
                'Порушено зв''язок 1:1: проєкт %1 також пов''язаний з внутрішнім SI-клієнтом %2.',
                Project."No.", OtherCustomer."No.");
    end;

    local procedure FindByReverseProjectNo(ProjectNo: Code[20]; var InternalCustomer: Record Customer): Boolean
    begin
        InternalCustomer.Reset();
        InternalCustomer.SetRange("SI Customer Type", InternalCustomer."SI Customer Type"::"Internal Project");
        InternalCustomer.SetRange("SI Project No.", ProjectNo);
        exit(InternalCustomer.FindFirst());
    end;

    local procedure BuildInternalCustomerName(Project: Record Job): Text[100]
    var
        Result: Text;
    begin
        Result := StrSubstNo('PROJECT %1', Project."No.");
        if Project.Description <> '' then
            Result := Result + ' - ' + Project.Description;

        exit(CopyStr(Result, 1, 100));
    end;
}
