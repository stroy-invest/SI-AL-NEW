codeunit 61012 "SI Supply Recipe Mgt."
{
    procedure Resolve(var Allocation: Record "SI Supply Allocation")
    var
        Resolver: Codeunit "SI Recipe Resolver";
        TempResult: Record "SI Recipe Resolver Result" temporary;
        Outcome: Enum "SI Recipe Resolve Outcome";
        TargetDate: Date;
    begin
        ValidateProductionContext(Allocation);
        TargetDate := DT2Date(Allocation."Required on Site At");

        Outcome := Resolver.GetApplicableCandidates(
            Allocation."Item No.",
            Allocation."Variant Code",
            TargetDate,
            TempResult);

        case Outcome of
            Outcome::"No Recipe":
                begin
                    SetBlocked(Allocation, StrSubstNo(NoRecipeMsg, Allocation."Item No.", Allocation."Variant Code"));
                    Message(NoRecipeUserMsg);
                end;
            Outcome::"No Applicable Revision":
                begin
                    SetBlocked(Allocation, StrSubstNo(NoApplicableMsg, TargetDate));
                    Message(NoApplicableUserMsg, TargetDate);
                end;
            Outcome::"Single Candidate":
                ResolveSingleCandidate(Allocation, TempResult);
            Outcome::"Multiple Candidates":
                begin
                    HandleMultipleCandidates(Allocation, TempResult.Count(), TargetDate);

                    // HandleMultipleCandidates persists Ambiguous/validation state.
                    // A modal lookup cannot be opened while that write transaction is active.
                    // If an existing manual selection is still valid, keep it and do not reopen selection.
                    if (Allocation."Recipe Resolution Status" = Allocation."Recipe Resolution Status"::Resolved) and
                       (Allocation."Recipe Selection Mode" = Allocation."Recipe Selection Mode"::Manual)
                    then
                        exit;

                    Commit();
                    SelectManually(Allocation);
                end;
        end;
    end;

    procedure SelectManually(var Allocation: Record "SI Supply Allocation")
    var
        Resolver: Codeunit "SI Recipe Resolver";
        CandidatePage: Page "SI Recipe Candidates";
        TempCandidates: Record "SI Recipe Resolver Result" temporary;
        SelectedCandidate: Record "SI Recipe Resolver Result" temporary;
        ReasonDialog: Page "SI Recipe Sel. Reason Dialog";
        TargetDate: Date;
        CandidateCount: Integer;
    begin
        ValidateProductionContext(Allocation);
        TargetDate := DT2Date(Allocation."Required on Site At");
        Resolver.GetApplicableCandidates(Allocation."Item No.", Allocation."Variant Code", TargetDate, TempCandidates);
        CandidateCount := TempCandidates.Count();
        if CandidateCount = 0 then begin
            Resolve(Allocation);
            exit;
        end;

        CandidatePage.SetContext(Allocation."Item No.", Allocation."Variant Code", TargetDate);
        CandidatePage.LookupMode(true);
        if CandidatePage.RunModal() <> Action::LookupOK then
            exit;

        CandidatePage.GetRecord(SelectedCandidate);
        if SelectedCandidate."Recipe No." = '' then
            exit;

        ReasonDialog.SetReason(Allocation."Recipe Selection Reason");
        if ReasonDialog.RunModal() <> Action::OK then
            exit;

        SetSelection(
            Allocation,
            SelectedCandidate,
            Allocation."Recipe Selection Mode"::Manual,
            ReasonDialog.GetReason(),
            CandidateCount);
    end;

    procedure RevalidateForExecution(var Allocation: Record "SI Supply Allocation")
    var
        Resolver: Codeunit "SI Recipe Resolver";
        TempResult: Record "SI Recipe Resolver Result" temporary;
        Outcome: Enum "SI Recipe Resolve Outcome";
        TargetDate: Date;
    begin
        ValidateProductionContext(Allocation);
        TargetDate := DT2Date(Allocation."Required on Site At");

        if Allocation."Recipe Selection Mode" = Allocation."Recipe Selection Mode"::Manual then begin
            if ManualSelectionStillApplicable(Allocation, TargetDate, TempResult) then begin
                Allocation."Recipe Last Validated At" := CurrentDateTime();
                Allocation."Recipe Resolution Message" := '';
                Allocation.RefreshAllocationReadiness();
                Allocation.Modify(true);
                exit;
            end;

            SetRevalidationRequired(Allocation, ManualInvalidMsg);
            Commit();
            Error(ManualInvalidErr);
        end;

        Outcome := Resolver.GetApplicableCandidates(
            Allocation."Item No.",
            Allocation."Variant Code",
            TargetDate,
            TempResult);

        case Outcome of
            Outcome::"Single Candidate":
                begin
                    TempResult.FindFirst();
                    SetSelection(Allocation, TempResult, Allocation."Recipe Selection Mode"::Automatic, '', 1);
                end;
            Outcome::"No Recipe":
                begin
                    SetBlocked(Allocation, StrSubstNo(NoRecipeMsg, Allocation."Item No.", Allocation."Variant Code"));
                    Commit();
                    Error(NoRecipeExecErr);
                end;
            Outcome::"No Applicable Revision":
                begin
                    SetBlocked(Allocation, StrSubstNo(NoApplicableMsg, TargetDate));
                    Commit();
                    Error(NoApplicableExecErr, TargetDate);
                end;
            Outcome::"Multiple Candidates":
                begin
                    HandleMultipleCandidates(Allocation, TempResult.Count(), TargetDate);
                    Commit();
                    Error(AmbiguousExecErr, TempResult.Count());
                end;
        end;
    end;

    local procedure ResolveSingleCandidate(var Allocation: Record "SI Supply Allocation"; var TempResult: Record "SI Recipe Resolver Result" temporary)
    begin
        TempResult.FindFirst();

        if Allocation."Recipe Selection Mode" = Allocation."Recipe Selection Mode"::Manual then begin
            if (Allocation."Selected Recipe No." = TempResult."Recipe No.") and
               (Allocation."Selected Revision No." = TempResult."Revision No.")
            then begin
                Allocation."Recipe Resolution Status" := Allocation."Recipe Resolution Status"::Resolved;
                Allocation."Recipe Last Validated At" := CurrentDateTime();
                Allocation."Recipe Resolution Message" := '';
                Allocation.RefreshAllocationReadiness();
                Allocation.Modify(true);
                exit;
            end;

            SetRevalidationRequired(Allocation, ManualChangedMsg);
            exit;
        end;

        SetSelection(Allocation, TempResult, Allocation."Recipe Selection Mode"::Automatic, '', 1);
    end;

    local procedure HandleMultipleCandidates(var Allocation: Record "SI Supply Allocation"; CandidateCount: Integer; TargetDate: Date)
    var
        TempResult: Record "SI Recipe Resolver Result" temporary;
    begin
        if Allocation."Recipe Selection Mode" = Allocation."Recipe Selection Mode"::Manual then
            if ManualSelectionStillApplicable(Allocation, TargetDate, TempResult) then begin
                Allocation."Recipe Resolution Status" := Allocation."Recipe Resolution Status"::Resolved;
                Allocation."Recipe Candidate Count" := CandidateCount;
                Allocation."Recipe Last Validated At" := CurrentDateTime();
                Allocation."Recipe Resolution Message" := '';
                Allocation.RefreshAllocationReadiness();
                Allocation.Modify(true);
                exit;
            end;

        ClearAutomaticSelection(Allocation);
        Allocation."Recipe Resolution Status" := Allocation."Recipe Resolution Status"::Ambiguous;
        Allocation."Recipe Candidate Count" := CandidateCount;
        Allocation."Recipe Last Validated At" := CurrentDateTime();
        Allocation."Recipe Resolution Message" := CopyStr(StrSubstNo(MultipleMsg, CandidateCount, TargetDate), 1, MaxStrLen(Allocation."Recipe Resolution Message"));
        Allocation.RefreshAllocationReadiness();
                Allocation.Modify(true);
    end;

    local procedure ManualSelectionStillApplicable(var Allocation: Record "SI Supply Allocation"; TargetDate: Date; var TempResult: Record "SI Recipe Resolver Result" temporary): Boolean
    var
        Resolver: Codeunit "SI Recipe Resolver";
    begin
        Resolver.GetApplicableCandidates(
            Allocation."Item No.",
            Allocation."Variant Code",
            TargetDate,
            TempResult);

        TempResult.SetRange("Recipe No.", Allocation."Selected Recipe No.");
        TempResult.SetRange("Revision No.", Allocation."Selected Revision No.");
        exit(TempResult.FindFirst());
    end;

    local procedure SetSelection(var Allocation: Record "SI Supply Allocation"; Candidate: Record "SI Recipe Resolver Result" temporary; SelectionMode: Enum "SI Recipe Selection Mode"; SelectionReason: Text[250]; CandidateCount: Integer)
    begin
        Allocation."Selected Recipe No." := Candidate."Recipe No.";
        Allocation."Selected Revision No." := Candidate."Revision No.";
        Allocation."Recipe Selection Mode" := SelectionMode;
        Allocation."Recipe Selected By" := CopyStr(UserId(), 1, MaxStrLen(Allocation."Recipe Selected By"));
        Allocation."Recipe Selected At" := CurrentDateTime();
        Allocation."Recipe Selection Reason" := SelectionReason;
        Allocation."Recipe Resolution Status" := Allocation."Recipe Resolution Status"::Resolved;
        Allocation."Recipe Candidate Count" := CandidateCount;
        Allocation."Recipe Last Validated At" := CurrentDateTime();
        Allocation."Recipe Resolution Message" := '';
        Allocation.InvalidateMaterialRequirements();
        Allocation.RefreshAllocationReadiness();
                Allocation.Modify(true);
    end;

    local procedure SetBlocked(var Allocation: Record "SI Supply Allocation"; ResolutionMessage: Text)
    begin
        ClearAutomaticSelection(Allocation);
        Allocation."Recipe Resolution Status" := Allocation."Recipe Resolution Status"::Blocked;
        Allocation."Recipe Candidate Count" := 0;
        Allocation."Recipe Last Validated At" := CurrentDateTime();
        Allocation."Recipe Resolution Message" := CopyStr(ResolutionMessage, 1, MaxStrLen(Allocation."Recipe Resolution Message"));
        Allocation.InvalidateMaterialRequirements();
        Allocation.RefreshAllocationReadiness();
                Allocation.Modify(true);
    end;

    local procedure SetRevalidationRequired(var Allocation: Record "SI Supply Allocation"; ResolutionMessage: Text)
    begin
        Allocation."Recipe Resolution Status" := Allocation."Recipe Resolution Status"::"Revalidation Required";
        Allocation."Recipe Last Validated At" := CurrentDateTime();
        Allocation."Recipe Resolution Message" := CopyStr(ResolutionMessage, 1, MaxStrLen(Allocation."Recipe Resolution Message"));
        Allocation.InvalidateMaterialRequirements();
        Allocation.RefreshAllocationReadiness();
                Allocation.Modify(true);
    end;

    local procedure ClearAutomaticSelection(var Allocation: Record "SI Supply Allocation")
    begin
        if Allocation."Recipe Selection Mode" = Allocation."Recipe Selection Mode"::Manual then
            exit;

        Clear(Allocation."Selected Recipe No.");
        Clear(Allocation."Selected Revision No.");
        Clear(Allocation."Recipe Selection Mode");
        Clear(Allocation."Recipe Selected By");
        Clear(Allocation."Recipe Selected At");
        Clear(Allocation."Recipe Selection Reason");
    end;

    local procedure ValidateProductionContext(Allocation: Record "SI Supply Allocation")
    begin
        Allocation.TestField("Supply Method", Allocation."Supply Method"::Production);
        Allocation.TestField("Item No.");
        Allocation.TestField("Required on Site At");
        if not IsNullGuid(Allocation."Execution System ID") then
            Error(ExecutionExistsErr);
    end;

    var
        NoRecipeMsg: Label 'Для товару %1, варіанта %2 не знайдено активної логічної рецептури.';
        NoRecipeUserMsg: Label 'Для цього продукту ще не створено жодної активної рецептури.';
        NoApplicableUserMsg: Label 'Для цього продукту є рецептура, але на %1 немає жодної застосовної сертифікованої активної ревізії.';
        NoApplicableMsg: Label 'Для %1 не знайдено застосовної сертифікованої активної ревізії рецептури.';
        MultipleMsg: Label 'Для %2 знайдено %1 застосовних ревізій. Потрібен ручний вибір уповноваженої особи.';
        ManualChangedMsg: Label 'Раніше вибрана вручну рецептура більше не є єдиним поточним результатом. Потрібна повторна перевірка уповноваженою особою.';
        ManualInvalidMsg: Label 'Вибрана вручну ревізія рецептури більше не є допустимою на дату виконання.';
        ManualInvalidErr: Label 'Вибрана вручну ревізія рецептури більше не є допустимою. Потрібна повторна перевірка рецептури.';
        NoRecipeExecErr: Label 'Створення документа виконання заблоковано: не знайдено рецептури.';
        NoApplicableExecErr: Label 'Створення документа виконання заблоковано: на %1 немає застосовної ревізії рецептури.';
        AmbiguousExecErr: Label 'Створення документа виконання заблоковано: знайдено %1 допустимих ревізій. Виконайте ручний вибір рецептури.';
        ExecutionExistsErr: Label 'Рецептуру не можна перевизначати після створення документа виконання.';
}
