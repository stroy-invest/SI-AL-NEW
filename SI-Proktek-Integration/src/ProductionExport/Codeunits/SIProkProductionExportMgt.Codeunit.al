codeunit 57081 "SI Prok Production Export Mgt."
{
    procedure GenerateNew(DateFrom: Date; DateTo: Date; ConnectionCode: Code[50]; var ExportEntry: Record "SI Prok Production Export")
    begin
        ValidatePeriod(DateFrom, DateTo);
        ValidateConnection(ConnectionCode);

        ExportEntry.Init();
        ExportEntry."Date From" := DateFrom;
        ExportEntry."Date To" := DateTo;
        ExportEntry."Connection Code" := ConnectionCode;
        ExportEntry."Created At" := CurrentDateTime;
        ExportEntry."Created By" := CopyStr(UserId(), 1, MaxStrLen(ExportEntry."Created By"));
        ExportEntry.Status := ExportEntry.Status::New;
        ExportEntry.Insert(true);

        GenerateExisting(ExportEntry);
    end;

    procedure GenerateExisting(var ExportEntry: Record "SI Prok Production Export")
    var
        RequestedConnection: Record "SI Prok Connection";
        CurrentConnection: Record "SI Prok Connection";
        ConnectionMgt: Codeunit "SI Prok Connection Mgt.";
        ProviderContext: Codeunit "SI EDS Provider Context";
        ScopeToken: Guid;
        ScopeStarted: Boolean;
        OperationSucceeded: Boolean;
        PayloadText: Text;
        ProductionCount: Integer;
        TotalVolumeM3: Decimal;
        ErrorText: Text;
    begin
        ValidatePeriod(ExportEntry."Date From", ExportEntry."Date To");
        ValidateConnection(ExportEntry."Connection Code");

        ExportEntry.Status := ExportEntry.Status::New;
        Clear(ExportEntry."File Name");
        ExportEntry."Production Count" := 0;
        ExportEntry."Total Volume M3" := 0;
        Clear(ExportEntry."Error Message");
        Clear(ExportEntry."JSON Payload");
        ExportEntry.Modify(true);

        RequestedConnection.Get(ExportEntry."Connection Code");

        // Use a session-local Foundation EDS provider scope only when the explicitly
        // selected profile differs from the currently active Proktek profile.
        // The persistent Active flag is never changed by the export.
        if (not ConnectionMgt.TryGetActive(CurrentConnection)) or
           (CurrentConnection.Code <> RequestedConnection.Code)
        then begin
            ProviderContext.BeginScope(
                RequestedConnection."EDS Service Code",
                RequestedConnection."EDS Provider Code",
                ScopeToken);
            ScopeStarted := true;
        end;

        ClearLastError();
        OperationSucceeded := TryBuildExport(
            ExportEntry."Date From",
            ExportEntry."Date To",
            ExportEntry."Connection Code",
            PayloadText,
            ProductionCount,
            TotalVolumeM3);
        if not OperationSucceeded then begin
            ErrorText := GetLastErrorText();
            if ErrorText = '' then
                ErrorText := 'Невідома помилка формування Production Export v2.';
        end;

        // ALWAYS clean up our temporary EDS context before processing or re-raising
        // the operation result. EndScope is idempotent and restores the exact prior
        // session-local context, including the state where no override existed.
        if ScopeStarted then
            ProviderContext.EndScope(ScopeToken);

        if OperationSucceeded then begin
            ExportEntry.SetPayload(PayloadText);
            ExportEntry."Production Count" := ProductionCount;
            ExportEntry."Total Volume M3" := TotalVolumeM3;
            ExportEntry."File Name" := BuildFileName(CurrentDateTime);
            ExportEntry.Status := ExportEntry.Status::Ready;
            Clear(ExportEntry."Error Message");
        end else begin
            ExportEntry.Status := ExportEntry.Status::Error;
            ExportEntry."Error Message" := CopyStr(ErrorText, 1, MaxStrLen(ExportEntry."Error Message"));
        end;

        ExportEntry.Modify(true);
    end;

    procedure Download(var ExportEntry: Record "SI Prok Production Export")
    var
        InStr: InStream;
        DownloadName: Text;
    begin
        ExportEntry.TestField(Status, ExportEntry.Status::Ready);
        ExportEntry.TestField("File Name");
        ExportEntry.CalcFields("JSON Payload");
        if not ExportEntry."JSON Payload".HasValue() then
            Error('Для цього експорту відсутній JSON-файл.');

        ExportEntry."JSON Payload".CreateInStream(InStr, TextEncoding::UTF8);
        DownloadName := ExportEntry."File Name";
        DownloadFromStream(InStr, '', '', '', DownloadName);
    end;

    [TryFunction]
    local procedure TryBuildExport(
        DateFrom: Date;
        DateTo: Date;
        ConnectionCode: Code[50];
        var PayloadText: Text;
        var ProductionCount: Integer;
        var TotalVolumeM3: Decimal)
    var
        Connection: Record "SI Prok Connection";
        ProductionsMgt: Codeunit "SI Prok Productions";
        RootJson: JsonObject;
        PeriodJson: JsonObject;
        SummaryJson: JsonObject;
        SourceJson: JsonObject;
        ProductionsJson: JsonArray;
        EntCodeByBunker: Dictionary of [Text, Text];
        MaterialUuidByBunker: Dictionary of [Text, Text];
        MaterialNameByBunker: Dictionary of [Text, Text];
        SeenProductionUuid: Dictionary of [Text, Boolean];
        ProductionUuids: List of [Text];
        ResponseText: Text;
        DetailResponseText: Text;
        ProductionUuid: Text;
        DetailRequestNo: Integer;
        TotalPages: Integer;
        PageNo: Integer;
    begin
        ValidatePeriod(DateFrom, DateTo);
        ValidateConnection(ConnectionCode);

        if not Connection.Get(ConnectionCode) then
            Error('Профіль підключення Proktek %1 не знайдено.', ConnectionCode);

        // Phase 1: lightweight index. GetProductions is used only to identify
        // productions in the requested period and obtain pagination/summary data.
        ProductionsMgt.GetPage(
            Connection,
            DateFrom,
            DateTo,
            100,
            1,
            false,
            false,
            ResponseText);

        CollectProductionIndexResponse(
            ResponseText,
            ProductionUuids,
            SeenProductionUuid,
            ProductionCount,
            TotalVolumeM3,
            TotalPages);

        for PageNo := 2 to TotalPages do begin
            Clear(ResponseText);
            ProductionsMgt.GetPage(
                Connection,
                DateFrom,
                DateTo,
                100,
                PageNo,
                false,
                false,
                ResponseText);

            CollectProductionIndexResponse(
                ResponseText,
                ProductionUuids,
                SeenProductionUuid,
                ProductionCount,
                TotalVolumeM3,
                TotalPages);
        end;

        // Empty period is a valid export and must not depend on Material Config.
        if ProductionCount > 0 then begin
            // Phase 2: resolve technical hopper codes to Proktek/ERP materials once.
            LoadMaterialConfig(
                Connection,
                EntCodeByBunker,
                MaterialUuidByBunker,
                MaterialNameByBunker);

            // Phase 3: authoritative details for every production.
            // Proktek allows 4 requests per 2 seconds. Pace detail calls below the limit
            // because these are N requests in a tight loop. 600 ms gives headroom for
            // timing jitter and for other API calls made by the same export session.
            DetailRequestNo := 0;
            foreach ProductionUuid in ProductionUuids do begin
                if DetailRequestNo > 0 then
                    Sleep(600);
                DetailRequestNo += 1;

                Clear(DetailResponseText);
                ProductionsMgt.GetDetails(
                    Connection,
                    ProductionUuid,
                    false,
                    DetailResponseText);

                ProductionsJson.Add(
                    BuildCanonicalProductionFromDetails(
                        DetailResponseText,
                        ProductionUuid,
                        EntCodeByBunker,
                        MaterialUuidByBunker,
                        MaterialNameByBunker));
            end;
        end;

        RootJson.Add('schemaVersion', '2.0');
        RootJson.Add('exportedAt', Format(CurrentDateTime, 0, 9));

        SourceJson.Add('system', 'PROKTEK');
        SourceJson.Add('connectionCode', Connection.Code);
        SourceJson.Add('environment', Format(Connection.Environment));
        RootJson.Add('source', SourceJson);

        PeriodJson.Add('dateFrom', Format(DateFrom, 0, '<Year4>-<Month,2>-<Day,2>'));
        PeriodJson.Add('dateTo', Format(DateTo, 0, '<Year4>-<Month,2>-<Day,2>'));
        RootJson.Add('period', PeriodJson);

        SummaryJson.Add('productionCount', ProductionCount);
        SummaryJson.Add('totalVolumeM3', TotalVolumeM3);
        RootJson.Add('summary', SummaryJson);
        RootJson.Add('productions', ProductionsJson);

        RootJson.WriteTo(PayloadText);
    end;

    procedure ParsePilotRawResponses(
        ProductionsResponseText: Text;
        DetailResponseText: Text;
        MaterialConfigResponseText: Text;
        ExpectedProductionUuid: Text;
        var CanonicalProductionText: Text)
    var
        ProductionUuids: List of [Text];
        SeenProductionUuid: Dictionary of [Text, Boolean];
        EntCodeByBunker: Dictionary of [Text, Text];
        MaterialUuidByBunker: Dictionary of [Text, Text];
        MaterialNameByBunker: Dictionary of [Text, Text];
        CanonicalProduction: JsonObject;
        ProductionUuid: Text;
        ProductionCount: Integer;
        TotalPages: Integer;
        TotalVolumeM3: Decimal;
        ExpectedFound: Boolean;
    begin
        // Pilot simulator deliberately enters through the same parsers used by the
        // real GetProductions / GetProductionDetails / GetMaterialsConfig flow.
        CollectProductionIndexResponse(
            ProductionsResponseText,
            ProductionUuids,
            SeenProductionUuid,
            ProductionCount,
            TotalVolumeM3,
            TotalPages);

        foreach ProductionUuid in ProductionUuids do
            if LowerCase(ProductionUuid) = LowerCase(ExpectedProductionUuid) then
                ExpectedFound := true;

        if not ExpectedFound then
            Error('GetProductions simulation does not contain expected production uuid %1.', ExpectedProductionUuid);

        ParseMaterialConfig(
            MaterialConfigResponseText,
            EntCodeByBunker,
            MaterialUuidByBunker,
            MaterialNameByBunker);

        CanonicalProduction := BuildCanonicalProductionFromDetails(
            DetailResponseText,
            ExpectedProductionUuid,
            EntCodeByBunker,
            MaterialUuidByBunker,
            MaterialNameByBunker);
        CanonicalProduction.WriteTo(CanonicalProductionText);
    end;

    procedure GetProductionUuidsFromRaw(ResponseText: Text; var ProductionUuids: List of [Text])
    var
        SeenProductionUuid: Dictionary of [Text, Boolean];
        ProductionCount: Integer;
        TotalPages: Integer;
        TotalVolumeM3: Decimal;
    begin
        Clear(ProductionUuids);
        CollectProductionIndexResponse(
            ResponseText,
            ProductionUuids,
            SeenProductionUuid,
            ProductionCount,
            TotalVolumeM3,
            TotalPages);
    end;

    procedure BuildCanonicalForProduction(
        var Connection: Record "SI Prok Connection";
        ProductionUuid: Text;
        var CanonicalProductionText: Text)
    var
        ProductionsMgt: Codeunit "SI Prok Productions";
        EntCodeByBunker: Dictionary of [Text, Text];
        MaterialUuidByBunker: Dictionary of [Text, Text];
        MaterialNameByBunker: Dictionary of [Text, Text];
        DetailResponseText: Text;
        CanonicalProduction: JsonObject;
    begin
        LoadMaterialConfig(
            Connection,
            EntCodeByBunker,
            MaterialUuidByBunker,
            MaterialNameByBunker);

        ProductionsMgt.GetDetails(Connection, ProductionUuid, false, DetailResponseText);
        CanonicalProduction := BuildCanonicalProductionFromDetails(
            DetailResponseText,
            ProductionUuid,
            EntCodeByBunker,
            MaterialUuidByBunker,
            MaterialNameByBunker);
        CanonicalProduction.WriteTo(CanonicalProductionText);
    end;

    local procedure CollectProductionIndexResponse(
        ResponseText: Text;
        var ProductionUuids: List of [Text];
        var SeenProductionUuid: Dictionary of [Text, Boolean];
        var ProductionCount: Integer;
        var TotalVolumeM3: Decimal;
        var TotalPages: Integer)
    var
        ResponseJson: JsonObject;
        Productions: JsonArray;
        Token: JsonToken;
        ProductionToken: JsonToken;
        ProductionJson: JsonObject;
        ResponseStatus: Boolean;
        ResponseMessage: Text;
        CurrentTotalPages: Integer;
        ProductionUuid: Text;
        QuantityM3: Decimal;
        Dummy: Boolean;
        I: Integer;
    begin
        if ResponseText = '' then
            Error('Proktek GetProductions повернув порожнє тіло відповіді.');
        if not ResponseJson.ReadFrom(ResponseText) then
            Error('Не вдалося прочитати JSON-відповідь Proktek GetProductions.');

        if not TryGetBoolean(ResponseJson, 'responseStatus', ResponseStatus) then
            Error('У відповіді GetProductions відсутнє поле responseStatus.');
        TryGetText(ResponseJson, 'responseMessage', ResponseMessage);
        if not ResponseStatus then begin
            if ResponseMessage = '' then
                ResponseMessage := 'Proktek повернув responseStatus=false для GetProductions.';
            Error('%1', ResponseMessage);
        end;

        if TryGetInteger(ResponseJson, 'totalpages', CurrentTotalPages) then
            if CurrentTotalPages > TotalPages then
                TotalPages := CurrentTotalPages;

        if not ResponseJson.Get('productions', Token) then
            exit;
        if not Token.IsArray() then
            Error('Поле productions у відповіді GetProductions не є масивом.');

        Productions := Token.AsArray();
        for I := 0 to Productions.Count() - 1 do begin
            Productions.Get(I, ProductionToken);
            if not ProductionToken.IsObject() then
                continue;

            ProductionJson := ProductionToken.AsObject();
            Clear(ProductionUuid);
            if not TryGetText(ProductionJson, 'uuid', ProductionUuid) then
                Error('GetProductions повернув запис без production uuid.');
            if ProductionUuid = '' then
                Error('GetProductions повернув запис із порожнім production uuid.');

            if SeenProductionUuid.Get(ProductionUuid, Dummy) then
                continue;

            SeenProductionUuid.Add(ProductionUuid, true);
            ProductionUuids.Add(ProductionUuid);
            ProductionCount += 1;

            Clear(QuantityM3);
            TryGetDecimal(ProductionJson, 'metrekup', QuantityM3);
            TotalVolumeM3 += QuantityM3;
        end;
    end;

    local procedure LoadMaterialConfig(
        var Connection: Record "SI Prok Connection";
        var EntCodeByBunker: Dictionary of [Text, Text];
        var MaterialUuidByBunker: Dictionary of [Text, Text];
        var MaterialNameByBunker: Dictionary of [Text, Text])
    var
        Session: Record "SI Prok Session";
        AuthMgt: Codeunit "SI Prok Auth Mgt.";
        ResponseText: Text;
    begin
        AuthMgt.EnsureSession(Connection, Session);

        if IsNullGuid(Session."Session GUID") then
            Error('Неможливо отримати Material Configs: GUID сеансу Proktek відсутній.');
        if Session."Plant IDs" = '' then
            Error('Неможливо отримати Material Configs: Proktek не повернув santral_id для сеансу.');

        ExecuteGetMaterialsConfigWithReauth(Connection, Session, ResponseText);

        ParseMaterialConfig(
            ResponseText,
            EntCodeByBunker,
            MaterialUuidByBunker,
            MaterialNameByBunker);
    end;

    local procedure ExecuteGetMaterialsConfigWithReauth(
        var Connection: Record "SI Prok Connection";
        var Session: Record "SI Prok Session";
        var ResponseText: Text)
    var
        RuntimeParam: Record "SI EDS Runtime Param" temporary;
        ResponseBuffer: Record "SI EDS Response Buffer" temporary;
        AuthMgt: Codeunit "SI Prok Auth Mgt.";
        EDSOrchestrator: Codeunit "SI EDS Orchestrator";
        RequestJson: JsonObject;
        PlantArray: JsonArray;
        RequestBody: Text;
        AttemptNo: Integer;
    begin
        for AttemptNo := 1 to 2 do begin
            Clear(RuntimeParam);
            Clear(ResponseBuffer);
            Clear(RequestJson);
            Clear(PlantArray);
            Clear(RequestBody);

            if IsNullGuid(Session."Session GUID") then
                Error('Неможливо отримати Material Configs: GUID сеансу Proktek відсутній.');
            if Session."Plant IDs" = '' then
                Error('Неможливо отримати Material Configs: Proktek не повернув santral_id для сеансу.');

            BuildPlantArray(Session."Plant IDs", PlantArray);
            RequestJson.Add('guid', Format(Session."Session GUID", 0, 4));
            RequestJson.Add('santral_id', PlantArray);
            RequestJson.WriteTo(RequestBody);

            EDSOrchestrator.ExecuteProviderBody(
                Connection."EDS Service Code",
                'GET-MATERIALS-CONFIG',
                Connection."EDS Provider Code",
                RuntimeParam,
                RequestBody,
                'application/json-patch+json',
                'text/plain',
                ResponseBuffer);

            Clear(RequestBody);

            if ResponseBuffer."Result Type" = ResponseBuffer."Result Type"::Success then begin
                ResponseText := ResponseBuffer.GetBodyText();
                exit;
            end;

            if (ResponseBuffer."HTTP Status Code" = 401) and (AttemptNo = 1) then begin
                AuthMgt.RefreshSession(Connection, Session);
                continue;
            end;

            ValidateTransportResponse(ResponseBuffer, 'GetMaterialsConfig');
        end;
    end;

    local procedure ParseMaterialConfig(
        ResponseText: Text;
        var EntCodeByBunker: Dictionary of [Text, Text];
        var MaterialUuidByBunker: Dictionary of [Text, Text];
        var MaterialNameByBunker: Dictionary of [Text, Text])
    var
        ResponseJson: JsonObject;
        ConfigArray: JsonArray;
        ConfigToken: JsonToken;
        ItemToken: JsonToken;
        MaterialToken: JsonToken;
        ConfigJson: JsonObject;
        MaterialJson: JsonObject;
        ResponseStatus: Boolean;
        ResponseMessage: Text;
        PlantId: Integer;
        Bunker: Text;
        EntCode: Text;
        MaterialUuid: Text;
        MaterialName: Text;
        MapKey: Text;
        ExistingEntCode: Text;
        IsActive: Boolean;
        I: Integer;
    begin
        if ResponseText = '' then
            Error('Proktek GetMaterialsConfig повернув порожнє тіло відповіді.');
        if not ResponseJson.ReadFrom(ResponseText) then
            Error('Не вдалося прочитати JSON-відповідь Proktek GetMaterialsConfig.');

        if not TryGetBoolean(ResponseJson, 'responseStatus', ResponseStatus) then
            Error('У відповіді GetMaterialsConfig відсутнє поле responseStatus.');
        TryGetText(ResponseJson, 'responseMessage', ResponseMessage);
        if not ResponseStatus then begin
            if ResponseMessage = '' then
                ResponseMessage := 'Proktek повернув responseStatus=false для GetMaterialsConfig.';
            Error('%1', ResponseMessage);
        end;

        if not ResponseJson.Get('materials_config', ConfigToken) then
            Error('У відповіді GetMaterialsConfig відсутній масив materials_config.');
        if not ConfigToken.IsArray() then
            Error('Поле materials_config у відповіді GetMaterialsConfig не є масивом.');

        ConfigArray := ConfigToken.AsArray();
        for I := 0 to ConfigArray.Count() - 1 do begin
            ConfigArray.Get(I, ItemToken);
            if not ItemToken.IsObject() then
                continue;

            ConfigJson := ItemToken.AsObject();
            Clear(PlantId);
            Clear(Bunker);
            Clear(EntCode);
            Clear(MaterialUuid);
            Clear(MaterialName);
            Clear(IsActive);

            if TryGetBoolean(ConfigJson, 'aktif', IsActive) then
                if not IsActive then
                    continue;

            if not TryGetInteger(ConfigJson, 'santral_id', PlantId) then
                continue;
            if not TryGetText(ConfigJson, 'bunker', Bunker) then
                continue;
            if Bunker = '' then
                continue;

            TryGetText(ConfigJson, 'malzeme_uuid', MaterialUuid);

            if ConfigJson.Get('malzeme', MaterialToken) and MaterialToken.IsObject() then begin
                MaterialJson := MaterialToken.AsObject();
                TryGetText(MaterialJson, 'malzeme_ent_kod', EntCode);
                TryGetText(MaterialJson, 'ad', MaterialName);
                if MaterialUuid = '' then
                    TryGetText(MaterialJson, 'uuid', MaterialUuid);
            end;

            if (MaterialUuid = '') and (EntCode = '') then
                continue;

            // Keep the config row even when ERP code is not filled yet.
            // The export must fail only if that hopper is actually used by a production.
            if EntCode <> '' then
                ValidateEntCode(EntCode);
            MapKey := BuildBunkerKey(PlantId, Bunker);

            Clear(ExistingEntCode);
            if EntCodeByBunker.Get(MapKey, ExistingEntCode) then
                if ExistingEntCode <> EntCode then
                    Error(
                        'Для hopper %1 (santral_id=%2) GetMaterialsConfig повернув кілька активних матеріалів: %3 та %4.',
                        Bunker,
                        PlantId,
                        ExistingEntCode,
                        EntCode);

            EntCodeByBunker.Set(MapKey, EntCode);
            MaterialUuidByBunker.Set(MapKey, MaterialUuid);
            MaterialNameByBunker.Set(MapKey, MaterialName);
        end;
    end;

    local procedure BuildCanonicalProductionFromDetails(
        DetailResponseText: Text;
        ExpectedProductionUuid: Text;
        EntCodeByBunker: Dictionary of [Text, Text];
        MaterialUuidByBunker: Dictionary of [Text, Text];
        MaterialNameByBunker: Dictionary of [Text, Text]): JsonObject
    var
        ResponseJson: JsonObject;
        ProductionToken: JsonToken;
        ProductionJson: JsonObject;
        ResponseStatus: Boolean;
        ResponseMessage: Text;
        ActualProductionUuid: Text;
    begin
        if DetailResponseText = '' then
            Error('GetProductionDetails для %1 повернув порожнє тіло відповіді.', ExpectedProductionUuid);
        if not ResponseJson.ReadFrom(DetailResponseText) then
            Error('Не вдалося прочитати JSON GetProductionDetails для %1.', ExpectedProductionUuid);

        if not TryGetBoolean(ResponseJson, 'responseStatus', ResponseStatus) then
            Error('У GetProductionDetails для %1 відсутнє responseStatus.', ExpectedProductionUuid);
        TryGetText(ResponseJson, 'responseMessage', ResponseMessage);
        if not ResponseStatus then begin
            if ResponseMessage = '' then
                ResponseMessage := StrSubstNo('GetProductionDetails повернув responseStatus=false для %1.', ExpectedProductionUuid);
            Error('%1', ResponseMessage);
        end;

        if not ResponseJson.Get('production', ProductionToken) then
            Error('У GetProductionDetails для %1 відсутній об’єкт production.', ExpectedProductionUuid);
        if not ProductionToken.IsObject() then
            Error('Поле production у GetProductionDetails для %1 не є об’єктом.', ExpectedProductionUuid);

        ProductionJson := ProductionToken.AsObject();
        if not TryGetText(ProductionJson, 'uuid', ActualProductionUuid) then
            Error('GetProductionDetails для %1 повернув production без uuid.', ExpectedProductionUuid);
        if LowerCase(ActualProductionUuid) <> LowerCase(ExpectedProductionUuid) then
            Error(
                'GetProductionDetails повернув інший production uuid. Очікувався %1, отримано %2.',
                ExpectedProductionUuid,
                ActualProductionUuid);

        exit(BuildCanonicalProduction(
            ProductionJson,
            EntCodeByBunker,
            MaterialUuidByBunker,
            MaterialNameByBunker));
    end;

    local procedure BuildCanonicalProduction(
        ProductionJson: JsonObject;
        EntCodeByBunker: Dictionary of [Text, Text];
        MaterialUuidByBunker: Dictionary of [Text, Text];
        MaterialNameByBunker: Dictionary of [Text, Text]): JsonObject
    var
        ResultJson: JsonObject;
        FormulaJson: JsonObject;
        CustomerJson: JsonObject;
        SiteJson: JsonObject;
        TransportJson: JsonObject;
        TruckJson: JsonObject;
        DriverJson: JsonObject;
        DeliveryJson: JsonObject;
        TimingJson: JsonObject;
        OrderJson: JsonObject;
        ServicesJson: JsonArray;
        MaterialsJson: JsonArray;
        HoppersJson: JsonArray;
        NestedFormula: JsonObject;
        FormulaToken: JsonToken;
        ProductionId: Integer;
        PlantId: Integer;
        DeliveryNo: Decimal;
        ProductionUuid: Text;
        DateText: Text;
        TimeText: Text;
        StartDateTime: Text;
        EndDateTime: Text;
        DeliverySeries: Text;
        FormulaUuid: Text;
        FormulaCode: Text;
        FormulaErpCode: Text;
        FormulaName: Text;
        CustomerUuid: Text;
        CustomerCode: Text;
        CustomerName: Text;
        SiteUuid: Text;
        SiteCode: Text;
        SiteName: Text;
        TruckUuid: Text;
        TruckCode: Text;
        TruckPlate: Text;
        DriverUuid: Text;
        DriverName: Text;
        OrderUuid: Text;
        OrderNo: Text;
        OperatorName: Text;
        QuantityM3: Decimal;
        IsAutomatic: Boolean;
        DeliveryPrinted: Boolean;
    begin
        TryGetInteger(ProductionJson, 'kod', ProductionId);
        TryGetInteger(ProductionJson, 'santral_id', PlantId);
        TryGetText(ProductionJson, 'uuid', ProductionUuid);
        TryGetText(ProductionJson, 'tarih', DateText);
        TryGetText(ProductionJson, 'saat', TimeText);
        TryGetDecimal(ProductionJson, 'metrekup', QuantityM3);
        TryGetBoolean(ProductionJson, 'otomatik', IsAutomatic);
        TryGetText(ProductionJson, 'kullanici', OperatorName);
        TryGetText(ProductionJson, 'baslangic_saati', StartDateTime);
        TryGetText(ProductionJson, 'bitis_saati', EndDateTime);

        TryGetText(ProductionJson, 'irsaliye_seri_no', DeliverySeries);
        TryGetDecimal(ProductionJson, 'irsaliye_no', DeliveryNo);
        TryGetBoolean(ProductionJson, 'irsaliye_basildi', DeliveryPrinted);

        TryGetText(ProductionJson, 'recete_uuid', FormulaUuid);
        TryGetText(ProductionJson, 'recete_ad', FormulaName);
        if ProductionJson.Get('recete', FormulaToken) and FormulaToken.IsObject() then begin
            NestedFormula := FormulaToken.AsObject();
            TryGetText(NestedFormula, 'recete_kod', FormulaCode);
            TryGetText(NestedFormula, 'erp_kod', FormulaErpCode);
            if FormulaName = '' then
                TryGetText(NestedFormula, 'ad', FormulaName);
            if FormulaUuid = '' then
                TryGetText(NestedFormula, 'uuid', FormulaUuid);
        end;
        if FormulaCode = '' then
            TryGetText(ProductionJson, 'recete_index', FormulaCode);

        TryGetText(ProductionJson, 'musteri_uuid', CustomerUuid);
        TryGetText(ProductionJson, 'musteri_index', CustomerCode);
        TryGetText(ProductionJson, 'musteri_ad', CustomerName);

        TryGetText(ProductionJson, 'santiye_uuid', SiteUuid);
        TryGetText(ProductionJson, 'santiye_index', SiteCode);
        TryGetText(ProductionJson, 'santiye_ad', SiteName);

        TryGetText(ProductionJson, 'kamyon_uuid', TruckUuid);
        TryGetText(ProductionJson, 'kamyon_index', TruckCode);
        TryGetText(ProductionJson, 'kamyon_plk', TruckPlate);
        TryGetText(ProductionJson, 'surucu_uuid', DriverUuid);
        TryGetText(ProductionJson, 'surucu_ad', DriverName);

        TryGetText(ProductionJson, 'siparis_uuid', OrderUuid);
        TryGetText(ProductionJson, 'sip_no', OrderNo);

        ResultJson.Add('productionId', ProductionId);
        ResultJson.Add('productionUuid', ProductionUuid);
        ResultJson.Add('productionDate', DateText);
        ResultJson.Add('productionTime', TimeText);
        ResultJson.Add('productionDateTime', NormalizeProductionDateTime(DateText, TimeText));
        ResultJson.Add('plantId', PlantId);
        ResultJson.Add('quantityM3', QuantityM3);
        ResultJson.Add('automatic', IsAutomatic);
        ResultJson.Add('operator', OperatorName);

        TimingJson.Add('startedAt', StartDateTime);
        TimingJson.Add('finishedAt', EndDateTime);
        ResultJson.Add('timing', TimingJson);

        DeliveryJson.Add('series', DeliverySeries);
        DeliveryJson.Add('number', DeliveryNo);
        DeliveryJson.Add('printed', DeliveryPrinted);
        ResultJson.Add('deliveryNote', DeliveryJson);

        FormulaJson.Add('uuid', FormulaUuid);
        FormulaJson.Add('code', FormulaCode);
        FormulaJson.Add('erpCode', FormulaErpCode);
        FormulaJson.Add('name', FormulaName);
        ResultJson.Add('formula', FormulaJson);

        CustomerJson.Add('uuid', CustomerUuid);
        CustomerJson.Add('code', CustomerCode);
        CustomerJson.Add('name', CustomerName);
        ResultJson.Add('customer', CustomerJson);

        SiteJson.Add('uuid', SiteUuid);
        SiteJson.Add('code', SiteCode);
        SiteJson.Add('name', SiteName);
        ResultJson.Add('constructionSite', SiteJson);

        TruckJson.Add('uuid', TruckUuid);
        TruckJson.Add('code', TruckCode);
        TruckJson.Add('plate', TruckPlate);
        DriverJson.Add('uuid', DriverUuid);
        DriverJson.Add('name', DriverName);
        TransportJson.Add('truck', TruckJson);
        TransportJson.Add('driver', DriverJson);
        ResultJson.Add('transport', TransportJson);

        OrderJson.Add('uuid', OrderUuid);
        OrderJson.Add('number', OrderNo);
        ResultJson.Add('order', OrderJson);

        AddServices(ProductionJson, ServicesJson);
        ResultJson.Add('services', ServicesJson);

        BuildMaterialsAndHoppers(
            ProductionJson,
            PlantId,
            ProductionUuid,
            EntCodeByBunker,
            MaterialUuidByBunker,
            MaterialNameByBunker,
            MaterialsJson,
            HoppersJson);
        ResultJson.Add('materials', MaterialsJson);
        ResultJson.Add('hoppers', HoppersJson);

        exit(ResultJson);
    end;

    local procedure AddServices(ProductionJson: JsonObject; var ServicesJson: JsonArray)
    var
        I: Integer;
        Uuid: Text;
        Name: Text;
        ServiceJson: JsonObject;
    begin
        for I := 1 to 4 do begin
            Clear(Uuid);
            Clear(Name);
            TryGetText(ProductionJson, StrSubstNo('hizmet%1_uuid', I), Uuid);
            TryGetText(ProductionJson, StrSubstNo('hizmet%1_ad', I), Name);
            if (Uuid = '') and (Name = '') then
                continue;

            Clear(ServiceJson);
            ServiceJson.Add('slot', I);
            ServiceJson.Add('uuid', Uuid);
            ServiceJson.Add('name', Name);
            ServicesJson.Add(ServiceJson);
        end;
    end;

    local procedure BuildMaterialsAndHoppers(
        ProductionJson: JsonObject;
        PlantId: Integer;
        ProductionUuid: Text;
        EntCodeByBunker: Dictionary of [Text, Text];
        MaterialUuidByBunker: Dictionary of [Text, Text];
        MaterialNameByBunker: Dictionary of [Text, Text];
        var MaterialsJson: JsonArray;
        var HoppersJson: JsonArray)
    var
        Bunkers: List of [Text];
        RequestedFields: List of [Text];
        AdjustedFields: List of [Text];
        ActualFields: List of [Text];
        RequestedByEntCode: Dictionary of [Text, Decimal];
        AdjustedByEntCode: Dictionary of [Text, Decimal];
        ActualByEntCode: Dictionary of [Text, Decimal];
        UuidByEntCode: Dictionary of [Text, Text];
        NameByEntCode: Dictionary of [Text, Text];
        EntCodes: List of [Text];
        Bunker: Text;
        RequestedField: Text;
        AdjustedField: Text;
        ActualField: Text;
        MapKey: Text;
        EntCode: Text;
        MaterialUuid: Text;
        MaterialName: Text;
        RequestedKg: Decimal;
        AdjustedKg: Decimal;
        ActualKg: Decimal;
        ExistingValue: Decimal;
        I: Integer;
    begin
        AddProductionMaterialSlots(Bunkers, RequestedFields, AdjustedFields, ActualFields);

        for I := 1 to Bunkers.Count() do begin
            Bunkers.Get(I, Bunker);
            RequestedFields.Get(I, RequestedField);
            AdjustedFields.Get(I, AdjustedField);
            ActualFields.Get(I, ActualField);

            Clear(RequestedKg);
            Clear(AdjustedKg);
            Clear(ActualKg);
            if RequestedField <> '' then
                TryGetDecimal(ProductionJson, RequestedField, RequestedKg);
            if AdjustedField <> '' then
                TryGetDecimal(ProductionJson, AdjustedField, AdjustedKg)
            else
                AdjustedKg := RequestedKg;
            if ActualField <> '' then
                TryGetDecimal(ProductionJson, ActualField, ActualKg);

            if (RequestedKg = 0) and (AdjustedKg = 0) and (ActualKg = 0) then
                continue;

            MapKey := BuildBunkerKey(PlantId, Bunker);
            if not EntCodeByBunker.Get(MapKey, EntCode) then
                Error(
                    'Не знайдено Material Config для hopper %1 (santral_id=%2) у production %3. План=%4 кг, скоригований план=%5 кг, факт=%6 кг.',
                    Bunker,
                    PlantId,
                    ProductionUuid,
                    RequestedKg,
                    AdjustedKg,
                    ActualKg);

            if EntCode = '' then
                Error('Для hopper %1 (santral_id=%2) не визначено malzeme_ent_kod.', Bunker, PlantId);

            Clear(MaterialUuid);
            Clear(MaterialName);
            MaterialUuidByBunker.Get(MapKey, MaterialUuid);
            MaterialNameByBunker.Get(MapKey, MaterialName);

            AddHopperFact(
                HoppersJson,
                Bunker,
                EntCode,
                MaterialUuid,
                MaterialName,
                RequestedKg,
                AdjustedKg,
                ActualKg);

            if RequestedByEntCode.Get(EntCode, ExistingValue) then
                RequestedByEntCode.Set(EntCode, ExistingValue + RequestedKg)
            else begin
                RequestedByEntCode.Add(EntCode, RequestedKg);
                AdjustedByEntCode.Add(EntCode, 0);
                ActualByEntCode.Add(EntCode, 0);
                UuidByEntCode.Add(EntCode, MaterialUuid);
                NameByEntCode.Add(EntCode, MaterialName);
            end;

            AdjustedByEntCode.Get(EntCode, ExistingValue);
            AdjustedByEntCode.Set(EntCode, ExistingValue + AdjustedKg);
            ActualByEntCode.Get(EntCode, ExistingValue);
            ActualByEntCode.Set(EntCode, ExistingValue + ActualKg);
        end;

        EntCodes := RequestedByEntCode.Keys();
        foreach EntCode in EntCodes do begin
            RequestedByEntCode.Get(EntCode, RequestedKg);
            AdjustedByEntCode.Get(EntCode, AdjustedKg);
            ActualByEntCode.Get(EntCode, ActualKg);
            UuidByEntCode.Get(EntCode, MaterialUuid);
            NameByEntCode.Get(EntCode, MaterialName);

            AddCanonicalMaterial(
                MaterialsJson,
                EntCode,
                MaterialUuid,
                MaterialName,
                RequestedKg,
                AdjustedKg,
                ActualKg);
        end;
    end;

    local procedure AddHopperFact(
        var HoppersJson: JsonArray;
        Bunker: Text;
        EntCode: Text;
        MaterialUuid: Text;
        MaterialName: Text;
        RequestedKg: Decimal;
        AdjustedKg: Decimal;
        ActualKg: Decimal)
    var
        HopperJson: JsonObject;
        ItemNo: Text;
        VariantCode: Text;
    begin
        ParseEntCode(EntCode, ItemNo, VariantCode);

        HopperJson.Add('hopper', Bunker);
        HopperJson.Add('materialUuid', MaterialUuid);
        HopperJson.Add('entCode', EntCode);
        HopperJson.Add('itemNo', ItemNo);
        HopperJson.Add('variantCode', VariantCode);
        HopperJson.Add('materialName', MaterialName);
        HopperJson.Add('requestedKg', RequestedKg);
        HopperJson.Add('adjustedKg', AdjustedKg);
        HopperJson.Add('actualKg', ActualKg);
        HoppersJson.Add(HopperJson);
    end;

    local procedure AddCanonicalMaterial(
        var MaterialsJson: JsonArray;
        EntCode: Text;
        MaterialUuid: Text;
        MaterialName: Text;
        RequestedKg: Decimal;
        AdjustedKg: Decimal;
        ActualKg: Decimal)
    var
        MaterialJson: JsonObject;
        ItemNo: Text;
        VariantCode: Text;
    begin
        ParseEntCode(EntCode, ItemNo, VariantCode);

        MaterialJson.Add('uuid', MaterialUuid);
        MaterialJson.Add('entCode', EntCode);
        MaterialJson.Add('itemNo', ItemNo);
        MaterialJson.Add('variantCode', VariantCode);
        MaterialJson.Add('name', MaterialName);
        MaterialJson.Add('requestedKg', RequestedKg);
        MaterialJson.Add('adjustedKg', AdjustedKg);
        MaterialJson.Add('actualKg', ActualKg);
        MaterialsJson.Add(MaterialJson);
    end;

    local procedure AddProductionMaterialSlots(
        var Bunkers: List of [Text];
        var RequestedFields: List of [Text];
        var AdjustedFields: List of [Text];
        var ActualFields: List of [Text])
    begin
        AddSlot(Bunkers, RequestedFields, AdjustedFields, ActualFields, 'agrega1', 'agrega1_ist', 'agrega1_tart', 'agrega1_ver');
        AddSlot(Bunkers, RequestedFields, AdjustedFields, ActualFields, 'agrega2', 'agrega2_ist', 'agrega2_tart', 'agrega2_ver');
        AddSlot(Bunkers, RequestedFields, AdjustedFields, ActualFields, 'agrega3', 'agrega3_ist', 'agrega3_tart', 'agrega3_ver');
        AddSlot(Bunkers, RequestedFields, AdjustedFields, ActualFields, 'agrega4', 'agrega4_ist', 'agrega4_tart', 'agrega4_ver');
        AddSlot(Bunkers, RequestedFields, AdjustedFields, ActualFields, 'agrega5', 'agrega5_ist', 'agrega5_tart', 'agrega5_ver');
        AddSlot(Bunkers, RequestedFields, AdjustedFields, ActualFields, 'agrega6', 'agrega6_ist', 'agrega6_tart', 'agrega6_ver');
        AddSlot(Bunkers, RequestedFields, AdjustedFields, ActualFields, 'agrega7', 'agrega7_ist', 'agrega7_tart', 'agrega7_ver');
        AddSlot(Bunkers, RequestedFields, AdjustedFields, ActualFields, 'agrega8', 'agrega8_ist', 'agrega8_tart', 'agrega8_ver');
        AddSlot(Bunkers, RequestedFields, AdjustedFields, ActualFields, 'cimento1', 'cimento1_ist', '', 'cimento1_ver');
        AddSlot(Bunkers, RequestedFields, AdjustedFields, ActualFields, 'cimento2', 'cimento2_ist', '', 'cimento2_ver');
        AddSlot(Bunkers, RequestedFields, AdjustedFields, ActualFields, 'cimento3', 'cimento3_ist', '', 'cimento3_ver');
        AddSlot(Bunkers, RequestedFields, AdjustedFields, ActualFields, 'cimento4', 'cimento4_ist', '', 'cimento4_ver');
        AddSlot(Bunkers, RequestedFields, AdjustedFields, ActualFields, 'su1', 'su1_ist', 'su1_tart', 'su1_ver');
        AddSlot(Bunkers, RequestedFields, AdjustedFields, ActualFields, 'su2', 'su2_ist', 'su2_tart', 'su2_ver');
        AddSlot(Bunkers, RequestedFields, AdjustedFields, ActualFields, 'katki1', 'katki1_ist', '', 'katki1_ver');
        AddSlot(Bunkers, RequestedFields, AdjustedFields, ActualFields, 'katki2', 'katki2_ist', '', 'katki2_ver');
        AddSlot(Bunkers, RequestedFields, AdjustedFields, ActualFields, 'katki3', 'katki3_ist', '', 'katki3_ver');
        AddSlot(Bunkers, RequestedFields, AdjustedFields, ActualFields, 'katki4', 'katki4_ist', '', 'katki4_ver');
        AddSlot(Bunkers, RequestedFields, AdjustedFields, ActualFields, 'extra1', 'extra1_ist', '', 'extra1_ver');
        AddSlot(Bunkers, RequestedFields, AdjustedFields, ActualFields, 'extra2', 'extra2_ist', '', 'extra2_ver');
    end;

    local procedure AddSlot(
        var Bunkers: List of [Text];
        var RequestedFields: List of [Text];
        var AdjustedFields: List of [Text];
        var ActualFields: List of [Text];
        Bunker: Text;
        RequestedField: Text;
        AdjustedField: Text;
        ActualField: Text)
    begin
        Bunkers.Add(Bunker);
        RequestedFields.Add(RequestedField);
        AdjustedFields.Add(AdjustedField);
        ActualFields.Add(ActualField);
    end;

    local procedure ParseEntCode(EntCode: Text; var ItemNo: Text; var VariantCode: Text)
    var
        SeparatorPos: Integer;
        Tail: Text;
    begin
        Clear(ItemNo);
        Clear(VariantCode);
        ValidateEntCode(EntCode);

        SeparatorPos := StrPos(EntCode, '|');
        if SeparatorPos = 0 then begin
            ItemNo := EntCode;
            exit;
        end;

        ItemNo := CopyStr(EntCode, 1, SeparatorPos - 1);
        Tail := CopyStr(EntCode, SeparatorPos + 1);
        VariantCode := Tail;
    end;

    local procedure ValidateEntCode(EntCode: Text)
    var
        SeparatorPos: Integer;
        Tail: Text;
    begin
        if EntCode = '' then
            Error('malzeme_ent_kod не може бути порожнім.');

        SeparatorPos := StrPos(EntCode, '|');
        if SeparatorPos = 0 then
            exit;

        if SeparatorPos = 1 then
            Error('Некоректний malzeme_ent_kod %1: Item No. відсутній.', EntCode);

        Tail := CopyStr(EntCode, SeparatorPos + 1);
        if Tail = '' then
            Error('Некоректний malzeme_ent_kod %1: Variant Code відсутній.', EntCode);
        if StrPos(Tail, '|') > 0 then
            Error('Некоректний malzeme_ent_kod %1: дозволено не більше одного роздільника |.', EntCode);
    end;

    local procedure BuildBunkerKey(PlantId: Integer; Bunker: Text): Text
    begin
        exit(Format(PlantId) + '|' + LowerCase(Bunker));
    end;

    local procedure BuildPlantArray(PlantIdsText: Text; var PlantArray: JsonArray)
    var
        PlantIds: List of [Text];
        PlantIdText: Text;
        PlantId: Integer;
    begin
        PlantIds := PlantIdsText.Split(',');
        foreach PlantIdText in PlantIds do begin
            PlantIdText := DelChr(PlantIdText, '<>', ' ');
            if PlantIdText = '' then
                continue;
            if not Evaluate(PlantId, PlantIdText) then
                Error('Некоректний santral_id у сесії Proktek: %1.', PlantIdText);
            PlantArray.Add(PlantId);
        end;

        if PlantArray.Count() = 0 then
            Error('Не вдалося сформувати santral_id для GetMaterialsConfig.');
    end;

    local procedure NormalizeProductionDateTime(DateText: Text; TimeText: Text): Text
    var
        DayText: Text;
        MonthText: Text;
        YearText: Text;
    begin
        if StrLen(DateText) >= 10 then begin
            DayText := CopyStr(DateText, 1, 2);
            MonthText := CopyStr(DateText, 4, 2);
            YearText := CopyStr(DateText, 7, 4);
            if (CopyStr(DateText, 3, 1) = '.') and (CopyStr(DateText, 6, 1) = '.') then
                exit(YearText + '-' + MonthText + '-' + DayText + 'T' + TimeText);
        end;

        exit(DateText + 'T' + TimeText);
    end;

    local procedure BuildFileName(Value: DateTime): Text
    begin
        exit(
            StrSubstNo(
                'Beton_Prod_%1_%2.json',
                Format(DT2Date(Value), 0, '<Year4><Month,2><Day,2>'),
                Format(DT2Time(Value), 0, '<Hours24,2><Minutes,2><Seconds,2>')));
    end;

    local procedure ValidateConnection(ConnectionCode: Code[50])
    var
        Connection: Record "SI Prok Connection";
    begin
        if ConnectionCode = '' then
            Error('Потрібно вибрати профіль підключення Proktek.');
        if not Connection.Get(ConnectionCode) then
            Error('Профіль підключення Proktek %1 не знайдено.', ConnectionCode);

        Connection.TestField("EDS Service Code");
        Connection.TestField("EDS Provider Code");
        Connection.TestField("EDS Login Operation");
    end;

    local procedure ValidatePeriod(DateFrom: Date; DateTo: Date)
    begin
        if DateFrom = 0D then
            Error('Дата з не може бути порожньою.');
        if DateTo = 0D then
            Error('Дата по не може бути порожньою.');
        if DateTo < DateFrom then
            Error('Дата по не може бути раніше за дату з.');
    end;

    local procedure ValidateTransportResponse(
        var ResponseBuffer: Record "SI EDS Response Buffer" temporary;
        OperationName: Text)
    var
        ResponseBody: Text;
    begin
        if ResponseBuffer."Result Type" = ResponseBuffer."Result Type"::Success then
            exit;

        ResponseBody := ResponseBuffer.GetBodyText();
        if ResponseBody = '' then
            ResponseBody := '<порожнє тіло відповіді>';

        Error(
            'Запит Proktek %1 завершився транспортною помилкою.\' +
            '\' +
            'HTTP Status = %2\' +
            'HTTP Reason = %3\' +
            'Blocked By BC Environment = %4\' +
            'EDS Result = %5\' +
            'EDS Error = %6\' +
            '\' +
            'Request URL = %7\' +
            'HTTP Method = %8\' +
            'Content-Type = %9\' +
            '\' +
            'Response Body:\' +
            '%10',
            OperationName,
            ResponseBuffer."HTTP Status Code",
            ResponseBuffer."HTTP Reason Phrase",
            ResponseBuffer."Blocked By Environment",
            Format(ResponseBuffer."Result Type"),
            ResponseBuffer."Error Message",
            ResponseBuffer."Request URL",
            Format(ResponseBuffer."Request Method"),
            ResponseBuffer."Request Content Type",
            ResponseBody);
    end;

    local procedure TryGetText(Json: JsonObject; PropertyName: Text; var Value: Text): Boolean
    var
        Token: JsonToken;
    begin
        Clear(Value);
        if not Json.Get(PropertyName, Token) then
            exit(false);
        if not Token.IsValue() then
            exit(false);
        if Token.AsValue().IsNull() then
            exit(false);
        Value := Token.AsValue().AsText();
        exit(true);
    end;

    local procedure TryGetBoolean(Json: JsonObject; PropertyName: Text; var Value: Boolean): Boolean
    var
        Token: JsonToken;
    begin
        Clear(Value);
        if not Json.Get(PropertyName, Token) then
            exit(false);
        if not Token.IsValue() then
            exit(false);
        if Token.AsValue().IsNull() then
            exit(false);
        Value := Token.AsValue().AsBoolean();
        exit(true);
    end;

    local procedure TryGetInteger(Json: JsonObject; PropertyName: Text; var Value: Integer): Boolean
    var
        Token: JsonToken;
    begin
        Clear(Value);
        if not Json.Get(PropertyName, Token) then
            exit(false);
        if not Token.IsValue() then
            exit(false);
        if Token.AsValue().IsNull() then
            exit(false);
        Value := Token.AsValue().AsInteger();
        exit(true);
    end;

    local procedure TryGetDecimal(Json: JsonObject; PropertyName: Text; var Value: Decimal): Boolean
    var
        Token: JsonToken;
    begin
        Clear(Value);
        if not Json.Get(PropertyName, Token) then
            exit(false);
        if not Token.IsValue() then
            exit(false);
        if Token.AsValue().IsNull() then
            exit(false);
        Value := Token.AsValue().AsDecimal();
        exit(true);
    end;
}
