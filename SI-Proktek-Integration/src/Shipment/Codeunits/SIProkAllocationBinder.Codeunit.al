codeunit 57196 "SI Prok Allocation Binder"
{
    // SH-03.2. Only bind by the exact three-part allocation key.
    // No heuristic matching by site, customer, item or date.
    procedure Bind(var Shipment: Record "SI Prok Shipment")
    var
        ProdRequest: Record "SI Concrete Prod Request";
        Allocation: Record "SI Supply Allocation";
    begin
        if Shipment."Prod. Request Entry No." = 0 then begin
            Shipment."Allocation Binding Status" := 'NO_REQUEST';
            exit;
        end;
        if not ProdRequest.Get(Shipment."Prod. Request Entry No.") then begin
            Shipment."Allocation Binding Status" := 'REQUEST_NOT_FOUND';
            exit;
        end;
        if (ProdRequest."Supply Decision No." = '') or
           (ProdRequest."Supply Decision Line No." = 0) or
           (ProdRequest."Supply Allocation Line No." = 0) then begin
            Shipment."Allocation Binding Status" := 'NO_ALLOCATION_KEY';
            exit;
        end;
        if not Allocation.Get(
            ProdRequest."Supply Decision No.",
            ProdRequest."Supply Decision Line No.",
            ProdRequest."Supply Allocation Line No.") then begin
            Shipment."Allocation Binding Status" := 'ALLOCATION_NOT_FOUND';
            exit;
        end;

        // Execution System ID is an additional integrity check, if present.
        if not IsNullGuid(Allocation."Execution System ID") then
            if Allocation."Execution System ID" <> ProdRequest.SystemId then begin
                Shipment."Allocation Binding Status" := 'EXECUTION_MISMATCH';
                exit;
            end;

        Shipment."Supply Decision No." := Allocation."Decision No.";
        Shipment."Supply Decision Line No." := Allocation."Decision Line No.";
        Shipment."Supply Allocation Line No." := Allocation."Line No.";
        Shipment."Supply Allocation System ID" := Allocation.SystemId;
        Shipment."Allocation Binding Status" := 'BOUND';
    end;

    procedure BindExistingOpen(ShipmentEntryNo: Integer)
    var
        Shipment: Record "SI Prok Shipment";
    begin
        if not Shipment.Get(ShipmentEntryNo) then
            exit;
        if Shipment.Status <> Shipment.Status::Open then
            exit;
        // Never overwrite a previously bound source.
        if not IsNullGuid(Shipment."Supply Allocation System ID") then
            exit;
        Bind(Shipment);
        Shipment.Modify(true);
    end;

    local procedure IsNullGuid(Value: Guid): Boolean
    begin
        exit(Value = '00000000-0000-0000-0000-000000000000');
    end;
}
