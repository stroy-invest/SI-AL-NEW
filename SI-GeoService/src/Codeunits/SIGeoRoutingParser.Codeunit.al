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
}
