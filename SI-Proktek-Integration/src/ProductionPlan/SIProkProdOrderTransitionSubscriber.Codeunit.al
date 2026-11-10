codeunit 57119 "SI Prok Prod Order Trans. Sub"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Prod. Order Status Management", 'OnAfterTransProdOrder', '', false, false)]
    local procedure OnAfterTransProdOrder(var FromProdOrder: Record "Production Order"; var ToProdOrder: Record "Production Order")
    var
        Plan: Record "SI Prok Production Plan";
        Sync: Codeunit "SI Prok Prod Order Status Sync";
        Issue: Text;
    begin
        // Only orders explicitly linked to SI plans; never touch unrelated BC orders.
        Plan.SetRange("BC Prod. Order Status", FromProdOrder.Status);
        Plan.SetRange("BC Prod. Order No.", FromProdOrder."No.");
        if not Plan.FindSet(true) then
            exit;
        repeat
            // Do not silently reassign if the standard order content does not match.
            if not Sync.ValidateIdentity(Plan, ToProdOrder, Issue) then
                Error('SI Proktek: зміна статусу замовлення %1 → %2 не підтверджена: %3', FromProdOrder."No.", ToProdOrder."No.", Issue);
            Sync.RegisterTransition(Plan."Prod. Request Entry No.", FromProdOrder.Status, FromProdOrder."No.", ToProdOrder.Status, ToProdOrder."No.", false);
            Sync.UpdatePlan(Plan, ToProdOrder);
        until Plan.Next() = 0;
        // Facts are reconciled through binding; no changes to immutable MES payload.
    end;
}
