codeunit 57145 "SI Prok Shipment Mgt."
{
    // PF-03.1: one immutable MES Production UUID -> one simple shipment document.
    // A shipment is operational only: no standard Sales Shipment, inventory or G/L posting.
    procedure TryCreateForFact(FactEntryNo: Integer)
    var
        Fact: Record "SI Prok Production Fact";
        Shipment: Record "SI Prok Shipment";
        Request: Record "SI Concrete Prod Request";
        BOMVersion: Record "Production BOM Version";
        Mapping: Record "SI Prok Driver Mapping";
        Employee: Record Employee;
        Root: JsonObject;
        Transport: JsonObject;
        Driver: JsonObject;
        Token: JsonToken;
        DriverUuidText: Text;
        DriverCode: Code[20];
        DriverUuid: Guid;
        AllocationBinder: Codeunit "SI Prok Allocation Binder";
        Snapshot: Codeunit "SI Prok Shipment Snapshot";
    begin
        if not Fact.Get(FactEntryNo) then
            exit;
        if (Fact."BC Prod. Order No." = '') or
           (Fact."BC Prod. Order Status" <> Fact."BC Prod. Order Status"::Released) or
           not (Fact."BC Binding Status" in [Fact."BC Binding Status"::Bound, Fact."BC Binding Status"::Warning]) then
            exit;
        if IsNullGuid(Fact."Production UUID") then
            exit;
        Shipment.SetRange("Production UUID", Fact."Production UUID");
        if not Shipment.IsEmpty() then
            exit;

        Shipment.Init();
        Shipment."Production UUID" := Fact."Production UUID";
        Shipment."Production Fact Entry No." := Fact."Entry No.";
        Shipment."Prod. Request Entry No." := Fact."Prod. Request Entry No.";
        Shipment."BC Prod. Order No." := Fact."BC Prod. Order No.";
        Shipment."Item No." := Fact."Item No.";
        Shipment."Variant Code" := Fact."Variant Code";
        Shipment."Connection Code" := Fact."Connection Code";
        Shipment."Truck Plate" := Fact."Truck Plate";
        Shipment."Shipment Date/Time" := Fact."Production Date/Time";
        Shipment."Created At" := CurrentDateTime();
        if Request.Get(Fact."Prod. Request Entry No.") then
            Shipment."Source Order No." := Request."Source No.";
        Shipment."Recipe Name" := Fact."Formula Name";
        if (Fact."Production BOM No." <> '') and (Fact."Production BOM Version Code" <> '') then
            if BOMVersion.Get(Fact."Production BOM No.", Fact."Production BOM Version Code") then
                Shipment."Recipe Name" := CopyStr(BOMVersion."Version Code" + ' - ' + BOMVersion.Description, 1, MaxStrLen(Shipment."Recipe Name"));

        // Do not mislabel the MES reported quantity as confirmed production.
        Shipment."Quantity M3" := Fact."Produced Quantity M3";
        if Fact.Simulation and (Shipment."Quantity M3" <= 0) then begin
            Shipment."Quantity M3" := Fact."Reported Quantity M3";
            Shipment."Simulation Quantity" := true;
        end;

        if Root.ReadFrom(Fact.GetCanonicalJson()) then
            if Root.Get('transport', Token) and Token.IsObject() then begin
                Transport := Token.AsObject();
                if Transport.Get('driver', Token) and Token.IsObject() then begin
                    Driver := Token.AsObject();
                    if Driver.Get('name', Token) and Token.IsValue() then
                        Shipment."Driver Name" := CopyStr(Token.AsValue().AsText(), 1, MaxStrLen(Shipment."Driver Name"));
                    if Driver.Get('uuid', Token) and Token.IsValue() then begin
                        DriverUuidText := Token.AsValue().AsText();
                        if Evaluate(DriverUuid, DriverUuidText) and not IsNullGuid(DriverUuid) then begin
                            Shipment."Driver UUID" := DriverUuid;
                            Mapping.SetRange("Connection Code", Fact."Connection Code");
                            Mapping.SetRange("Driver UUID", DriverUuid);
                            if Mapping.FindFirst() then
                                DriverCode := Mapping."Employee No.";
                        end;
                    end;
                    // Optional direct ERP code if Proktek ever sends Description 1.
                    if (DriverCode = '') and Driver.Get('description1', Token) and Token.IsValue() then
                        DriverCode := CopyStr(Token.AsValue().AsText(), 1, MaxStrLen(DriverCode));
                end;
            end;
        if (DriverCode <> '') and Employee.Get(DriverCode) then begin
            Shipment."Employee No." := Employee."No.";
            Shipment."Driver Name" := CopyStr(Employee.FullName(), 1, MaxStrLen(Shipment."Driver Name"));
        end;
        AllocationBinder.Bind(Shipment);
        Snapshot.InitializeOpen(Shipment, false);
        Shipment.Insert(true);
    end;

    procedure CreateForReleasedOrder(OrderNo: Code[20])
    var
        Fact: Record "SI Prok Production Fact";
    begin
        Fact.SetRange("BC Prod. Order Status", Fact."BC Prod. Order Status"::Released);
        Fact.SetRange("BC Prod. Order No.", OrderNo);
        if Fact.FindSet() then
            repeat
                TryCreateForFact(Fact."Entry No.");
            until Fact.Next() = 0;
    end;

    local procedure IsNullGuid(Value: Guid): Boolean
    begin
        exit(Value = '00000000-0000-0000-0000-000000000000');
    end;
}
