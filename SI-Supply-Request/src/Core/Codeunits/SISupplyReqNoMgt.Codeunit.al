codeunit 61000 "SI Supply Req No. Mgt."
{
    procedure InitRequestNo(var Header: Record "SI Supply Req Header")
    var
        Setup: Record "SI Supply Req Setup";
        NoSeries: Codeunit "No. Series";
    begin
        if Header."No." <> '' then
            exit;

        Setup.Get();
        Setup.TestField("Request Nos.");
        Header."No." := NoSeries.GetNextNo(Setup."Request Nos.");
    end;
}
