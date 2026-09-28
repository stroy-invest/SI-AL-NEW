codeunit 61011 "SI Supply Execution Mgt."
{
    procedure ExecuteProduction(var Allocation: Record "SI Supply Allocation")
    var
        RecipeMgt: Codeunit "SI Supply Recipe Mgt.";
        ExecutionReference: Code[50];
        ExecutionSystemId: Guid;
        Handled: Boolean;
    begin
        Allocation.TestField("Supply Method", Allocation."Supply Method"::Production);
        Allocation.TestField(Quantity);
        Allocation.TestField("Item No.");
        Allocation.TestField("Unit of Measure Code");
        Allocation.TestField("Required on Site At");
        Allocation.TestField("Source Location Code");
        Allocation.TestField("Target Location Code");

        RecipeMgt.RevalidateForExecution(Allocation);

        if not IsNullGuid(Allocation."Execution System ID") then
            exit;

        OnExecuteProductionAllocation(Allocation, ExecutionReference, ExecutionSystemId, Handled);
        if not Handled then
            Error('Не знайдено обробник виконання для способу забезпечення Виробництво.');
        if IsNullGuid(ExecutionSystemId) then
            Error('Обробник виробництва не повернув SystemId документа виконання.');

        Allocation.MarkExecution(ExecutionReference, ExecutionSystemId);
    end;

    procedure ExecutePurchase(Allocation: Record "SI Supply Allocation")
    var
        PlanningDemandMgt: Codeunit "SI Planning Demand Mgt.";
        PlanningRunner: Codeunit "SI Proc. Planning Runner";
        Run: Record "SI Proc. Plan Run";
        DemandLink: Record "SI Proc. Plan Demand Link";
        Snapshot: Record "SI Proc. Plan Snapshot";
        DemandEntryNo: Integer;
    begin
        Allocation.TestField("Supply Method", Allocation."Supply Method"::Purchase);

        // Idempotent handoff: the source key of SI Planning Demand is unique,
        // therefore a repeated action updates the same demand instead of creating a duplicate.
        DemandEntryNo := PlanningDemandMgt.EnsurePurchaseDemand(Allocation);

        // Procurement Planning is a calculated projection of all active demands.
        // Refresh it after the handoff so the user immediately sees the current purchasing result.
        PlanningRunner.RefreshPlan();

        Run.SetRange(Current, true);
        if not Run.FindLast() then
            Error(NoCurrentPlanErr);

        DemandLink.SetRange("Planning Demand Entry No.", DemandEntryNo);
        DemandLink.SetRange("Run No.", Run."Run No.");
        if not DemandLink.FindFirst() then begin
            OpenPlanningDemand(DemandEntryNo);
            Message(NoProcurementLineMsg);
            exit;
        end;

        if not Snapshot.Get(DemandLink."Run No.", DemandLink."Snapshot Line No.") then
            Error(PlanningLineNotFoundErr);

        Snapshot.SetRecFilter();
        Page.Run(Page::"SI Proc. Planning Board", Snapshot);
    end;

    local procedure OpenPlanningDemand(DemandEntryNo: Integer)
    var
        Demand: Record "SI Planning Demand";
    begin
        if not Demand.Get(DemandEntryNo) then
            exit;
        Demand.SetRecFilter();
        Page.Run(Page::"SI Planning Demands", Demand);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnExecuteProductionAllocation(Allocation: Record "SI Supply Allocation"; var ExecutionReference: Code[50]; var ExecutionSystemId: Guid; var Handled: Boolean)
    begin
    end;

    var
        NoCurrentPlanErr: Label 'Після оновлення не знайдено актуальний план закупівель.';
        PlanningLineNotFoundErr: Label 'Не знайдено рядок актуального плану закупівель, пов’язаний із переданою потребою.';
        NoProcurementLineMsg: Label 'Потребу передано в планування, але стандартний розрахунок Business Central не сформував для неї окремого рядка закупівлі. Відкрито вихідну планову потребу.';
}
