codeunit 57210 "SI Prok Operations Config"
{
    procedure EnsureForConnection(ConnectionCode: Code[50]; var Setup: Record "SI Prok Operations Setup")
    var
        Connection: Record "SI Prok Connection";
    begin
        Connection.Get(ConnectionCode);
        if Setup.Get(ConnectionCode) then
            exit;
        Setup.Init();
        Setup."Connection Code" := ConnectionCode;
        Setup.Insert(true);
    end;

    procedure Resolve(ConnectionCode: Code[50]; var Setup: Record "SI Prok Operations Setup")
    begin
        if not Setup.Get(ConnectionCode) then
            Error('Для профілю Proktek %1 не створено Operations Setup.', ConnectionCode);
        Setup.TestField("Sync Interval Minutes");
        if (Setup."Sync Lookback Days" < 0) or (Setup."Sync Lookback Days" > 30) then
            Error('Некоректний період повторного отримання фактів для %1.', ConnectionCode);
    end;
}
