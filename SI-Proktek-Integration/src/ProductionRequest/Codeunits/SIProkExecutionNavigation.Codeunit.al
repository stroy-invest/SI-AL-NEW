codeunit 57098 "SI Prok Exec. Navigation"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SI Supply Exec. Navigation", 'OnOpenExecutionDocument', '', false, false)]
    local procedure OpenProductionExecution(Allocation: Record "SI Supply Allocation"; var Handled: Boolean)
    var
        ProdRequest: Record "SI Concrete Prod Request";
    begin
        if Handled or (Allocation."Supply Method" <> Allocation."Supply Method"::Production) then
            exit;

        Handled := true;
        if not ProdRequest.GetBySystemId(Allocation."Execution System ID") then
            Error('Виробничу заявку за посиланням розподілу %1/%2/%3 не знайдено. Перевірте цілісність зв’язку.', Allocation."Decision No.", Allocation."Decision Line No.", Allocation."Line No.");

        Page.Run(Page::"SI Concrete Prod Req Card", ProdRequest);
    end;
}
