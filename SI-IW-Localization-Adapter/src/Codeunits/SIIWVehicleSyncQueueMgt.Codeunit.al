codeunit 65003 "SI IW Vehicle Sync Queue Mgt."
{
    // Stage A: only enqueue. No automatic event subscriptions or processing.
    procedure Enqueue(VehicleNo: Code[20])
    var
        Outbox: Record "SI IW Vehicle Sync Outbox";
        SIVehicle: Record "SI Vehicle Profile";
    begin
        SIVehicle.Get(VehicleNo);

        if Outbox.Get(VehicleNo) then begin
            Outbox."Revision No." += 1;
            Outbox.Status := Outbox.Status::Pending;
            Outbox."Attempt Count" := 0;
            Clear(Outbox."Last Error");
            Clear(Outbox."Last Attempt At");
            Outbox."Next Attempt At" := CurrentDateTime();
            Outbox."Modified At" := CurrentDateTime();
            Outbox.Modify(true);
        end else begin
            Outbox.Init();
            Outbox."Vehicle No." := VehicleNo;
            Outbox.Status := Outbox.Status::Pending;
            Outbox."Revision No." := 1;
            Outbox."Next Attempt At" := CurrentDateTime();
            Outbox."Created At" := CurrentDateTime();
            Outbox."Modified At" := Outbox."Created At";
            Outbox.Insert(true);
        end;
    end;
}
