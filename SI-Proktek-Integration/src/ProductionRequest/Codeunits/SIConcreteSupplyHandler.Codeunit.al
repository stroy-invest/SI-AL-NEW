using STROYINVEST.ConcreteRecipeEngine;

codeunit 57070 "SI Concrete Supply Handler"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SI Supply Execution Mgt.", 'OnExecuteProductionAllocation', '', false, false)]
    local procedure OnExecuteProductionAllocation(Allocation: Record "SI Supply Allocation"; var ExecutionReference: Code[50]; var ExecutionSystemId: Guid; var Handled: Boolean)
    var
        ProdRequest: Record "SI Concrete Prod Request";
        DecisionHeader: Record "SI Supply Decision Header";
        DecisionLine: Record "SI Supply Decision Line";
        RequestHeader: Record "SI Supply Req Header";
        Project: Record Job;
        Recipe: Record "SI Concrete Recipe";
        FormulaProjector: Codeunit "SI Prok Formula Projector";
    begin
        if Handled then
            exit;

        if Allocation."Supply Method" <> Allocation."Supply Method"::Production then
            exit;

        ProdRequest.SetRange("Supply Decision No.", Allocation."Decision No.");
        ProdRequest.SetRange("Supply Decision Line No.", Allocation."Decision Line No.");
        ProdRequest.SetRange("Supply Allocation Line No.", Allocation."Line No.");
        if ProdRequest.FindFirst() then begin
            ExecutionReference := CopyStr(Format(ProdRequest."Entry No."), 1, MaxStrLen(ExecutionReference));
            ExecutionSystemId := ProdRequest.SystemId;
            Handled := true;
            exit;
        end;

        DecisionHeader.Get(Allocation."Decision No.");
        DecisionLine.Get(Allocation."Decision No.", Allocation."Decision Line No.");
        RequestHeader.Get(DecisionHeader."Request No.");
        DecisionHeader.TestField("Project No.");
        Project.Get(DecisionHeader."Project No.");
        Project.TestField("SI Internal Customer No.");

        ProdRequest.Init();
        ProdRequest."Source Type" := ProdRequest."Source Type"::"Supply Request";
        ProdRequest."Source No." := DecisionHeader."Request No.";
        ProdRequest."Source Line No." := DecisionLine."Request Line No.";
        ProdRequest."Customer No." := Project."SI Internal Customer No.";
        ProdRequest.Validate("Item No.", Allocation."Item No.");
        if Allocation."Variant Code" <> '' then
            ProdRequest.Validate("Variant Code", Allocation."Variant Code");
        ProdRequest.Validate(Quantity, Allocation.Quantity);
        if Allocation."Unit of Measure Code" <> '' then
            ProdRequest.Validate("Unit of Measure Code", Allocation."Unit of Measure Code");
        ProdRequest."Required Date/Time" := Allocation."Required on Site At";
        ProdRequest."Location Code" := Allocation."Target Location Code";
        ProdRequest.Description := CopyStr(Allocation.Description, 1, MaxStrLen(ProdRequest.Description));
        ProdRequest."Supply Decision No." := Allocation."Decision No.";
        ProdRequest."Supply Decision Line No." := Allocation."Decision Line No.";
        ProdRequest."Supply Allocation Line No." := Allocation."Line No.";
        ProdRequest."Request Type" := RequestHeader."Request Type";
        ProdRequest."Project No." := DecisionHeader."Project No.";
        ProdRequest."Project Location Code" := DecisionHeader."Project Location Code";
        ProdRequest."Integration Customer No." := Project."SI Internal Customer No.";
        ProdRequest."Source Location Code" := Allocation."Source Location Code";
        ProdRequest."Supply Method" := Allocation."Supply Method";
        ProdRequest."Recipe No." := Allocation."Selected Recipe No.";
        ProdRequest."Recipe Revision No." := Allocation."Selected Revision No.";
        Recipe.Get(Allocation."Selected Recipe No.");
        ProdRequest."Formula Code" := CopyStr(
            FormulaProjector.BuildRecipeFormulaIntegrationKey(Allocation."Selected Recipe No.", Allocation."Selected Revision No."),
            1, MaxStrLen(ProdRequest."Formula Code"));
        ProdRequest."Formula Description" := CopyStr(
            StrSubstNo('%1 v.%2', Recipe.Description, Allocation."Selected Revision No."),
            1, MaxStrLen(ProdRequest."Formula Description"));
        ProdRequest."Recipe Type" := ProdRequest."Recipe Type"::Base;
        ProdRequest.Insert(true);

        ExecutionReference := CopyStr(Format(ProdRequest."Entry No."), 1, MaxStrLen(ExecutionReference));
        ExecutionSystemId := ProdRequest.SystemId;
        Handled := true;
    end;
}
