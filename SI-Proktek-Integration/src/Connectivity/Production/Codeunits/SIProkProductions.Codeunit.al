codeunit 57056 "SI Prok Productions"
{
    procedure GetPage(
        var Connection: Record "SI Prok Connection";
        StartDate: Date;
        EndDate: Date;
        PerPage: Integer;
        PageNo: Integer;
        HideDetails: Boolean;
        TotalStatistic: Boolean;
        var ResponseText: Text)
    var
        Session: Record "SI Prok Session";
        RuntimeParam: Record "SI EDS Runtime Param" temporary;
        ResponseBuffer: Record "SI EDS Response Buffer" temporary;
        AuthMgt: Codeunit "SI Prok Auth Mgt.";
        EDSOrchestrator: Codeunit "SI EDS Orchestrator";
        RequestBody: Text;
    begin
        ValidateConnection(Connection);

        if StartDate = 0D then
            Error('Дата з не може бути порожньою.');
        if EndDate = 0D then
            Error('Дата по не може бути порожньою.');
        if EndDate < StartDate then
            Error('Дата по не може бути раніше за дату з.');
        if PerPage <= 0 then
            Error('Кількість записів на сторінку має бути більшою за нуль.');
        if PageNo <= 0 then
            Error('Номер сторінки має бути більшим за нуль.');

        AuthMgt.EnsureSession(
            Connection,
            Session);

        ExecuteGetProductionsWithReauth(
            Connection,
            Session,
            StartDate,
            EndDate,
            PerPage,
            PageNo,
            HideDetails,
            TotalStatistic,
            ResponseText);
    end;

    local procedure ExecuteGetProductionsWithReauth(
        var Connection: Record "SI Prok Connection";
        var Session: Record "SI Prok Session";
        StartDate: Date;
        EndDate: Date;
        PerPage: Integer;
        PageNo: Integer;
        HideDetails: Boolean;
        TotalStatistic: Boolean;
        var ResponseText: Text)
    var
        RuntimeParam: Record "SI EDS Runtime Param" temporary;
        ResponseBuffer: Record "SI EDS Response Buffer" temporary;
        AuthMgt: Codeunit "SI Prok Auth Mgt.";
        EDSOrchestrator: Codeunit "SI EDS Orchestrator";
        RequestBody: Text;
        AttemptNo: Integer;
    begin
        for AttemptNo := 1 to 2 do begin
            Clear(RuntimeParam);
            Clear(ResponseBuffer);

            RequestBody :=
                BuildRequestBody(
                    Session,
                    StartDate,
                    EndDate,
                    PerPage,
                    PageNo,
                    HideDetails,
                    TotalStatistic);

            EDSOrchestrator.ExecuteProviderBody(
                Connection."EDS Service Code",
                'GET-PRODUCTIONS',
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

            ValidateTransportResponse(ResponseBuffer);
        end;
    end;

    procedure GetDetails(
        var Connection: Record "SI Prok Connection";
        ProductionUuid: Text;
        FindReturnedProduction: Boolean;
        var ResponseText: Text)
    var
        Session: Record "SI Prok Session";
        AuthMgt: Codeunit "SI Prok Auth Mgt.";
    begin
        ValidateConnection(Connection);

        if ProductionUuid = '' then
            Error('Production UUID не може бути порожнім.');

        AuthMgt.EnsureSession(Connection, Session);

        ExecuteGetProductionDetailsWithReauth(
            Connection,
            Session,
            ProductionUuid,
            FindReturnedProduction,
            ResponseText);
    end;

    local procedure ExecuteGetProductionDetailsWithReauth(
        var Connection: Record "SI Prok Connection";
        var Session: Record "SI Prok Session";
        ProductionUuid: Text;
        FindReturnedProduction: Boolean;
        var ResponseText: Text)
    var
        RuntimeParam: Record "SI EDS Runtime Param" temporary;
        ResponseBuffer: Record "SI EDS Response Buffer" temporary;
        AuthMgt: Codeunit "SI Prok Auth Mgt.";
        EDSOrchestrator: Codeunit "SI EDS Orchestrator";
        RequestJson: JsonObject;
        RequestBody: Text;
        AttemptNo: Integer;
        ReauthUsed: Boolean;
        MaxAttempts: Integer;
    begin
        // Proktek throttles Production Details to 4 requests per 2 seconds.
        // Export pacing should normally avoid 429; this retry is the safety net.
        MaxAttempts := 6;
        ReauthUsed := false;

        for AttemptNo := 1 to MaxAttempts do begin
            Clear(RuntimeParam);
            Clear(ResponseBuffer);
            Clear(RequestJson);
            Clear(RequestBody);

            if IsNullGuid(Session."Session GUID") then
                Error('Неможливо виконати GetProductionDetails: GUID сеансу відсутній.');

            RequestJson.Add('guid', Format(Session."Session GUID", 0, 4));
            RequestJson.Add('geri_donen_bul', FindReturnedProduction);
            RequestJson.Add('production_uuid', ProductionUuid);
            RequestJson.WriteTo(RequestBody);

            EDSOrchestrator.ExecuteProviderBody(
                Connection."EDS Service Code",
                'GET-PRODUCTION-DETAILS',
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

            if (ResponseBuffer."HTTP Status Code" = 401) and (not ReauthUsed) then begin
                AuthMgt.RefreshSession(Connection, Session);
                ReauthUsed := true;
                continue;
            end;

            if (ResponseBuffer."HTTP Status Code" = 429) and (AttemptNo < MaxAttempts) then begin
                // API currently reports: 4 requests / 2 s and asks to retry in 1 s.
                // Use a small safety margin instead of immediately failing the whole export.
                Sleep(1100);
                continue;
            end;

            ValidateDetailsTransportResponse(ResponseBuffer, ProductionUuid);
        end;
    end;

    local procedure ValidateDetailsTransportResponse(
        var ResponseBuffer: Record "SI EDS Response Buffer" temporary;
        ProductionUuid: Text)
    var
        ResponseBody: Text;
    begin
        if ResponseBuffer."Result Type" = ResponseBuffer."Result Type"::Success then
            exit;

        ResponseBody := ResponseBuffer.GetBodyText();
        if ResponseBody = '' then
            ResponseBody := '<порожнє тіло відповіді>';

        Error(
            'Запит Proktek GetProductionDetails для production_uuid=%1 завершився транспортною помилкою.\' +
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
            ProductionUuid,
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

    procedure ExecuteToday(
        var Connection: Record "SI Prok Connection";
        var SummaryText: Text;
        var FirstProductionText: Text)
    var
        Session: Record "SI Prok Session";
        RuntimeParam: Record "SI EDS Runtime Param" temporary;
        ResponseBuffer: Record "SI EDS Response Buffer" temporary;
        AuthMgt: Codeunit "SI Prok Auth Mgt.";
        EDSOrchestrator: Codeunit "SI EDS Orchestrator";
        RequestBody: Text;
        ResponseText: Text;
    begin
        ValidateConnection(Connection);

        AuthMgt.EnsureSession(
            Connection,
            Session);

        RequestBody :=
            BuildRequestBody(
                Session,
                Today,
                Today,
                100,
                1,
                false,
                true);

        EDSOrchestrator.ExecuteProviderBody(
            Connection."EDS Service Code",
            'GET-PRODUCTIONS',
            Connection."EDS Provider Code",
            RuntimeParam,
            RequestBody,
            'application/json-patch+json',
            'text/plain',
            ResponseBuffer);

        Clear(RequestBody);

        ValidateTransportResponse(ResponseBuffer);

        ResponseText := ResponseBuffer.GetBodyText();
        ParseResponse(
            ResponseText,
            SummaryText,
            FirstProductionText);
    end;

    local procedure ValidateConnection(
        Connection: Record "SI Prok Connection")
    begin
        Connection.TestField(Code);
        Connection.TestField("EDS Service Code");
        Connection.TestField("EDS Provider Code");
        Connection.TestField("EDS Prod. Operation");
    end;

    local procedure BuildRequestBody(
        Session: Record "SI Prok Session";
        StartDate: Date;
        EndDate: Date;
        PerPage: Integer;
        PageNo: Integer;
        HideDetails: Boolean;
        TotalStatistic: Boolean): Text
    var
        RequestJson: JsonObject;
        RequestBody: Text;
    begin
        if IsNullGuid(Session."Session GUID") then
            Error('Неможливо виконати GetProductions: GUID сеансу відсутній.');

        // Keep the GetProductions request intentionally minimal.
        // santral_id is not sent: Proktek resolves the available/default plant itself.
        // hide_details and total_statistic are also omitted because the API defaults
        // already return the payload and statistics required by the exporter.
        RequestJson.Add(
            'guid',
            Format(
                Session."Session GUID",
                0,
                4));
        RequestJson.Add(
            'startDate',
            FormatDateTime(StartDate, false));
        RequestJson.Add(
            'endDate',
            FormatDateTime(EndDate, true));
        RequestJson.Add(
            'perpage',
            PerPage);
        RequestJson.Add(
            'page',
            PageNo);

        RequestJson.WriteTo(RequestBody);
        exit(RequestBody);
    end;

    local procedure FormatDateTime(
        Value: Date;
        EndOfDay: Boolean): Text
    var
        DateText: Text;
    begin
        DateText := Format(Value, 0, '<Year4>-<Month,2>-<Day,2>');

        if EndOfDay then
            exit(DateText + 'T23:59:59');

        exit(DateText + 'T00:00:00');
    end;

    local procedure ValidateTransportResponse(
        var ResponseBuffer: Record "SI EDS Response Buffer" temporary)
    var
        ResponseBody: Text;
    begin
        if ResponseBuffer."Result Type" =
           ResponseBuffer."Result Type"::Success
        then
            exit;

        ResponseBody := ResponseBuffer.GetBodyText();
        if ResponseBody = '' then
            ResponseBody := '<порожнє тіло відповіді>';

        Error(
            'Запит Proktek GetProductions завершився транспортною помилкою.\' +
            '\' +
            'HTTP Status = %1\' +
            'HTTP Reason = %2\' +
            'Blocked By BC Environment = %3\' +
            'EDS Result = %4\' +
            'EDS Error = %5\' +
            '\' +
            'Request URL = %6\' +
            'HTTP Method = %7\' +
            'Content-Type = %8\' +
            '\' +
            'Response Body:\' +
            '%9',
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

    local procedure ParseResponse(
        ResponseText: Text;
        var SummaryText: Text;
        var FirstProductionText: Text)
    var
        ResponseJson: JsonObject;
        Productions: JsonArray;
        Token: JsonToken;
        ProductionToken: JsonToken;
        ResponseStatus: Boolean;
        ResponseMessage: Text;
        TotalRecords: Integer;
        TotalPages: Integer;
        ProductionCount: Integer;
        TotalMeterCubes: Decimal;
    begin
        Clear(SummaryText);
        Clear(FirstProductionText);

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

        TryGetInteger(ResponseJson, 'totalrecords', TotalRecords);
        TryGetInteger(ResponseJson, 'totalpages', TotalPages);
        TryGetDecimal(ResponseJson, 'totalmetercubes', TotalMeterCubes);

        if ResponseJson.Get('productions', Token) and Token.IsArray() then begin
            Productions := Token.AsArray();
            ProductionCount := Productions.Count();

            if ProductionCount > 0 then begin
                Productions.Get(0, ProductionToken);
                ProductionToken.WriteTo(FirstProductionText);
            end;
        end;

        SummaryText :=
            StrSubstNo(
                'GET-PRODUCTIONS успішно. Записів за статистикою: %1; у масиві productions: %2; сторінок: %3; обсяг: %4 м³.',
                TotalRecords,
                ProductionCount,
                TotalPages,
                TotalMeterCubes);
    end;

    local procedure TryGetText(
        Json: JsonObject;
        PropertyName: Text;
        var Value: Text): Boolean
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

    local procedure TryGetBoolean(
        Json: JsonObject;
        PropertyName: Text;
        var Value: Boolean): Boolean
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

    local procedure TryGetInteger(
        Json: JsonObject;
        PropertyName: Text;
        var Value: Integer): Boolean
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

    local procedure TryGetDecimal(
        Json: JsonObject;
        PropertyName: Text;
        var Value: Decimal): Boolean
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
