namespace STROYINVEST.ConcreteRecipeEngine;

codeunit 62201 "SI Recipe Lifecycle Mgt."
{
    procedure CertifyRevision(var RecipeRevision: Record "SI Concrete Recipe Revision")
    var
        RecipeBOMProjection: Codeunit "SI Recipe BOM Projection";
    begin
        RecipeRevision.Get(RecipeRevision."Recipe No.", RecipeRevision."Revision No.");
        RecipeRevision.TestField(Status, RecipeRevision.Status::Draft);
        RecipeRevision.ValidateValidity();
        ValidateRecipeLines(RecipeRevision);

        RecipeRevision.MarkCertified();
        RecipeRevision.SetProjectionState(
            RecipeRevision."Projection Status"::Pending,
            '',
            '');
        OnAfterRecipeRevisionCertified(RecipeRevision);

        // Certification is the business action that makes the recipe authoritative
        // for production, therefore its standard BC Production BOM projection is
        // created/updated as part of the same lifecycle action.
        RecipeBOMProjection.ProjectRevision(RecipeRevision);
    end;

    procedure CloneRevision(SourceRevision: Record "SI Concrete Recipe Revision"; var NewRevision: Record "SI Concrete Recipe Revision")
    begin
        SourceRevision.Get(SourceRevision."Recipe No.", SourceRevision."Revision No.");

        EnsureNoExistingDraft(SourceRevision."Recipe No.");

        NewRevision.Init();
        NewRevision.Validate("Recipe No.", SourceRevision."Recipe No.");
        NewRevision."Source Revision No." := SourceRevision."Revision No.";
        NewRevision."Validity Type" := SourceRevision."Validity Type";
        NewRevision."Valid From" := 0D;
        NewRevision."Valid To" := 0D;
        NewRevision.Insert(true);

        if NewRevision."Validity Type" = NewRevision."Validity Type"::Permanent then begin
            NewRevision.SetPermanentEndDate();
            NewRevision.Modify(true);
        end;

        RemoveOrphanLinesForFreshRevision(NewRevision);
        CloneRecipeLines(SourceRevision, NewRevision);
        OnAfterRecipeRevisionCloned(SourceRevision, NewRevision);
    end;

    procedure DeactivateRevision(var RecipeRevision: Record "SI Concrete Recipe Revision")
    begin
        RecipeRevision.Get(RecipeRevision."Recipe No.", RecipeRevision."Revision No.");
        RecipeRevision.TestField(Status, RecipeRevision.Status::Certified);

        if RecipeRevision."Administrative Status" = RecipeRevision."Administrative Status"::Inactive then
            exit;

        RecipeRevision.Deactivate();
        LogAdministrativeAction(RecipeRevision, "SI Recipe Admin Action"::Deactivated);
        OnAfterRecipeRevisionDeactivated(RecipeRevision);
    end;

    procedure ActivateRevision(var RecipeRevision: Record "SI Concrete Recipe Revision")
    begin
        RecipeRevision.Get(RecipeRevision."Recipe No.", RecipeRevision."Revision No.");
        RecipeRevision.TestField(Status, RecipeRevision.Status::Certified);

        if RecipeRevision."Administrative Status" = RecipeRevision."Administrative Status"::Active then
            exit;

        RecipeRevision.Activate();
        LogAdministrativeAction(RecipeRevision, "SI Recipe Admin Action"::Activated);
        OnAfterRecipeRevisionActivated(RecipeRevision);
    end;

    local procedure LogAdministrativeAction(
        RecipeRevision: Record "SI Concrete Recipe Revision";
        AdminAction: Enum "SI Recipe Admin Action")
    var
        History: Record "SI Recipe Admin History";
    begin
        History.Init();
        History."Recipe No." := RecipeRevision."Recipe No.";
        History."Revision No." := RecipeRevision."Revision No.";
        History.Action := AdminAction;
        History."Changed At" := CurrentDateTime();
        History."Changed By" := UserSecurityId();
        History.Insert(true);
    end;

    local procedure ValidateRecipeLines(RecipeRevision: Record "SI Concrete Recipe Revision")
    var
        RecipeLine: Record "SI Concrete Recipe Line";
    begin
        RecipeLine.SetRange("Recipe No.", RecipeRevision."Recipe No.");
        RecipeLine.SetRange("Revision No.", RecipeRevision."Revision No.");

        if not RecipeLine.FindSet() then
            Error(RecipeMustHaveLinesErr, RecipeRevision."Recipe No.", RecipeRevision."Revision No.");

        repeat
            RecipeLine.TestField("Item No.");
            RecipeLine.TestField("Unit of Measure Code");
            if RecipeLine.Quantity <= 0 then
                Error(LineQuantityErr, RecipeLine."Line No.");
        until RecipeLine.Next() = 0;
    end;

    local procedure EnsureNoExistingDraft(RecipeNo: Code[50])
    var
        DraftRevision: Record "SI Concrete Recipe Revision";
    begin
        DraftRevision.SetRange("Recipe No.", RecipeNo);
        DraftRevision.SetRange(Status, DraftRevision.Status::Draft);
        if DraftRevision.FindFirst() then
            Error(DraftAlreadyExistsErr, RecipeNo, DraftRevision."Revision No.");
    end;

    local procedure RemoveOrphanLinesForFreshRevision(NewRevision: Record "SI Concrete Recipe Revision")
    var
        RecipeLine: Record "SI Concrete Recipe Line";
    begin
        RecipeLine.SetRange("Recipe No.", NewRevision."Recipe No.");
        RecipeLine.SetRange("Revision No.", NewRevision."Revision No.");
        if not RecipeLine.IsEmpty() then
            RecipeLine.DeleteAll(true);
    end;

    local procedure CloneRecipeLines(
        SourceRevision: Record "SI Concrete Recipe Revision";
        NewRevision: Record "SI Concrete Recipe Revision")
    var
        SourceLine: Record "SI Concrete Recipe Line";
        NewLine: Record "SI Concrete Recipe Line";
    begin
        SourceLine.SetRange("Recipe No.", SourceRevision."Recipe No.");
        SourceLine.SetRange("Revision No.", SourceRevision."Revision No.");
        if not SourceLine.FindSet() then
            exit;

        repeat
            NewLine.Init();
            NewLine."Recipe No." := NewRevision."Recipe No.";
            NewLine."Revision No." := NewRevision."Revision No.";
            NewLine."Line No." := SourceLine."Line No.";
            NewLine."Item No." := SourceLine."Item No.";
            NewLine."Variant Code" := SourceLine."Variant Code";
            NewLine.Description := SourceLine.Description;
            NewLine."Unit of Measure Code" := SourceLine."Unit of Measure Code";
            NewLine.Quantity := SourceLine.Quantity;
            NewLine.Insert(true);
        until SourceLine.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRecipeRevisionCertified(RecipeRevision: Record "SI Concrete Recipe Revision")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRecipeRevisionDeactivated(RecipeRevision: Record "SI Concrete Recipe Revision")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRecipeRevisionActivated(RecipeRevision: Record "SI Concrete Recipe Revision")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRecipeRevisionCloned(
        SourceRevision: Record "SI Concrete Recipe Revision";
        NewRevision: Record "SI Concrete Recipe Revision")
    begin
    end;

    var
        RecipeMustHaveLinesErr: Label 'Рецептуру %1, ревізію %2, не можна сертифікувати, оскільки вона не містить рядків.';
        LineQuantityErr: Label 'Рядок рецептури %1 повинен мати кількість більшу за нуль.';
        DraftAlreadyExistsErr: Label 'Рецептура %1 уже має чернеткову ревізію %2. Відкрийте наявну чернетку замість створення нової.';
}
