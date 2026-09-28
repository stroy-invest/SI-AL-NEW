namespace STROYINVEST.ConcreteRecipeEngine;

using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.ProductionBOM;

codeunit 62205 "SI Recipe Resolver"
{
    procedure GetApplicableCandidates(
        ItemNo: Code[20];
        VariantCode: Code[10];
        TargetDate: Date;
        var TempResult: Record "SI Recipe Resolver Result" temporary): Enum "SI Recipe Resolve Outcome"
    var
        Recipe: Record "SI Concrete Recipe";
        MatchType: Enum "SI Recipe Match Type";
    begin
        ValidateRequest(ItemNo, VariantCode, TargetDate);
        TempResult.Reset();
        TempResult.DeleteAll();

        if not ResolveLogicalRecipe(ItemNo, VariantCode, Recipe, MatchType) then
            exit("SI Recipe Resolve Outcome"::"No Recipe");

        CollectApplicableRevisions(Recipe, MatchType, TargetDate, TempResult);
        exit(GetOutcome(TempResult));
    end;

    procedure GetApplicableCandidatesForRecipe(
        RecipeNo: Code[50];
        TargetDate: Date;
        var TempResult: Record "SI Recipe Resolver Result" temporary): Enum "SI Recipe Resolve Outcome"
    var
        Recipe: Record "SI Concrete Recipe";
    begin
        if TargetDate = 0D then
            Error(TargetDateRequiredErr);

        TempResult.Reset();
        TempResult.DeleteAll();

        if not Recipe.Get(RecipeNo) then
            exit("SI Recipe Resolve Outcome"::"No Recipe");

        if not Recipe.Active then
            exit("SI Recipe Resolve Outcome"::"No Recipe");

        CollectApplicableRevisions(
            Recipe,
            "SI Recipe Match Type"::Exact,
            TargetDate,
            TempResult);

        exit(GetOutcome(TempResult));
    end;

    procedure ResolveLogicalRecipe(
        ItemNo: Code[20];
        VariantCode: Code[10];
        var Recipe: Record "SI Concrete Recipe";
        var MatchType: Enum "SI Recipe Match Type"): Boolean
    var
        ExactRecipeExists: Boolean;
    begin
        Recipe.Reset();
        Recipe.SetRange("Item No.", ItemNo);
        Recipe.SetRange("Variant Code", VariantCode);

        ExactRecipeExists := Recipe.FindFirst();
        if ExactRecipeExists then begin
            MatchType := MatchType::Exact;
            exit(Recipe.Active);
        end;

        if VariantCode = '' then
            exit(false);

        Recipe.Reset();
        Recipe.SetRange("Item No.", ItemNo);
        Recipe.SetRange("Variant Code", '');
        Recipe.SetRange("Recipe Type", Recipe."Recipe Type"::Base);
        if not Recipe.FindFirst() then
            exit(false);

        if not Recipe.Active then
            exit(false);

        MatchType := MatchType::"Base Fallback";
        exit(true);
    end;

    procedure CountApplicableCandidates(
        ItemNo: Code[20];
        VariantCode: Code[10];
        TargetDate: Date): Integer
    var
        TempResult: Record "SI Recipe Resolver Result" temporary;
    begin
        GetApplicableCandidates(ItemNo, VariantCode, TargetDate, TempResult);
        exit(TempResult.Count());
    end;

    local procedure ValidateRequest(ItemNo: Code[20]; VariantCode: Code[10]; TargetDate: Date)
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
    begin
        if ItemNo = '' then
            Error(ItemRequiredErr);

        if TargetDate = 0D then
            Error(TargetDateRequiredErr);

        Item.Get(ItemNo);

        if VariantCode <> '' then
            ItemVariant.Get(ItemNo, VariantCode);
    end;

    local procedure CollectApplicableRevisions(
        Recipe: Record "SI Concrete Recipe";
        MatchType: Enum "SI Recipe Match Type";
        TargetDate: Date;
        var TempResult: Record "SI Recipe Resolver Result" temporary)
    var
        RecipeRevision: Record "SI Concrete Recipe Revision";
        EntryNo: Integer;
    begin
        RecipeRevision.SetRange("Recipe No.", Recipe."Recipe No.");
        RecipeRevision.SetRange(Status, RecipeRevision.Status::Certified);
        RecipeRevision.SetRange(
            "Administrative Status",
            RecipeRevision."Administrative Status"::Active);
        RecipeRevision.SetFilter("Valid From", '<=%1', TargetDate);
        RecipeRevision.SetFilter("Valid To", '>=%1', TargetDate);
        RecipeRevision.SetCurrentKey("Recipe No.", "Valid From", "Valid To");

        if RecipeRevision.FindSet() then
            repeat
                if RecipeRevision.IsApplicable(TargetDate) then begin
                    EntryNo += 1;
                    AddCandidate(
                        EntryNo,
                        Recipe,
                        RecipeRevision,
                        MatchType,
                        TargetDate,
                        TempResult);
                end;
            until RecipeRevision.Next() = 0;
    end;

    local procedure AddCandidate(
        EntryNo: Integer;
        Recipe: Record "SI Concrete Recipe";
        RecipeRevision: Record "SI Concrete Recipe Revision";
        MatchType: Enum "SI Recipe Match Type";
        TargetDate: Date;
        var TempResult: Record "SI Recipe Resolver Result" temporary)
    begin
        TempResult.Init();
        TempResult."Entry No." := EntryNo;
        TempResult."Recipe No." := Recipe."Recipe No.";
        TempResult."Revision No." := RecipeRevision."Revision No.";
        TempResult."Recipe Description" := Recipe.Description;
        TempResult."Recipe Type" := Recipe."Recipe Type";
        TempResult."Item No." := Recipe."Item No.";
        TempResult."Variant Code" := Recipe."Variant Code";
        TempResult."Match Type" := MatchType;
        TempResult."Validity Type" := RecipeRevision."Validity Type";
        TempResult."Valid From" := RecipeRevision."Valid From";
        TempResult."Valid To" := RecipeRevision."Valid To";
        TempResult.Applicability := RecipeRevision.GetApplicability(TargetDate);
        TempResult."Projection Status" := RecipeRevision."Projection Status";
        TempResult."Production BOM No." := Recipe."Production BOM No.";
        TempResult."Production BOM Version Code" :=
            RecipeRevision."Production BOM Version Code";
        TempResult."Projection Ready" := IsProjectionReady(Recipe, RecipeRevision);
        TempResult."Target Date" := TargetDate;
        TempResult.Insert();
    end;

    local procedure IsProjectionReady(
        Recipe: Record "SI Concrete Recipe";
        RecipeRevision: Record "SI Concrete Recipe Revision"): Boolean
    var
        ProdBOMVersion: Record "Production BOM Version";
    begin
        if RecipeRevision."Projection Status" <> RecipeRevision."Projection Status"::Projected then
            exit(false);

        if (Recipe."Production BOM No." = '') or
           (RecipeRevision."Production BOM Version Code" = '')
        then
            exit(false);

        if not ProdBOMVersion.Get(
            Recipe."Production BOM No.",
            RecipeRevision."Production BOM Version Code")
        then
            exit(false);

        exit(ProdBOMVersion.Status = ProdBOMVersion.Status::Certified);
    end;

    local procedure GetOutcome(
        var TempResult: Record "SI Recipe Resolver Result" temporary): Enum "SI Recipe Resolve Outcome"
    var
        CandidateCount: Integer;
    begin
        CandidateCount := TempResult.Count();

        case CandidateCount of
            0:
                exit("SI Recipe Resolve Outcome"::"No Applicable Revision");
            1:
                exit("SI Recipe Resolve Outcome"::"Single Candidate");
            else
                exit("SI Recipe Resolve Outcome"::"Multiple Candidates");
        end;
    end;

    var
        ItemRequiredErr: Label 'Для визначення рецептури потрібно вказати код товару.';
        TargetDateRequiredErr: Label 'Для визначення рецептури потрібно вказати цільову дату.';
}
