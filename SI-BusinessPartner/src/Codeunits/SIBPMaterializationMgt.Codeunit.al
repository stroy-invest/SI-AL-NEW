codeunit 54070 "SI BP Materialization Mgt."
{
    procedure CreateRun(
        Role: Record "SI BP Role";
        var MatRun: Record "SI BP Materialization Run")
    begin
        ValidateCanCreateRun(Role);

        MatRun.Init();

        MatRun."Role Code" :=
            Role.Code;

        MatRun."Business Partner No." :=
            Role."Business Partner No.";

        MatRun."Role Type" :=
            Role."Role Type";

        MatRun.Status :=
            MatRun.Status::Pending;

        MatRun.Insert(true);

        CreateSteps(
            MatRun);
    end;

    procedure StartRun(
        var MatRun: Record "SI BP Materialization Run")
    begin
        MatRun.Get(
            MatRun."Entry No.");

        if not (
            MatRun.Status in
            [
                MatRun.Status::Pending,
                MatRun.Status::Failed
            ])
        then
            Error(
                'Запуск %1 не можна запустити зі стану %2.',
                MatRun."Entry No.",
                Format(MatRun.Status));

        MatRun.Status :=
            MatRun.Status::Running;

        MatRun."Error Message" :=
            '';

        if MatRun."Started At" = 0DT then
            MatRun."Started At" :=
                CurrentDateTime;

        MatRun.Modify(true);
    end;

    procedure StartStep(
        var MatRun: Record "SI BP Materialization Run";
        StepType: Enum "SI BP Mat. Step Type")
    var
        MatStep: Record "SI BP Materialization Step";
    begin
        MatStep.Get(
            MatRun."Entry No.",
            StepType);

        MatStep.Status :=
            MatStep.Status::Running;

        MatStep."Started At" :=
            CurrentDateTime;

        MatStep."Completed At" :=
            0DT;

        MatStep."Error Message" :=
            '';

        MatStep."Attempt Count" += 1;

        MatStep.Modify(true);

        MatRun."Current Step" :=
            StepType;

        MatRun.Modify(true);
    end;

    procedure CompleteStep(
        var MatRun: Record "SI BP Materialization Run";
        StepType: Enum "SI BP Mat. Step Type";
        Details: Text)
    var
        MatStep: Record "SI BP Materialization Step";
    begin
        MatStep.Get(
            MatRun."Entry No.",
            StepType);

        MatStep.Status :=
            MatStep.Status::Completed;

        MatStep."Completed At" :=
            CurrentDateTime;

        MatStep.Details :=
            CopyStr(
                Details,
                1,
                MaxStrLen(MatStep.Details));

        MatStep.Modify(true);

        MatRun."Last Successful Step" :=
            StepType;

        MatRun.Modify(true);
    end;

    procedure FailStep(
        var MatRun: Record "SI BP Materialization Run";
        StepType: Enum "SI BP Mat. Step Type";
        ErrorText: Text)
    var
        MatStep: Record "SI BP Materialization Step";
    begin
        MatStep.Get(
            MatRun."Entry No.",
            StepType);

        MatStep.Status :=
            MatStep.Status::Failed;

        MatStep."Error Message" :=
            CopyStr(
                ErrorText,
                1,
                MaxStrLen(MatStep."Error Message"));

        MatStep.Modify(true);

        MatRun.Status :=
            MatRun.Status::Failed;

        MatRun."Error Message" :=
            CopyStr(
                ErrorText,
                1,
                MaxStrLen(MatRun."Error Message"));

        MatRun.Modify(true);
    end;

    procedure CompleteRun(
        var MatRun: Record "SI BP Materialization Run")
    begin
        MatRun.Status :=
            MatRun.Status::Completed;

        MatRun."Completed At" :=
            CurrentDateTime;

        MatRun."Error Message" :=
            '';

        MatRun.Modify(true);
    end;

    procedure RequireManualIntervention(
        var MatRun: Record "SI BP Materialization Run";
        ErrorText: Text)
    begin
        MatRun.Status :=
            MatRun.Status::"Manual Intervention";

        MatRun."Error Message" :=
            CopyStr(
                ErrorText,
                1,
                MaxStrLen(MatRun."Error Message"));

        MatRun.Modify(true);
    end;

    procedure GetOpenRun(
        RoleCode: Code[30];
        var MatRun: Record "SI BP Materialization Run"): Boolean
    begin
        MatRun.Reset();

        MatRun.SetRange(
            "Role Code",
            RoleCode);

        MatRun.SetFilter(
            Status,
            '%1|%2|%3',
            MatRun.Status::Pending,
            MatRun.Status::Running,
            MatRun.Status::Failed);

        exit(
            MatRun.FindLast());
    end;

    procedure RunPreflight(
        var MatRun: Record "SI BP Materialization Run"): Boolean
    var
        Preflight: Codeunit "SI BP Mat. Preflight";
        StepType: Enum "SI BP Mat. Step Type";
        ErrorText: Text;
        Details: Text;
    begin
        MatRun.Get(
            MatRun."Entry No.");

        StartRun(
            MatRun);

        StepType :=
            StepType::Preflight;

        StartStep(
            MatRun,
            StepType);

        if Preflight.ValidateRun(
            MatRun,
            ErrorText,
            Details)
        then begin
            CompleteStep(
                MatRun,
                StepType,
                Details);

            exit(true);
        end;

        FailStep(
            MatRun,
            StepType,
            ErrorText);

        exit(false);
    end;

    local procedure ValidateCanCreateRun(
        Role: Record "SI BP Role")
    var
        ExistingRun: Record "SI BP Materialization Run";
        Projection: Record "SI BP ERP Projection";
    begin
        Role.TestField(Code);

        if Role.Status <> Role.Status::Active then
            Error(
                'Матеріалізацію можна запускати лише для активної ролі.');

        if not Projection.Get(Role.Code) then
            Error(
                'Для ролі %1 не створено ERP-проєкцію.',
                Role.Code);

        if Projection.Status <>
           Projection.Status::Ready
        then
            Error(
                'ERP-проєкція ролі %1 не готова до матеріалізації.',
                Role.Code);

        if GetOpenRun(
            Role.Code,
            ExistingRun)
        then
            Error(
                'Для ролі %1 вже існує незавершений запуск матеріалізації %2.',
                Role.Code,
                ExistingRun."Entry No.");
    end;

    local procedure CreateSteps(
        MatRun: Record "SI BP Materialization Run")
    begin
        CreateStep(
            MatRun,
            Enum::"SI BP Mat. Step Type"::Preflight);

        CreateStep(
            MatRun,
            Enum::"SI BP Mat. Step Type"::"Create ERP Entity");

        CreateStep(
            MatRun,
            Enum::"SI BP Mat. Step Type"::"Apply BP Data");

        CreateStep(
            MatRun,
            Enum::"SI BP Mat. Step Type"::"Create Bank Accounts");

        CreateStep(
            MatRun,
            Enum::"SI BP Mat. Step Type"::"Ensure Company Contact");

        CreateStep(
            MatRun,
            Enum::"SI BP Mat. Step Type"::"Link Customer");

        CreateStep(
            MatRun,
            Enum::"SI BP Mat. Step Type"::"Link Vendor");

        CreateStep(
            MatRun,
            Enum::"SI BP Mat. Step Type"::"Post Validate");

        CreateStep(
            MatRun,
            Enum::"SI BP Mat. Step Type"::"Finalize Projection");
    end;

    local procedure CreateStep(
        MatRun: Record "SI BP Materialization Run";
        StepType: Enum "SI BP Mat. Step Type")
    var
        MatStep: Record "SI BP Materialization Step";
    begin
        MatStep.Init();

        MatStep."Run Entry No." :=
            MatRun."Entry No.";

        MatStep."Step Type" :=
            StepType;

        MatStep.Status :=
            MatStep.Status::Pending;

        MatStep.Insert(true);
    end;
}