codeunit 57057 "SI Prok Operation Test"
{
    procedure ExecuteCurrent(
        var Connection: Record "SI Prok Connection";
        var SummaryText: Text;
        var ResponsePreview: Text)
    var
        Session: Record "SI Prok Session";
        RuntimeParam: Record "SI EDS Runtime Param" temporary;
        ResponseBuffer: Record "SI EDS Response Buffer" temporary;
        AuthMgt: Codeunit "SI Prok Auth Mgt.";
        EDSOrchestrator: Codeunit "SI EDS Orchestrator";
        RequestBody: Text;
        ResponseText: Text;
        OperationCode: Code[50];
    begin
        ValidateConnection(Connection);

        OperationCode := Connection."EDS Prod. Operation";

        AuthMgt.EnsureSession(
            Connection,
            Session);

        RequestBody :=
            BuildRequestBody(
                Connection,
                OperationCode,
                Session);

        EDSOrchestrator.ExecuteProviderBody(
            Connection."EDS Service Code",
            OperationCode,
            Connection."EDS Provider Code",
            RuntimeParam,
            RequestBody,
            'application/json-patch+json',
            'text/plain',
            ResponseBuffer);

        Clear(RequestBody);

        ValidateTransportResponse(
            OperationCode,
            ResponseBuffer);

        ResponseText := ResponseBuffer.GetBodyText();

        ParseGenericResponse(
            OperationCode,
            ResponseBuffer."HTTP Status Code",
            ResponseText,
            SummaryText,
            ResponsePreview);
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
        Connection: Record "SI Prok Connection";
        OperationCode: Code[50];
        Session: Record "SI Prok Session"): Text
    var
        CustomPayload: Text;
    begin
        if IsNullGuid(Session."Session GUID") then
            Error('Неможливо виконати тест операції %1: GUID сеансу Proktek відсутній.', OperationCode);

        CustomPayload := Connection.GetTestPayload();
        if CustomPayload <> '' then
            exit(BuildCustomRequestBody(CustomPayload, Session, OperationCode));

        case OperationCode of
            'GET-PRODUCTIONS':
                exit(BuildProductionsRequest(Session));

            'GET-PRODUCTIONS-LIVE',
            'GET-ALL-PRODUCTIONS':
                exit(BuildGuidPlantsRequest(Session, OperationCode));

            'COMPANY-INFO',
            'CLIENT-LIST',
            'HUB-LIST',
            'GET-CUSTOMER-NAMES',
            'GET-SUPPLIER-NAMES',
            'GET-DRIVER-NAMES',
            'GET-FORMULA-NAMES',
            'GET-FORMULA-GROUPS',
            'GET-FUEL-STATION-NAMES',
            'GET-ALL-MIXER-NAMES',
            'GET-FUEL-OIL',
            'GET-SAMPLE-SIZES',
            'GET-MATERIALS',
            'GET-MIXER-NAMES',
            'GET-SCALES',
            'GET-IP-ADDRESS':
                exit(BuildGuidOnlyRequest(Session));

            'GET-PRODUCTION-DETAILS':
                Error(
                    'Операція %1 потребує production_uuid. Для універсального тесту UUID ще не задано. Спочатку отримай хоча б один запис через GET-PRODUCTIONS або GET-ALL-PRODUCTIONS.',
                    OperationCode);

            else
                Error(
                    'Для операції %1 ще не описано тестовий request body. Операція є в EDS, але її параметри треба додати до SI Prok Operation Test відповідно до Swagger.',
                    OperationCode);
        end;
    end;

    local procedure BuildCustomRequestBody(
        CustomPayload: Text;
        Session: Record "SI Prok Session";
        OperationCode: Code[50]): Text
    var
        RequestJson: JsonObject;
        RequestBody: Text;
    begin
        if not RequestJson.ReadFrom(CustomPayload) then
            Error(
                'Payload для операції %1 не є коректним JSON object.',
                OperationCode);

        // Session GUID належить connection/session context, а не тестовому payload.
        // Якщо користувач випадково передав guid у JSON, завжди замінюємо його
        // актуальним GUID поточного успішного сеансу.
        if RequestJson.Contains('guid') then
            RequestJson.Remove('guid');

        AddGuid(
            RequestJson,
            Session."Session GUID");

        RequestJson.WriteTo(RequestBody);
        exit(RequestBody);
    end;

    local procedure BuildGuidOnlyRequest(
        Session: Record "SI Prok Session"): Text
    var
        RequestJson: JsonObject;
        RequestBody: Text;
    begin
        AddGuid(
            RequestJson,
            Session."Session GUID");

        RequestJson.WriteTo(RequestBody);
        exit(RequestBody);
    end;

    local procedure BuildGuidPlantsRequest(
        Session: Record "SI Prok Session";
        OperationCode: Code[50]): Text
    var
        RequestJson: JsonObject;
        PlantArray: JsonArray;
        RequestBody: Text;
    begin
        if Session."Plant IDs" = '' then
            Error(
                'Неможливо виконати тест операції %1: Proktek не повернув santral_id для поточного сеансу.',
                OperationCode);

        AddGuid(
            RequestJson,
            Session."Session GUID");

        BuildPlantArray(
            Session."Plant IDs",
            PlantArray);

        RequestJson.Add(
            'santral_id',
            PlantArray);

        RequestJson.WriteTo(RequestBody);
        exit(RequestBody);
    end;

    local procedure BuildProductionsRequest(
        Session: Record "SI Prok Session"): Text
    var
        RequestJson: JsonObject;
        PlantArray: JsonArray;
        RequestBody: Text;
    begin
        if Session."Plant IDs" = '' then
            Error('Неможливо виконати GET-PRODUCTIONS: Proktek не повернув santral_id для поточного сеансу.');

        AddGuid(
            RequestJson,
            Session."Session GUID");

        BuildPlantArray(
            Session."Plant IDs",
            PlantArray);

        RequestJson.Add(
            'startDate',
            FormatDateTime(Today, false));
        RequestJson.Add(
            'endDate',
            FormatDateTime(Today, true));
        RequestJson.Add(
            'santral_id',
            PlantArray);
        RequestJson.Add(
            'perpage',
            100);
        RequestJson.Add(
            'page',
            1);
        RequestJson.Add(
            'hide_details',
            false);
        RequestJson.Add(
            'total_statistic',
            true);

        RequestJson.WriteTo(RequestBody);
        exit(RequestBody);
    end;

    local procedure AddGuid(
        var RequestJson: JsonObject;
        SessionGuid: Guid)
    begin
        RequestJson.Add(
            'guid',
            Format(
                SessionGuid,
                0,
                4));
    end;

    local procedure BuildPlantArray(
        PlantIdsText: Text;
        var PlantArray: JsonArray)
    var
        PlantIds: List of [Text];
        PlantIdText: Text;
        PlantId: Integer;
    begin
        Clear(PlantArray);
        PlantIds := PlantIdsText.Split(',');

        foreach PlantIdText in PlantIds do begin
            PlantIdText := DelChr(PlantIdText, '<>', ' ');
            if not Evaluate(PlantId, PlantIdText) then
                Error('Некоректний santral_id у сеансі Proktek: %1.', PlantIdText);

            PlantArray.Add(PlantId);
        end;

        if PlantArray.Count() = 0 then
            Error('Не вдалося сформувати список santral_id для тестового запиту Proktek.');
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
        OperationCode: Code[50];
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
            'Операція Proktek %1 завершилась транспортною помилкою.\' +
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
            OperationCode,
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

    local procedure ParseGenericResponse(
        OperationCode: Code[50];
        HttpStatusCode: Integer;
        ResponseText: Text;
        var SummaryText: Text;
        var ResponsePreview: Text)
    var
        ResponseJson: JsonObject;
        Token: JsonToken;
        ResponseStatus: Boolean;
        ResponseMessage: Text;
        Productions: JsonArray;
        TotalRecords: Integer;
        TotalPages: Integer;
        TotalMeterCubes: Decimal;
        HasJson: Boolean;
    begin
        Clear(SummaryText);
        Clear(ResponsePreview);

        if ResponseText = '' then begin
            SummaryText :=
                StrSubstNo(
                    '%1 успішно. HTTP %2; тіло відповіді порожнє.',
                    OperationCode,
                    HttpStatusCode);
            exit;
        end;

        ResponsePreview := CopyStr(ResponseText, 1, 12000);
        if StrLen(ResponseText) > 12000 then
            ResponsePreview += '\... [response truncated]';

        HasJson := ResponseJson.ReadFrom(ResponseText);
        if not HasJson then begin
            SummaryText :=
                StrSubstNo(
                    '%1 успішно на транспортному рівні. HTTP %2; відповідь не є JSON.',
                    OperationCode,
                    HttpStatusCode);
            exit;
        end;

        if TryGetBoolean(ResponseJson, 'responseStatus', ResponseStatus) then begin
            TryGetText(ResponseJson, 'responseMessage', ResponseMessage);

            if not ResponseStatus then begin
                if ResponseMessage = '' then
                    ResponseMessage :=
                        StrSubstNo(
                            'Proktek повернув responseStatus=false для %1.',
                            OperationCode);
                Error('%1', ResponseMessage);
            end;
        end;

        if OperationCode = 'GET-PRODUCTIONS' then begin
            TryGetInteger(ResponseJson, 'totalrecords', TotalRecords);
            TryGetInteger(ResponseJson, 'totalpages', TotalPages);
            TryGetDecimal(ResponseJson, 'totalmetercubes', TotalMeterCubes);

            if ResponseJson.Get('productions', Token) and Token.IsArray() then
                Productions := Token.AsArray();

            SummaryText :=
                StrSubstNo(
                    '%1 успішно. HTTP %2; записів за статистикою: %3; у productions: %4; сторінок: %5; обсяг: %6 м³.',
                    OperationCode,
                    HttpStatusCode,
                    TotalRecords,
                    Productions.Count(),
                    TotalPages,
                    TotalMeterCubes);
            exit;
        end;

        if (OperationCode = 'GET-PRODUCTIONS-LIVE') or
           (OperationCode = 'GET-ALL-PRODUCTIONS')
        then begin
            if ResponseJson.Get('productions', Token) and Token.IsArray() then
                Productions := Token.AsArray();

            TryGetInteger(ResponseJson, 'totalrecords', TotalRecords);

            SummaryText :=
                StrSubstNo(
                    '%1 успішно. HTTP %2; у productions: %3; totalrecords: %4.',
                    OperationCode,
                    HttpStatusCode,
                    Productions.Count(),
                    TotalRecords);
            exit;
        end;

        SummaryText :=
            StrSubstNo(
                '%1 успішно. HTTP %2. Raw JSON показано нижче.',
                OperationCode,
                HttpStatusCode);
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
