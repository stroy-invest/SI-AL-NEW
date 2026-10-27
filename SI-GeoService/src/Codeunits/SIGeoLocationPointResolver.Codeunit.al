codeunit 63004 "SI Geo Point Resolver"
{
    procedure ResolveOrigin(LocationCode: Code[10]; PointCode: Code[20]; var Latitude: Decimal; var Longitude: Decimal)
    var
        GeoPoint: Record "SI Geo Location Point";
    begin
        if LocationCode = '' then
            Error('Виберіть склад відправлення.');

        if PointCode = '' then begin
            GeoPoint.SetRange("Location Code", LocationCode);
            GeoPoint.SetRange("Default Point", true);
            GeoPoint.SetRange(Active, true);
            if not GeoPoint.FindFirst() then
                Error('Для складу %1 не визначено активну точку за замовчуванням. Виберіть конкретну точку.', LocationCode);
        end else
            if not GeoPoint.Get(LocationCode, PointCode) then
                Error('Географічну точку %1 складу %2 не знайдено.', PointCode, LocationCode);

        if not GeoPoint.Active then
            Error('Географічна точка %1 неактивна.', GeoPoint."Point Code");
        if not GeoPoint.Verified then
            Error('Координати точки %1 не позначені як перевірені.', GeoPoint."Point Code");
        if GeoPoint."Point Type" <> GeoPoint."Point Type"::"Exit" then
            Error('Для початку маршруту доставки потрібна точка типу «Виїзд». Точка %1 має інший тип.', GeoPoint."Point Code");
        if (GeoPoint.Latitude < -90) or (GeoPoint.Latitude > 90) or
           (GeoPoint.Longitude < -180) or (GeoPoint.Longitude > 180) or
           ((GeoPoint.Latitude = 0) and (GeoPoint.Longitude = 0)) then
            Error('Точка %1 має некоректні або незаповнені координати.', GeoPoint."Point Code");

        Latitude := GeoPoint.Latitude;
        Longitude := GeoPoint.Longitude;
    end;
}
