codeunit 61096 "SI Supply Geo Mgt"
{
    // SR-GEO-02A: geographic point selection only; routing is SR-GEO-02B.
    procedure CheckDepartureLocation(LocationCode: Code[10])
    var
        Location: Record Location;
        Setup: Record "SI Location Setup";
    begin
        if LocationCode = '' then
            exit;
        Location.Get(LocationCode);
        if not Setup.Get() then
            Error('Не налаштовано семантичні типи складів.');
        Setup.TestField("Finished Goods Type");
        if Location."SI Location Type Code" <> Setup."Finished Goods Type" then
            Error('Склад %1 має тип %2, очікується %3.', LocationCode, Location."SI Location Type Code", Setup."Finished Goods Type");
    end;

    procedure DefaultPoint(LocationCode: Code[10]; var PointCode: Code[20])
    var
        Point: Record "SI Geo Location Point";
    begin
        PointCode := '';
        if LocationCode = '' then
            exit;
        Point.SetRange("Location Code", LocationCode);
        Point.SetRange(Active, true);
        Point.SetRange("Default Point", true);
        if Point.FindFirst() then
            PointCode := Point."Point Code";
    end;

    procedure CheckPoint(LocationCode: Code[10]; PointCode: Code[20]; IsDeparture: Boolean)
    var
        Point: Record "SI Geo Location Point";
    begin
        if PointCode = '' then
            exit;
        if LocationCode = '' then
            Error('Спочатку виберіть склад.');
        if not Point.Get(LocationCode, PointCode) then
            Error('Точка %1 не належить складу %2.', PointCode, LocationCode);
        if not Point.Active then
            Error('Географічна точка %1 неактивна.', PointCode);
        if IsDeparture and (Point."Point Type" <> Point."Point Type"::"Exit") then
            Error('Для відправлення потрібна точка типу «Виїзд».');
        // Verified coordinates are mandatory at routing stage, not for draft editing.
    end;
}
