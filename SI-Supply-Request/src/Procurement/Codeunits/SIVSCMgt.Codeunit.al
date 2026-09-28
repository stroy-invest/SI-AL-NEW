codeunit 61041 "SI VSC Mgt."
{
    procedure InitCapabilityNo(var Capability: Record "SI Vendor Supply Capability")
    var
        Setup: Record "SI Supply Req Setup";
        NoSeries: Codeunit "No. Series";
    begin
        if Capability.Code <> '' then
            exit;

        Setup.Get();
        Setup.TestField("VSC Nos.");
        Capability.Code := NoSeries.GetNextNo(Setup."VSC Nos.");
    end;
}
