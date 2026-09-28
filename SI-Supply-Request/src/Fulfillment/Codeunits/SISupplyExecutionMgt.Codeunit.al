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

    [IntegrationEvent(false, false)]
    local procedure OnExecuteProductionAllocation(Allocation: Record "SI Supply Allocation"; var ExecutionReference: Code[50]; var ExecutionSystemId: Guid; var Handled: Boolean)
    begin
    end;
}
