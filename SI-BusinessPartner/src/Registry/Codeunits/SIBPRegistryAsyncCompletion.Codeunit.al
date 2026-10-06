codeunit 54019 "SI BP Reg. Async Completion"
{
    Permissions =
        tabledata "SI Business Partner" = RIMD,
        tabledata "SI BP Address" = RIMD,
        tabledata "SI BP Contact Point" = RIMD;

    [EventSubscriber(ObjectType::Table, Database::"SI EDS Async Request", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifyAsyncRequest(
        var Rec: Record "SI EDS Async Request";
        var xRec: Record "SI EDS Async Request";
        RunTrigger: Boolean)
    var
        BusinessPartner: Record "SI Business Partner";
        RegistryResult: Record "SI Registry Result" temporary;
        RegistryOrchestrator: Codeunit "SI BP Registry Orchestrator";
        RegistryMaterializer: Codeunit "SI BP Registry Materializer";
    begin
        if Rec.IsTemporary then
            exit;
        if Rec.Status <> Rec.Status::Completed then
            exit;
        if xRec.Status = Rec.Status then
            exit;
        if Rec."Service Code" <> UARegistryServiceLbl then
            exit;
        if Rec."Operation Code" <> GetUSR_OperationLbl then
            exit;

        // BP-originated async requests use Business Partner No. as Business Key.
        // Requests created by the Foundation diagnostic page use the identifier
        // as Business Key and are intentionally ignored here.
        if not BusinessPartner.Get(CopyStr(Rec."Business Key", 1, MaxStrLen(BusinessPartner."No."))) then
            exit;

        RegistryOrchestrator.ResolveCompletedAsyncResponse(
            BusinessPartner,
            Rec,
            RegistryResult);

        if not RegistryResult.FindFirst() then
            Error(RegistryResultMissingErr);

        RegistryMaterializer.Materialize(BusinessPartner, RegistryResult);
    end;

    var
        UARegistryServiceLbl: Label 'UA-REGISTRY', Locked = true;
        GetUSR_OperationLbl: Label 'GET-USR', Locked = true;
        RegistryResultMissingErr: Label 'The completed EDS registry request did not produce a registry result.';
}
