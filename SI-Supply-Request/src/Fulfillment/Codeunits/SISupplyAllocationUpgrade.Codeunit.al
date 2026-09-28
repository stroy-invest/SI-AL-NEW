codeunit 61013 "SI Supply Alloc Upgrade"
{
    Subtype = Upgrade;

    trigger OnUpgradePerCompany()
    var
        Allocation: Record "SI Supply Allocation";
    begin
        if Allocation.FindSet(true) then
            repeat
                Allocation.RefreshAllocationReadiness();
                Allocation.Modify(false);
            until Allocation.Next() = 0;
    end;
}
