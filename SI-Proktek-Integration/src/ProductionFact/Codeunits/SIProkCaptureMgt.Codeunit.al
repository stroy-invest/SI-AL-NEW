codeunit 57094 "SI Prok Capture Mgt."
{
    procedure Capture(DateFrom: Date; DateTo: Date; ConnectionCode: Code[50]; var Imported: Integer; var Existing: Integer; var Failed: Integer)
    var
        Conflicts: Integer;
    begin
        // Retain the established Test entry point and its error counter.
        CaptureWithMode(DateFrom, DateTo, ConnectionCode, Enum::"SI Prok Capture Mode"::Test,
            Imported, Existing, Conflicts, Failed);
        Failed += Conflicts;
    end;

    procedure CaptureWithMode(DateFrom: Date; DateTo: Date; ConnectionCode: Code[50]; Mode: Enum "SI Prok Capture Mode"; var Imported: Integer; var Existing: Integer; var Conflicts: Integer; var Failed: Integer)
    var
        Connection: Record "SI Prok Connection";
        ProviderContext: Codeunit "SI EDS Provider Context";
        ScopeToken: Guid;
        FailureText: Text;
    begin
        Clear(Imported);
        Clear(Existing);
        Clear(Conflicts);
        Clear(Failed);
        if (DateFrom = 0D) or (DateTo = 0D) or (DateFrom > DateTo) then
            Error('Некоректний період отримання.');
        Connection.Get(ConnectionCode);
        ProviderContext.BeginScope(Connection."EDS Service Code", Connection."EDS Provider Code", ScopeToken);
        ClearLastError();
        if not TryCaptureCore(DateFrom, DateTo, Connection, Mode, Imported, Existing, Conflicts, Failed) then begin
            // Preserve the original error before cleanup can affect LastError.
            FailureText := GetLastErrorText();
            if FailureText = '' then
                FailureText := 'Capture завершився невизначеною помилкою.';
            if not TryEndProviderScope(ScopeToken) then
                Error('%1\\Provider Context cleanup: %2', FailureText, GetLastErrorText());
            // TryFunction does not roll back writes. This Error rolls back any
            // remaining uncommitted work; earlier raw/worker commits stay durable.
            Error('%1', FailureText);
        end;
        if not TryEndProviderScope(ScopeToken) then
            Error('Не вдалося відновити Provider Context: %1', GetLastErrorText());
    end;

    [TryFunction]
    local procedure TryCaptureCore(DateFrom: Date; DateTo: Date; Connection: Record "SI Prok Connection"; Mode: Enum "SI Prok Capture Mode"; var Imported: Integer; var Existing: Integer; var Conflicts: Integer; var Failed: Integer)
    var
        ExportMgt: Codeunit "SI Prok Production Export Mgt.";
        Worker: Codeunit "SI Prok Fact Intake Worker";
        Uuids: List of [Text];
        PageUuids: List of [Text];
        Seen: Dictionary of [Text, Boolean];
        Uuid: Text;
        ResponseText: Text;
        DetailText: Text;
        Canonical: Text;
        ErrorText: Text;
        PageNo: Integer;
        TotalPages: Integer;
        Archive: Record "SI Prok Raw API Response";
        ConfigurationArchive: Record "SI Prok Raw API Response";
        ConfigurationResponse: Text;
        ConfigurationArchiveEntryNo: Integer;
        DetailNo: Integer;
        EntCodes: Dictionary of [Text, Text];
        MaterialUuids: Dictionary of [Text, Text];
        MaterialNames: Dictionary of [Text, Text];
        ConfigError: Text;
    begin
        // This boundary catches errors for scope cleanup, not for rollback.
        // Fact/material writes remain in the Boolean Run worker below.
        PageNo := 1;
        repeat
            Clear(ResponseText);
            ClearLastError();
            if not TryGetPage(Connection, DateFrom, DateTo, PageNo, ResponseText) then begin
                ErrorText := GetLastErrorText();
                ArchiveResponse(Connection.Code, 'GetProductions', '', ResponseText, Mode, Archive);
                MarkError(Archive, 'Не вдалося отримати індекс виробництва. ' + ErrorText);
                Commit();
                Failed += 1;
                exit;
            end;
            ArchiveResponse(Connection.Code, 'GetProductions', '', ResponseText, Mode, Archive);
            Commit(); // Raw evidence is durable before normalization.
            Clear(PageUuids);
            ClearLastError();
            if not TryParseIndex(ResponseText, PageUuids, TotalPages) then begin
                MarkError(Archive, GetLastErrorText());
                Commit();
                Failed += 1;
                exit;
            end;
            MarkProcessed(Archive);
            Commit();
            foreach Uuid in PageUuids do
                if not Seen.ContainsKey(LowerCase(Uuid)) then begin
                    Seen.Add(LowerCase(Uuid), true);
                    Uuids.Add(Uuid);
                end;
            PageNo += 1;
        until PageNo > TotalPages;
        ClearLastError();
        if not ExportMgt.TryGetCaptureMaterialConfigResponse(Connection, ConfigurationResponse) then
            ConfigError := GetLastErrorText();
        // Archive the real API response, not a reconstructed configuration.
        ArchiveResponse(Connection.Code, 'GetMaterialsConfig', '', ConfigurationResponse, Mode, ConfigurationArchive);
        ConfigurationArchiveEntryNo := ConfigurationArchive."Entry No.";
        Commit(); // Config evidence survives parser/fact errors.
        if ConfigError = '' then begin
            ClearLastError();
            if not ExportMgt.TryParseCaptureMaterialConfigResponse(
                ConfigurationResponse, EntCodes, MaterialUuids, MaterialNames) then
                ConfigError := GetLastErrorText();
        end;
        if ConfigError <> '' then begin
            Clear(EntCodes);
            Clear(MaterialUuids);
            Clear(MaterialNames);
            MarkError(ConfigurationArchive, ConfigError);
        end else
            MarkProcessed(ConfigurationArchive);
        // Material Config/auth may have written session state. The isolated
        // worker must always be called outside an open write transaction.
        Commit();
        foreach Uuid in Uuids do begin
            if DetailNo > 0 then
                Sleep(600);
            DetailNo += 1;
            Clear(DetailText);
            ClearLastError();
            if not TryGetDetails(Connection, Uuid, DetailText) then begin
                ErrorText := GetLastErrorText();
                ArchiveResponse(Connection.Code, 'GetProductionDetails', Uuid, DetailText, Mode, Archive);
                MarkError(Archive, 'Не вдалося отримати деталі виробництва. ' + ErrorText);
                Commit();
                Failed += 1;
                continue;
            end;
            ArchiveResponse(Connection.Code, 'GetProductionDetails', Uuid, DetailText, Mode, Archive);
            Commit();
            Clear(Canonical);
            ClearLastError();
            if not TryBuildCanonical(DetailText, Uuid, EntCodes, MaterialUuids, MaterialNames, Canonical) then begin
                MarkError(Archive, GetLastErrorText());
                Commit();
                Failed += 1;
                continue;
            end;
            Clear(Worker);
            Worker.SetCanonical(Canonical);
            Worker.SetConfigurationArchive(ConfigurationArchiveEntryNo);
            ClearLastError();
            if not Worker.Run(Archive) then begin
                ErrorText := GetLastErrorText();
                Archive.Get(Archive."Entry No.");
                MarkError(Archive, ErrorText);
                Commit();
                Failed += 1;
                continue;
            end;
            Archive.Get(Archive."Entry No.");
            case Archive."Intake Result" of
                Archive."Intake Result"::Imported: Imported += 1;
                Archive."Intake Result"::Existing: Existing += 1;
                Archive."Intake Result"::Conflict: Conflicts += 1;
                else Failed += 1;
            end;
            if ConfigError <> '' then begin
                Archive."Error Message" := CopyStr(
                    Archive."Error Message" + ' Material Config недоступний; використано fallback. ' + ConfigError,
                    1, MaxStrLen(Archive."Error Message"));
                Archive.Modify(true);
            end;
            Commit();
        end;
    end;

    [TryFunction]
    local procedure TryEndProviderScope(ScopeToken: Guid)
    var
        ProviderContext: Codeunit "SI EDS Provider Context";
    begin
        ProviderContext.EndScope(ScopeToken);
    end;

    [TryFunction]
    local procedure TryGetPage(var Connection: Record "SI Prok Connection"; DateFrom: Date; DateTo: Date; PageNo: Integer; var Payload: Text)
    var
        Productions: Codeunit "SI Prok Productions";
    begin
        Productions.GetPage(Connection, DateFrom, DateTo, 100, PageNo, false, false, Payload);
    end;

    local procedure ArchiveResponse(ConnectionCode: Code[50]; Operation: Code[50]; Uuid: Text; Payload: Text; Mode: Enum "SI Prok Capture Mode"; var Archive: Record "SI Prok Raw API Response")
    begin
        Clear(Archive);
        Archive.Init();
        Archive."Connection Code" := ConnectionCode;
        Archive."API Operation" := Operation;
        Archive."Production UUID" := CopyStr(Uuid, 1, MaxStrLen(Archive."Production UUID"));
        Archive."Capture Mode" := Mode;
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
        Archive."Intake Result" := Archive."Intake Result"::Error;
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
    local procedure TryBuildCanonical(
        Payload: Text;
        Uuid: Text;
        EntCodes: Dictionary of [Text, Text];
        MaterialUuids: Dictionary of [Text, Text];
        MaterialNames: Dictionary of [Text, Text];
        var Canonical: Text)
    var
        ExportMgt: Codeunit "SI Prok Production Export Mgt.";
    begin
        // Parsing only: fact/material writes belong to the transactional worker.
        ExportMgt.BuildCaptureCanonicalFromDetails(
            Payload, Uuid, EntCodes, MaterialUuids, MaterialNames, Canonical);
    end;

}
