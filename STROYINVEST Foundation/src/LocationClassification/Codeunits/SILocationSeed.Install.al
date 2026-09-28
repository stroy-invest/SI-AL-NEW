codeunit 50505 "SI Location Seed"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    begin
        EnsureLocationType('FG', 'Склад ГП', 10);
        EnsureLocationType('MAIN', 'Основний склад', 20);
        EnsureLocationType('MATERIAL', 'Склад матеріалів', 30);
        EnsureLocationType('METAL', 'Склад металовиробів і прокату', 40);
        EnsureLocationType('FUEL', 'Склад ПММ', 50);
        EnsureLocationType('PROJECT', 'Склад проєкту', 60);
        EnsureLocationType('DEPARTMENT', 'Склад підрозділу', 70);
        EnsureLocationType('VEHICLE', 'Склад ТЗ', 80);
        EnsureSetup();
    end;

    local procedure EnsureLocationType(TypeCode: Code[20]; TypeDescription: Text[100]; SortOrder: Integer)
    var
        LocationType: Record "SI Location Type";
    begin
        if LocationType.Get(TypeCode) then
            exit;
        LocationType.Init();
        LocationType.Code := TypeCode;
        LocationType.Description := TypeDescription;
        LocationType.Active := true;
        LocationType."Sort Order" := SortOrder;
        LocationType.Insert(true);
    end;

    local procedure EnsureSetup()
    var
        LocationSetup: Record "SI Location Setup";
    begin
        if not LocationSetup.Get() then begin
            LocationSetup.Init();
            LocationSetup.Insert(true);
        end;

        if LocationSetup."Finished Goods Type" = '' then LocationSetup."Finished Goods Type" := 'FG';
        if LocationSetup."Main Warehouse Type" = '' then LocationSetup."Main Warehouse Type" := 'MAIN';
        if LocationSetup."Material Warehouse Type" = '' then LocationSetup."Material Warehouse Type" := 'MATERIAL';
        if LocationSetup."Metal Warehouse Type" = '' then LocationSetup."Metal Warehouse Type" := 'METAL';
        if LocationSetup."Fuel Warehouse Type" = '' then LocationSetup."Fuel Warehouse Type" := 'FUEL';
        if LocationSetup."Project Location Type" = '' then LocationSetup."Project Location Type" := 'PROJECT';
        if LocationSetup."Department Location Type" = '' then LocationSetup."Department Location Type" := 'DEPARTMENT';
        if LocationSetup."Vehicle Location Type" = '' then LocationSetup."Vehicle Location Type" := 'VEHICLE';
        LocationSetup.Modify(true);
    end;
}
