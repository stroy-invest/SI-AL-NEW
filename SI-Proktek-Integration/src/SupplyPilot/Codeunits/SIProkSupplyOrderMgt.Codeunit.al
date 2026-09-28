using STROYINVEST.ConcreteRecipeEngine;

codeunit 57076 "SI Prok Supply Order Mgt."
{
    procedure SendAllocation(var Allocation: Record "SI Supply Allocation")
    var
        ProdRequest: Record "SI Concrete Prod Request";
        Connection: Record "SI Prok Connection";
        ExecutionMgt: Codeunit "SI Supply Execution Mgt.";
        ConnectionMgt: Codeunit "SI Prok Connection Mgt.";
        EnsureMgt: Codeunit "SI Prok Pilot Ensure";
        OrderSync: Codeunit "SI Prok Order Sync";
    begin
        Allocation.TestField("Supply Method", Allocation."Supply Method"::Production);
        Allocation.TestField("Selected Recipe No.");
        Allocation.TestField("Selected Revision No.");
        ValidateRecipeReadiness(Allocation);

        if IsNullGuid(Allocation."Execution System ID") then begin
            ExecutionMgt.ExecuteProduction(Allocation);
            Allocation.Get(Allocation."Decision No.", Allocation."Decision Line No.", Allocation."Line No.");
        end;

        if not ProdRequest.GetBySystemId(Allocation."Execution System ID") then
            Error('Документ виконання для розподілу %1/%2/%3 не знайдено.', Allocation."Decision No.", Allocation."Decision Line No.", Allocation."Line No.");

        PrepareProdRequest(Allocation, ProdRequest);

        if ProdRequest."Proktek Order ID" <> 0 then
            Error('Для цього розподілу вже підтверджено Proktek Order ID %1. Повторний CREATE заблоковано.', ProdRequest."Proktek Order ID");

        if not IsNullGuid(ProdRequest."Proktek Order UUID") then begin
            if OrderSync.ReconcilePendingOrder(ProdRequest) then
                exit;

            if not Confirm(
                'Попередній SAVE-ORDER повернув UUID %1, але повторний GET-ORDERS не знаходить цей Order у Proktek.\\Скинути непідтверджений локальний UUID і дозволити нову спробу CREATE?',
                false, ProdRequest."Proktek Order UUID")
            then
                exit;

            OrderSync.ResetUnconfirmedOrder(ProdRequest);
        end;

        ConnectionMgt.GetActive(Connection);
        if Connection.Environment = Connection.Environment::Production then
            if not Confirm(
                'Буде перевірено/створено Customer і Site та створено реальний Order у ПРОДУКТИВНОМУ Proktek для розподілу %1/%2/%3. Продовжити?',
                false, Allocation."Decision No.", Allocation."Decision Line No.", Allocation."Line No.")
            then
                exit;

        EnsureMgt.EnsureForOrder(ProdRequest);
        OrderSync.SendPreparedOrder(ProdRequest);
    end;

    procedure ShowOrderDiagnostic(Allocation: Record "SI Supply Allocation")
    var
        ProdRequest: Record "SI Concrete Prod Request";
        OrderSync: Codeunit "SI Prok Order Sync";
        DiagnosticPage: Page "SI Prok Order Diagnostic";
        BaselineRequestBody: Text;
        BaselineResponseText: Text;
        TargetRequestBody: Text;
        TargetResponseText: Text;
        AnalysisText: Text;
    begin
        if IsNullGuid(Allocation."Execution System ID") then
            Error('Для розподілу %1/%2/%3 ще не створено документ виконання.', Allocation."Decision No.", Allocation."Decision Line No.", Allocation."Line No.");

        if not ProdRequest.GetBySystemId(Allocation."Execution System ID") then
            Error('Документ виконання для розподілу %1/%2/%3 не знайдено.', Allocation."Decision No.", Allocation."Decision Line No.", Allocation."Line No.");

        OrderSync.GetOrderDiagnostic(ProdRequest, BaselineRequestBody, BaselineResponseText, TargetRequestBody, TargetResponseText, AnalysisText);

        // GET-ORDERS goes through EDS and writes execution-log/response-buffer records.
        // End that write transaction before opening the modal diagnostic page.
        Commit();

        DiagnosticPage.SetDiagnostic(BaselineRequestBody, BaselineResponseText, TargetRequestBody, TargetResponseText, AnalysisText);
        DiagnosticPage.RunModal();
    end;

    local procedure ValidateRecipeReadiness(Allocation: Record "SI Supply Allocation")
    var
        Readiness: Codeunit "SI Prok Prod Readiness";
    begin
        Readiness.ValidateRecipe(Allocation."Selected Recipe No.", Allocation."Selected Revision No.");
    end;

    local procedure PrepareProdRequest(Allocation: Record "SI Supply Allocation"; var ProdRequest: Record "SI Concrete Prod Request")
    var
        Recipe: Record "SI Concrete Recipe";
        FormulaProjector: Codeunit "SI Prok Formula Projector";
    begin
        Allocation.TestField("Selected Recipe No.");
        Allocation.TestField("Selected Revision No.");
        Recipe.Get(Allocation."Selected Recipe No.");

        ProdRequest."Recipe No." := Allocation."Selected Recipe No.";
        ProdRequest."Recipe Revision No." := Allocation."Selected Revision No.";
        ProdRequest."Formula Code" := CopyStr(
            FormulaProjector.BuildRecipeFormulaIntegrationKey(Allocation."Selected Recipe No.", Allocation."Selected Revision No."),
            1, MaxStrLen(ProdRequest."Formula Code"));
        ProdRequest."Formula Description" := CopyStr(
            StrSubstNo('%1 v.%2', Recipe.Description, Allocation."Selected Revision No."),
            1, MaxStrLen(ProdRequest."Formula Description"));
        ProdRequest."Recipe Type" := ProdRequest."Recipe Type"::Base;
        ProdRequest.Modify(false);
    end;

    local procedure IsNullGuid(Value: Guid): Boolean
    var
        EmptyGuid: Guid;
    begin
        exit(Value = EmptyGuid);
    end;
}
