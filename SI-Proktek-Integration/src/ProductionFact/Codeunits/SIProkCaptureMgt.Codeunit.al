codeunit 57094 "SI Prok Capture Mgt."
{
    procedure Capture(DateFrom: Date; DateTo: Date; ConnectionCode: Code[50]; var Imported: Integer; var Existing: Integer; var Failed: Integer)
    var
        Connection: Record "SI Prok Connection";
        ActiveConnection: Record "SI Prok Connection";
        ConnectionMgt: Codeunit "SI Prok Connection Mgt.";
        ProviderContext: Codeunit "SI EDS Provider Context";
        Productions: Codeunit "SI Prok Productions";
        ExportMgt: Codeunit "SI Prok Production Export Mgt.";
        Uuids: List of [Text];
        PageUuids: List of [Text];
        Seen: Dictionary of [Text, Boolean];
        Uuid: Text;
        Dummy: Boolean;
        ResponseText: Text;
        DetailText: Text;
        PageNo: Integer;
        TotalPages: Integer;
        ScopeToken: Guid;
        ScopeStarted: Boolean;
        Archive: Record "SI Prok Raw API Response";
        DetailNo: Integer;
        EntCodes: Dictionary of [Text, Text];
        MaterialUuids: Dictionary of [Text, Text];
        MaterialNames: Dictionary of [Text, Text];
        ConfigError: Text;
    begin
        if (DateFrom = 0D) or (DateTo = 0D) or (DateFrom > DateTo) then
            Error('Некоректний період отримання.');
        Connection.Get(ConnectionCode);
        if (not ConnectionMgt.TryGetActive(ActiveConnection)) or (ActiveConnection.Code <> Connection.Code) then begin
            ProviderContext.BeginScope(Connection."EDS Service Code", Connection."EDS Provider Code", ScopeToken);
            ScopeStarted := true;
        end;
        // A failure of a page request stops the run. Earlier archived responses remain committed.
        PageNo := 1;
        repeat
            Clear(ResponseText);
            Productions.GetPage(Connection, DateFrom, DateTo, 100, PageNo, false, false, ResponseText);
            ArchiveResponse(ConnectionCode, 'GetProductions', '', ResponseText, Archive);
            Commit(); // Durable raw evidence before any parsing; no BC standard posting is performed.
            Clear(PageUuids);
            ClearLastError();
            if not TryParseIndex(ResponseText, PageUuids, TotalPages) then begin
                MarkError(Archive, GetLastErrorText());
                Failed += 1;
                if ScopeStarted then ProviderContext.EndScope(ScopeToken);
                exit;
            end;
            MarkProcessed(Archive);
            foreach Uuid in PageUuids do
                if not Seen.Get(Uuid, Dummy) then begin
                    Seen.Add(Uuid, true);
                    Uuids.Add(Uuid);
                end;
            PageNo += 1;
        until PageNo > TotalPages;
        // Load once per capture batch, using the SAME EDS provider as GetDetails.
        // A config outage must not discard production evidence.
        ClearLastError();
        if not ExportMgt.TryLoadCaptureMaterialConfig(Connection, EntCodes, MaterialUuids, MaterialNames) then begin
            ConfigError := GetLastErrorText();
            Clear(EntCodes);
            Clear(MaterialUuids);
            Clear(MaterialNames);
        end;
        DetailNo := 0;
        foreach Uuid in Uuids do begin
            if DetailNo > 0 then Sleep(600);
            DetailNo += 1;
            Clear(DetailText);
            ClearLastError();
            if TryGetDetails(Connection, Uuid, DetailText) then begin
                ArchiveResponse(ConnectionCode, 'GetProductionDetails', Uuid, DetailText, Archive);
                Commit(); // Raw evidence survives later parser errors.
                ClearLastError();
                if TryProcessDetail(ConnectionCode, DetailText, Uuid, EntCodes, MaterialUuids, MaterialNames, Imported, Existing) then begin
                    MarkProcessed(Archive);
                    if ConfigError <> '' then begin
                        Archive."Error Message" := CopyStr(
                            StrSubstNo('Material config unavailable; captured unmapped: %1', ConfigError),
                            1, MaxStrLen(Archive."Error Message"));
                        Archive.Modify(true);
                    end;
                end
                else begin
                    MarkError(Archive, GetLastErrorText());
                    Failed += 1;
                end;
            end else
                Failed += 1; // HTTP transport errors have no successful response payload to archive.
        end;
        if ScopeStarted then ProviderContext.EndScope(ScopeToken);
    end;

    local procedure ArchiveResponse(ConnectionCode: Code[50]; Operation: Code[50]; Uuid: Text; Payload: Text; var Archive: Record "SI Prok Raw API Response")
    begin
        Clear(Archive);
        Archive.Init();
        Archive."Connection Code" := ConnectionCode;
        Archive."API Operation" := Operation;
        Archive."Production UUID" := CopyStr(Uuid, 1, MaxStrLen(Archive."Production UUID"));
        Archive."Capture Mode" := Archive."Capture Mode"::Test;
        Archive.SetRaw(Payload);
        Archive.Insert(true);
    end;

    local procedure MarkProcessed(var Archive: Record "SI Prok Raw API Response")
    begin
        Archive."Processing Status" := Archive."Processing Status"::Processed;
        Archive.Modify(true);
    end;

    local procedure MarkError(var Archive: Record "SI Prok Raw API Response"; ErrorText: Text)
    begin
        Archive."Processing Status" := Archive."Processing Status"::Error;
        Archive."Error Message" := CopyStr(ErrorText, 1, MaxStrLen(Archive."Error Message"));
        Archive.Modify(true);
    end;

    [TryFunction]
    local procedure TryParseIndex(Payload: Text; var Uuids: List of [Text]; var Pages: Integer)
    var
        ExportMgt: Codeunit "SI Prok Production Export Mgt.";
        Root: JsonObject;
        Token: JsonToken;
    begin
        ExportMgt.GetProductionUuidsFromRaw(Payload, Uuids);
        Pages := 1;
        if Root.ReadFrom(Payload) and Root.Get('totalpages', Token) and Token.IsValue() then
            Pages := Token.AsValue().AsInteger();
        if Pages < 1 then Pages := 1;
    end;

    [TryFunction]
    local procedure TryGetDetails(var Connection: Record "SI Prok Connection"; Uuid: Text; var Payload: Text)
    var Productions: Codeunit "SI Prok Productions";
    begin
        Productions.GetDetails(Connection, Uuid, false, Payload);
    end;

    [TryFunction]
    local procedure TryProcessDetail(
        ConnectionCode: Code[50];
        Payload: Text;
        Uuid: Text;
        EntCodes: Dictionary of [Text, Text];
        MaterialUuids: Dictionary of [Text, Text];
        MaterialNames: Dictionary of [Text, Text];
        var Imported: Integer;
        var Existing: Integer)
    var
        ExportMgt: Codeunit "SI Prok Production Export Mgt.";
        FactMgt: Codeunit "SI Prok Prod Fact Mgt.";
        Fact: Record "SI Prok Production Fact";
        Canonical: Text;
    begin
        ExportMgt.BuildCaptureCanonicalFromDetails(
            Payload, Uuid, EntCodes, MaterialUuids, MaterialNames, Canonical);
        if FactMgt.PersistCaptureOnlyWithConnection(Canonical, ConnectionCode, Fact) then Imported += 1 else Existing += 1;
    end;
}
