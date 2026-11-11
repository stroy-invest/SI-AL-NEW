codeunit 63303 "SI Veh Actual Cap Events"
{
    [EventSubscriber(ObjectType::Table, Database::"SI Vehicle Profile", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnVehicleInserted(var Rec: Record "SI Vehicle Profile"; RunTrigger: Boolean)
    var
        Mgt: Codeunit "SI Vehicle Management";
    begin
        if (Rec."Brand Code" <> '') and (Rec."Model Code" <> '') then
            Mgt.SyncVehicleActualCapacities(Rec."No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"SI Vehicle Profile", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnVehicleModified(var Rec: Record "SI Vehicle Profile"; var xRec: Record "SI Vehicle Profile"; RunTrigger: Boolean)
    var
        Mgt: Codeunit "SI Vehicle Management";
    begin
        if (Rec."Brand Code" = xRec."Brand Code") and (Rec."Model Code" = xRec."Model Code") then
            exit;
        if (Rec."Brand Code" <> '') and (Rec."Model Code" <> '') then
            Mgt.SyncVehicleActualCapacities(Rec."No.");
    end;
}
