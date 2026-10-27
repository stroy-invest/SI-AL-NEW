codeunit 63002 "SI Geo Routing Parser"
{
    Access = Internal;

    procedure ParseRoute(ResponseJson: Text; var DistanceMeters: Decimal; var DurationSeconds: Decimal)
    var
        Root: JsonObject;
        FeaturesToken: JsonToken;
        Features: JsonArray;
        FeatureToken: JsonToken;
        Feature: JsonObject;
        PropertiesToken: JsonToken;
        Properties: JsonObject;
        ValueToken: JsonToken;
    begin
        Clear(DistanceMeters);
        Clear(DurationSeconds);
        if ResponseJson.Trim() = '' then
            Error('Geoapify повернув порожнє тіло маршруту.');
        if not Root.ReadFrom(ResponseJson) then
            Error('Відповідь маршрутизації Geoapify не є коректним JSON.');
        if not Root.Get('features', FeaturesToken) then
            Error('У відповіді маршрутизації відсутній features.');
        if not FeaturesToken.IsArray() then
            Error('Поле features не є масивом.');
        Features := FeaturesToken.AsArray();
        if Features.Count() = 0 then
            Error('Geoapify не повернув жодного маршруту.');
        Features.Get(0, FeatureToken);
        if not FeatureToken.IsObject() then
            Error('Некоректний об’єкт маршруту Geoapify.');
        Feature := FeatureToken.AsObject();
        if not Feature.Get('properties', PropertiesToken) then
            Error('У маршруті відсутній properties.');
        if not PropertiesToken.IsObject() then
            Error('Некоректний properties маршруту.');
        Properties := PropertiesToken.AsObject();
        if not Properties.Get('distance', ValueToken) then
            Error('У маршруті відсутня відстань (distance).');
        if not ValueToken.IsValue() then
            Error('Некоректний тип distance.');
        if ValueToken.AsValue().IsNull() then
            Error('Відстань маршруту не визначена.');
        DistanceMeters := ValueToken.AsValue().AsDecimal();
        if not Properties.Get('time', ValueToken) then
            Error('У маршруті відсутній час (time).');
        if not ValueToken.IsValue() then
            Error('Некоректний тип time.');
        if ValueToken.AsValue().IsNull() then
            Error('Час маршруту не визначений.');
        DurationSeconds := ValueToken.AsValue().AsDecimal();
        if (DistanceMeters < 0) or (DurationSeconds < 0) then
            Error('Geoapify повернув від’ємну відстань або час маршруту.');
    end;


    procedure ExtractRouteGeoJson(ResponseJson: Text): Text
    var
        Root: JsonObject;
        FeaturesToken: JsonToken;
        Features: JsonArray;
        FeatureToken: JsonToken;
        Feature: JsonObject;
        GeometryToken: JsonToken;
        Geometry: JsonObject;
        TypeToken: JsonToken;
        CoordinatesToken: JsonToken;
        GeometryType: Text;
        FeatureCollection: JsonObject;
        RouteFeatures: JsonArray;
        ResultJson: Text;
    begin
        if not Root.ReadFrom(ResponseJson) then
            Error('Відповідь Geoapify не є коректним JSON.');
        if not Root.Get('features', FeaturesToken) then
            Error('Geoapify не повернув features.');
        if not FeaturesToken.IsArray() then
            Error('Geoapify не повернув масив features.');
        Features := FeaturesToken.AsArray();
        if Features.Count() = 0 then
            Error('Geoapify не повернув маршрут.');
        Features.Get(0, FeatureToken);
        if not FeatureToken.IsObject() then
            Error('Некоректний GeoJSON Feature.');
        Feature := FeatureToken.AsObject();
        if not Feature.Get('geometry', GeometryToken) then
            Error('У відповіді Geoapify відсутня геометрія маршруту.');
        if not GeometryToken.IsObject() then
            Error('У відповіді Geoapify відсутня геометрія маршруту.');
        Geometry := GeometryToken.AsObject();
        if not Geometry.Get('type', TypeToken) then
            Error('У геометрії маршруту відсутній type.');
        if not TypeToken.IsValue() then
            Error('У геометрії маршруту відсутній type.');
        GeometryType := TypeToken.AsValue().AsText();
        if (GeometryType <> 'LineString') and (GeometryType <> 'MultiLineString') then
            Error('Непідтримуваний тип геометрії: %1.', GeometryType);
        if not Geometry.Get('coordinates', CoordinatesToken) then
            Error('Геометрія маршруту не містить coordinates.');
        if not CoordinatesToken.IsArray() then
            Error('Геометрія маршруту не містить coordinates.');
        RouteFeatures.Add(FeatureToken);
        FeatureCollection.Add('type', 'FeatureCollection');
        FeatureCollection.Add('features', RouteFeatures);
        FeatureCollection.WriteTo(ResultJson);
        exit(ResultJson);
    end;
}
