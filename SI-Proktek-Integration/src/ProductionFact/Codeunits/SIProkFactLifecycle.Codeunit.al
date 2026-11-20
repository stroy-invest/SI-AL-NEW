codeunit 57233 "SI Prok Fact Lifecycle"
{
    // Canonical post-intake pipeline. No journals, printing, inventory or G/L.
    procedure AfterImported(FactEntryNo: Integer)
    var
        Fact: Record "SI Prok Production Fact";
        Binding: Codeunit "SI Prok Fact BC Binding Mgt.";
        ShipmentMgt: Codeunit "SI Prok Shipment Mgt.";
    begin
        Fact.Get(FactEntryNo);
        Binding.BindFact(Fact);
        ShipmentMgt.EnsureForFact(FactEntryNo);
    end;

    procedure AfterExisting(FactEntryNo: Integer)
    var
        ShipmentMgt: Codeunit "SI Prok Shipment Mgt.";
    begin
        // Idempotent backfill: never replace or reopen an existing Shipment.
        ShipmentMgt.EnsureForFact(FactEntryNo);
    end;
}
