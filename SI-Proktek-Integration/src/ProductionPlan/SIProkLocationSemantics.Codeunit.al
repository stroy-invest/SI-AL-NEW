codeunit 57137 "SI Prok Location Semantics"
{
    // Shared Foundation location-type contract. Never hardcode WH-MAT/WH-CON.
    procedure ResolveMaterialWarehouse(var MaterialLocation: Record Location)
    var
        Setup: Record "SI Location Setup";
    begin
        GetSetup(Setup);
        Setup.TestField("Material Warehouse Type");
        MaterialLocation.Reset();
        MaterialLocation.SetRange("SI Location Type Code", Setup."Material Warehouse Type");
        if not MaterialLocation.FindFirst() then
            Error('Proktek: не знайдено складу матеріалів із семантичним типом %1.', Setup."Material Warehouse Type");
        if MaterialLocation.Next() <> 0 then
            Error('Proktek: знайдено декілька складів матеріалів із типом %1; автоматичний вибір заборонено.', Setup."Material Warehouse Type");
        MaterialLocation.FindFirst();
    end;

    procedure ResolveFinishedGoodsWarehouse(var FinishedLocation: Record Location)
    var
        Setup: Record "SI Location Setup";
    begin
        GetSetup(Setup);
        Setup.TestField("Finished Goods Type");
        FinishedLocation.Reset();
        FinishedLocation.SetRange("SI Location Type Code", Setup."Finished Goods Type");
        if not FinishedLocation.FindFirst() then
            Error('Proktek: не знайдено складу готової продукції з типом %1.', Setup."Finished Goods Type");
        if FinishedLocation.Next() <> 0 then
            Error('Proktek: знайдено декілька складів готової продукції з типом %1; автоматичний вибір заборонено.', Setup."Finished Goods Type");
        FinishedLocation.FindFirst();
    end;

    procedure AssertMaterial(LocationCode: Code[10])
    var
        Setup: Record "SI Location Setup";
        Loc: Record Location;
    begin
        GetSetup(Setup);
        Setup.TestField("Material Warehouse Type");
        if not Loc.Get(LocationCode) then
            Error('Proktek: склад матеріалів %1 не знайдено.', LocationCode);
        if Loc."SI Location Type Code" <> Setup."Material Warehouse Type" then
            Error('Proktek: компонент використовує склад %1 (тип %2), очікується тип матеріального складу %3.',
                Loc.Code, Loc."SI Location Type Code", Setup."Material Warehouse Type");
    end;

    procedure AssertFinishedGoods(LocationCode: Code[10])
    var
        Setup: Record "SI Location Setup";
        Loc: Record Location;
    begin
        GetSetup(Setup);
        Setup.TestField("Finished Goods Type");
        if not Loc.Get(LocationCode) then
            Error('Proktek: склад готової продукції %1 не знайдено.', LocationCode);
        if Loc."SI Location Type Code" <> Setup."Finished Goods Type" then
            Error('Proktek: Output використовує склад %1 (тип %2), очікується тип складу ГП %3.',
                Loc.Code, Loc."SI Location Type Code", Setup."Finished Goods Type");
    end;

    local procedure GetSetup(var Setup: Record "SI Location Setup")
    begin
        if not Setup.Get('') then
            Error('Proktek: відсутні налаштування семантики складів SI Location Setup.');
    end;
}
