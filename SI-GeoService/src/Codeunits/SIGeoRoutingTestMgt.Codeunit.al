codeunit 63003 "SI Geo Routing Test Mgt."
{
    Access = Internal;

    procedure TestRoute(FromLatitude: Decimal; FromLongitude: Decimal; ToLatitude: Decimal; ToLongitude: Decimal;
        var HttpStatus: Integer; var ResultText: Text; var CorrelationId: Guid;
        var DistanceMeters: Decimal; var DurationSeconds: Decimal; var RouteGeoJson: Text)
    var
        EnvironmentInformation: Codeunit "Environment Information";
        Orchestrator: Codeunit "SI EDS Orchestrator";
        Parser: Codeunit "SI Geo Routing Parser";
        RuntimeParam: Record "SI EDS Runtime Param" temporary;
        ResponseBuffer: Record "SI EDS Response Buffer" temporary;
        Waypoints: Text;
    begin
        if not EnvironmentInformation.IsSandbox() then
            Error('Тестування маршрутизації дозволене лише в Sandbox.');
        ValidateCoordinate(FromLatitude, FromLongitude);
        ValidateCoordinate(ToLatitude, ToLongitude);
        if (FromLatitude = ToLatitude) and (FromLongitude = ToLongitude) then
            Error('Точки початку й завершення маршруту збігаються.');
        Clear(HttpStatus);
        Clear(ResultText);
        Clear(CorrelationId);
        Clear(DistanceMeters);
        Clear(DurationSeconds);
        Clear(RouteGeoJson);
        // Geoapify: latitude,longitude|latitude,longitude; invariant decimal separator.
        Waypoints := Format(FromLatitude, 0, 9) + ',' + Format(FromLongitude, 0, 9) + '|' +
            Format(ToLatitude, 0, 9) + ',' + Format(ToLongitude, 0, 9);
        RuntimeParam.Add('WAYPOINTS', Waypoints);
        Orchestrator.Execute('GEO', 'ROUTE-CALCULATE', RuntimeParam, ResponseBuffer);
        if not ResponseBuffer.FindFirst() then
            Error('EDS не повернув результат маршрутизації.');
        HttpStatus := ResponseBuffer."HTTP Status Code";
        ResultText := Format(ResponseBuffer."Result Type");
        CorrelationId := ResponseBuffer."Correlation ID";
        if (HttpStatus < 200) or (HttpStatus >= 300) then
            exit;
        Parser.ParseRoute(ResponseBuffer.GetBodyText(), DistanceMeters, DurationSeconds);
        RouteGeoJson := Parser.ExtractRouteGeoJson(ResponseBuffer.GetBodyText());
    end;

    local procedure ValidateCoordinate(Latitude: Decimal; Longitude: Decimal)
    begin
        if (Latitude < -90) or (Latitude > 90) then
            Error('Широта повинна бути в межах -90..90.');
        if (Longitude < -180) or (Longitude > 180) then
            Error('Довгота повинна бути в межах -180..180.');
        if (Latitude = 0) and (Longitude = 0) then
            Error('Координати 0,0 не допускаються для цього тесту.');
    end;
}
