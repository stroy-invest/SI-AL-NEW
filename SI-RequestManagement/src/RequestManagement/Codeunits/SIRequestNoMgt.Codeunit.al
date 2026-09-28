codeunit 52010 "SI Request No. Mgt."
{
    procedure InitRequestNo(var RequestHeader: Record "SI Request Header")
    var
        RequestSetup: Record "SI Request Setup";
        NoSeries: Codeunit "No. Series";
    begin
        if RequestHeader."No." <> '' then
            exit;

        RequestSetup.Get();
        RequestSetup.TestField("Request Nos.");

        RequestHeader."No." :=
            NoSeries.GetNextNo(RequestSetup."Request Nos.");
    end;
}