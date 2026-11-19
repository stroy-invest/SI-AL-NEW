codeunit 65004 "SI IW Vehicle Sync Events"
{
    // Stage B: enqueue only. The Job Queue processor is introduced in Stage C.
    [EventSubscriber(ObjectType::Table, Database::"SI Vehicle Profile", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnVehicleInserted(var Rec: Record "SI Vehicle Profile"; RunTrigger: Boolean)
    begin
        EnqueueEligible(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"SI Vehicle Profile", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnVehicleModified(var Rec: Record "SI Vehicle Profile"; var xRec: Record "SI Vehicle Profile"; RunTrigger: Boolean)
    begin
        if (Rec."Registration No." = xRec."Registration No.") and
           (Rec."Vehicle Type Code" = xRec."Vehicle Type Code") and
           (Rec."Brand Code" = xRec."Brand Code") and
           (Rec."Model Code" = xRec."Model Code") and
           (Rec.Blocked = xRec.Blocked) then
            exit;

        // Block state changes must refresh existing projections AND pending
        // requests for vehicles not yet published to IW. Never create a new
        // Outbox entry for a vehicle first saved in blocked state.
        if Rec.Blocked then begin
            if (not xRec.Blocked) and (HasProjection(Rec."No.") or HasOutbox(Rec."No.")) then
                EnqueueVehicle(Rec."No.");
            exit;
        end;

        EnqueueEligible(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"SI Vehicle Capacity", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnCapacityInserted(var Rec: Record "SI Vehicle Capacity"; RunTrigger: Boolean)
    begin
        EnqueueCapacityChange(Rec."Vehicle No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"SI Vehicle Capacity", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnCapacityModified(var Rec: Record "SI Vehicle Capacity"; var xRec: Record "SI Vehicle Capacity"; RunTrigger: Boolean)
    begin
        if (Rec."Vehicle No." = xRec."Vehicle No.") and
           (Rec."Capacity Type Code" = xRec."Capacity Type Code") and
           (Rec."Nominal Quantity" = xRec."Nominal Quantity") and
           (Rec."Actual Quantity" = xRec."Actual Quantity") and
           (Rec."Unit of Measure Code" = xRec."Unit of Measure Code") then
            exit;

        EnqueueCapacityChange(Rec."Vehicle No.");
        if Rec."Vehicle No." <> xRec."Vehicle No." then
            EnqueueCapacityChange(xRec."Vehicle No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"SI Vehicle Capacity", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnCapacityDeleted(var Rec: Record "SI Vehicle Capacity"; RunTrigger: Boolean)
    begin
        EnqueueCapacityChange(Rec."Vehicle No.");
    end;

    local procedure EnqueueEligible(SIVehicle: Record "SI Vehicle Profile")
    var
        Mapping: Record "SI IW Vehicle Type Mapping";
    begin
        if SIVehicle.Blocked or (SIVehicle."No." = '') or
           (SIVehicle."Registration No." = '') or
           (SIVehicle."Brand Code" = '') or
           (SIVehicle."Model Code" = '') or
           (SIVehicle."Vehicle Type Code" = '') then
            exit;

        if not Mapping.Get(SIVehicle."Vehicle Type Code") then
            exit;
        if not Mapping.Enabled then
            exit;
        if Mapping."IW Vehicle Category".AsInteger() = 0 then
            exit;

        EnqueueVehicle(SIVehicle."No.");
    end;

    local procedure EnqueueCapacityChange(VehicleNo: Code[20])
    var
        SIVehicle: Record "SI Vehicle Profile";
    begin
        if VehicleNo = '' then
            exit;
        if not SIVehicle.Get(VehicleNo) then
            exit;
        if SIVehicle.Blocked then
            exit;
        // A Capacity edit does not create a new projection by itself.
        if not HasProjection(VehicleNo) then
            exit;
        EnqueueEligible(SIVehicle);
    end;

    local procedure HasOutbox(VehicleNo: Code[20]): Boolean
    var
        Outbox: Record "SI IW Vehicle Sync Outbox";
    begin
        exit(Outbox.Get(VehicleNo));
    end;

    local procedure HasProjection(VehicleNo: Code[20]): Boolean
    var
        IWVehicle: Record IWSVehicle;
    begin
        IWVehicle.SetRange("SI Vehicle No.", VehicleNo);
        exit(not IWVehicle.IsEmpty());
    end;

    local procedure EnqueueVehicle(VehicleNo: Code[20])
    var
        QueueMgt: Codeunit "SI IW Vehicle Sync Queue Mgt.";
    begin
        QueueMgt.Enqueue(VehicleNo);
    end;
}
