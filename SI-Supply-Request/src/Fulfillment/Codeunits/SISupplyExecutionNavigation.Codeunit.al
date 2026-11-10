codeunit 61080 "SI Supply Exec. Navigation"
{
    procedure OpenExecution(Allocation: Record "SI Supply Allocation")
    var
        Handled: Boolean;
    begin
        if IsNullGuid(Allocation."Execution System ID") then
            Error('Для розподілу %1/%2/%3 документ виконання ще не створено.', Allocation."Decision No.", Allocation."Decision Line No.", Allocation."Line No.");

        OnOpenExecutionDocument(Allocation, Handled);
        if not Handled then
            Error('Для способу забезпечення %1 не налаштовано відкриття документа виконання.', Format(Allocation."Supply Method"));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOpenExecutionDocument(Allocation: Record "SI Supply Allocation"; var Handled: Boolean)
    begin
    end;
}
