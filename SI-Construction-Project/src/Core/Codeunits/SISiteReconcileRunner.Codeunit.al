codeunit 60031 "SI Site Reconcile Runner"
{
    TableNo = "SI Construction Site";
    trigger OnRun()
    var
        Sync: Codeunit "SI Site ShipTo Sync";
    begin
        Sync.Sync(Rec);
    end;
}
