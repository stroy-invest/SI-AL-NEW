codeunit 63001 "SI Geo Response Parser"
{
    Access = Internal;

    procedure ParseForwardResponse(
        ResponseJson: Text;
        var ResultCount: Integer;
        var FormattedAddress: Text;
        var Latitude: Decimal;
        var Longitude: Decimal;
        var CoordinatesAvailable: Boolean)
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
        Clear(ResultCount);
        Clear(FormattedAddress);
        Clear(Latitude);
        Clear(Longitude);
        Clear(CoordinatesAvailable);

        if ResponseJson.Trim() = '' then
            Error('Geoapify повернув порожнє тіло відповіді.');

        if not Root.ReadFrom(ResponseJson) then
            Error('Відповідь Geoapify не є коректним JSON.');

        if not Root.Get('features', FeaturesToken) then
            Error('У відповіді Geoapify відсутній масив features.');

        if not FeaturesToken.IsArray() then
            Error('Поле features має некоректний тип.');

        Features := FeaturesToken.AsArray();
        ResultCount := Features.Count();

        if ResultCount = 0 then
            exit;

        Features.Get(0, FeatureToken);

        if not FeatureToken.IsObject() then
            Error('Перший результат Geoapify має некоректний формат.');

        Feature := FeatureToken.AsObject();

        if not Feature.Get('properties', PropertiesToken) then
            Error('У першому результаті Geoapify відсутній properties.');

        if not PropertiesToken.IsObject() then
            Error('Поле properties має некоректний тип.');

        Properties := PropertiesToken.AsObject();

        if Properties.Get('formatted', ValueToken) then
            if ValueToken.IsValue() then
                if not ValueToken.AsValue().IsNull() then
                    FormattedAddress := ValueToken.AsValue().AsText();

        if not Properties.Get('lat', ValueToken) then
            exit;

        if not ValueToken.IsValue() then
            exit;

        if ValueToken.AsValue().IsNull() then
            exit;

        Latitude := ValueToken.AsValue().AsDecimal();

        if not Properties.Get('lon', ValueToken) then
            exit;

        if not ValueToken.IsValue() then
            exit;

        if ValueToken.AsValue().IsNull() then
            exit;

        Longitude := ValueToken.AsValue().AsDecimal();

        if (Latitude < -90) or (Latitude > 90) then
            Error('Geoapify повернув широту поза допустимим діапазоном.');

        if (Longitude < -180) or (Longitude > 180) then
            Error('Geoapify повернув довготу поза допустимим діапазоном.');

        CoordinatesAvailable := true;
    end;
}