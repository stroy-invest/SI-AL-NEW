codeunit 63302 "SI Vehicle Actual Capacity Upg"
{
    Subtype = Upgrade;
    trigger OnUpgradePerCompany()
    var
        Vehicle: Record "SI Vehicle Profile";
        Mgt: Codeunit "SI Vehicle Management";
    begin
        if Vehicle.FindSet() then
            repeat
                if (Vehicle."Brand Code" <> '') and (Vehicle."Model Code" <> '') then
                    Mgt.SyncVehicleActualCapacities(Vehicle."No.");
            until Vehicle.Next() = 0;
    end;
}
