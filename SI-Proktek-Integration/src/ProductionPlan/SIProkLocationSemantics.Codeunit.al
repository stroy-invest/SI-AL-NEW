codeunit 57137 "SI Prok Location Semantics"
{
    // Shared Foundation location-type contract. Never hardcode WH-MAT/WH-CON.
    procedure ResolveMaterialWarehouse(var MaterialLocation: Record Location)
    var
        Setup: Record "SI Location Setup";
        Resolver: Codeunit "SI Location Resolver";
        LocationCode: Code[10];
    begin
        GetSetup(Setup);
        Setup.TestField("Material Warehouse Type");
        LocationCode := Resolver.AssertResolve(Setup."Material Warehouse Type", '', '');
        MaterialLocation.Get(LocationCode);
    end;

    procedure ResolveFinishedGoodsWarehouse(var FinishedLocation: Record Location)
    var
        Resolver: Codeunit "SI Location Resolver";
        LocationCode: Code[10];
        Reason: Text;
    begin
        if not Resolver.TryResolveFinishedGoods('', '', LocationCode, Reason) then
            Error('Proktek: %1', Reason);
        FinishedLocation.Get(LocationCode);
    end;

    procedure AssertMaterial(LocationCode: Code[10])
    var
        Setup: Record "SI Location Setup";
        Resolver: Codeunit "SI Location Resolver";
    begin
        GetSetup(Setup);
        Setup.TestField("Material Warehouse Type");
        Resolver.AssertResolve(Setup."Material Warehouse Type", '', LocationCode);
    end;

    procedure AssertFinishedGoods(LocationCode: Code[10])
    var
        Resolver: Codeunit "SI Location Resolver";
        ResolvedCode: Code[10];
        Reason: Text;
    begin
        if not Resolver.TryResolveFinishedGoods('', LocationCode, ResolvedCode, Reason) then
            Error('Proktek: %1', Reason);
    end;

    local procedure GetSetup(var Setup: Record "SI Location Setup")
    begin
        if not Setup.Get('') then
            Error('Proktek: відсутні налаштування семантики складів SI Location Setup.');
    end;
}
