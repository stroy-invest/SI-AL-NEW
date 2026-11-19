codeunit 65006 "SI IW Vehicle Sync Worker"
{
    TableNo = "SI IW Vehicle Sync Outbox";

    trigger OnRun()
    var
        Outbox: Record "SI IW Vehicle Sync Outbox";
        SIVehicle: Record "SI Vehicle Profile";
        IWVehicle: Record IWSVehicle;
        Projection: Codeunit "SI IW Vehicle Projection Mgt.";
    begin
        // Serialize the projection and its Outbox completion in one transaction.
        Outbox.LockTable();
        if not Outbox.Get(Rec."Vehicle No.") then
            exit;
        if (Outbox.Status <> Outbox.Status::Pending) or
           (Outbox."Revision No." <> Rec."Revision No.") then
            exit;

        SIVehicle.Get(Outbox."Vehicle No.");
        IWVehicle.SetRange("SI Vehicle No.", SIVehicle."No.");

        if SIVehicle.Blocked then begin
            // Blocked, never published: no IW record should be created.
            if IWVehicle.FindSet(true) then
                repeat
                    if not IWVehicle."SI Vehicle Blocked" then begin
                        IWVehicle."SI Vehicle Blocked" := true;
                        IWVehicle.Modify(true);
                    end;
                until IWVehicle.Next() = 0;
        end else begin
            Projection.PublishVehicle(SIVehicle."No.");
            // PublishVehicle can Insert or Modify; reload the projection.
            IWVehicle.Reset();
            IWVehicle.SetRange("SI Vehicle No.", SIVehicle."No.");
            if not IWVehicle.FindFirst() then
                Error('IW projection not found after publishing SI vehicle %1.', SIVehicle."No.");
            if IWVehicle."SI Vehicle Blocked" then begin
                IWVehicle."SI Vehicle Blocked" := false;
                IWVehicle.Modify(true);
            end;
        end;

        Outbox.Status := Outbox.Status::Completed;
        Outbox."Attempt Count" += 1;
        Outbox."Last Attempt At" := CurrentDateTime();
        Outbox."Last Success At" := CurrentDateTime();
        Clear(Outbox."Last Error");
        Clear(Outbox."Next Attempt At");
        Outbox."Modified At" := CurrentDateTime();
        Outbox.Modify(true);
    end;
}
