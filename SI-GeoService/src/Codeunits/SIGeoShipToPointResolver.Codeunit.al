codeunit 63005 "SI Geo Ship-to Resolver"
{
    procedure ResolveDestination(CustomerNo: Code[20]; ShipToCode: Code[10]; PointCode: Code[20]; var Latitude: Decimal; var Longitude: Decimal)
    var
        ShipTo: Record "Ship-to Address";
        GeoPoint: Record "SI Geo Ship-to Point";
    begin
        if (CustomerNo = '') or (ShipToCode = '') then
            Error('Виберіть клієнта та адресу доставки.');
        if not ShipTo.Get(CustomerNo, ShipToCode) then
            Error('Адресу доставки %1 клієнта %2 не знайдено.', ShipToCode, CustomerNo);
        if PointCode = '' then begin
            GeoPoint.SetRange("Customer No.", CustomerNo);
            GeoPoint.SetRange("Ship-to Code", ShipToCode);
            GeoPoint.SetRange("Default Point", true);
            GeoPoint.SetRange(Active, true);
            if not GeoPoint.FindFirst() then
                Error('Для адреси доставки %1 клієнта %2 немає активної точки за замовчуванням.', ShipToCode, CustomerNo);
        end else
            if not GeoPoint.Get(CustomerNo, ShipToCode, PointCode) then
                Error('Точку %1 адреси %2 клієнта %3 не знайдено.', PointCode, ShipToCode, CustomerNo);
        if not GeoPoint.Active then
            Error('Географічна точка %1 неактивна.', GeoPoint."Point Code");
        if not GeoPoint.Verified then
            Error('Координати точки %1 не перевірені.', GeoPoint."Point Code");
        if (GeoPoint."Point Type" <> GeoPoint."Point Type"::Entrance) and
           (GeoPoint."Point Type" <> GeoPoint."Point Type"::Unloading) then
            Error('Точка доставки повинна мати тип «В’їзд» або «Розвантаження».');
        if (GeoPoint.Latitude < -90) or (GeoPoint.Latitude > 90) or
           (GeoPoint.Longitude < -180) or (GeoPoint.Longitude > 180) or
           ((GeoPoint.Latitude = 0) and (GeoPoint.Longitude = 0)) then
            Error('Точка %1 має некоректні координати.', GeoPoint."Point Code");
        Latitude := GeoPoint.Latitude;
        Longitude := GeoPoint.Longitude;
    end;
}
