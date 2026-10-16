namespace STROYINVEST.ConcreteRecipeEngine;

using Microsoft.Inventory.Item;

codeunit 62211 "SI Recipe Cement Mfr Mgt."
{
    procedure ValidateManufacturer(ManufacturerCode: Code[20])
    var
        Manufacturer: Record "SI Manufacturer";
    begin
        if ManufacturerCode = '' then
            exit;
        if not Manufacturer.Get(ManufacturerCode) then
            Error(UnknownManufacturerErr, ManufacturerCode);
        if Manufacturer.Blocked then
            Error(BlockedManufacturerErr, ManufacturerCode);
        if not IsAllowedManufacturer(ManufacturerCode) then
            Error(NotAllowedManufacturerErr, ManufacturerCode);
    end;

    procedure LookupManufacturer(var ManufacturerCode: Code[20]): Boolean
    var
        Manufacturer: Record "SI Manufacturer";
        HasMatches: Boolean;
    begin
        Manufacturer.SetRange(Blocked, false);
        if Manufacturer.FindSet() then
            repeat
                if IsAllowedManufacturer(Manufacturer.Code) then begin
                    Manufacturer.Mark(true);
                    HasMatches := true;
                end;
            until Manufacturer.Next() = 0;
        if not HasMatches then
            exit(false);
        Manufacturer.SetRange(Blocked);
        Manufacturer.MarkedOnly(true);
        if Page.RunModal(Page::"SI Manufacturers", Manufacturer) <> Action::LookupOK then
            exit(false);
        ValidateManufacturer(Manufacturer.Code);
        ManufacturerCode := Manufacturer.Code;
        exit(true);
    end;

    local procedure IsAllowedManufacturer(ManufacturerCode: Code[20]): Boolean
    var
        Category: Record "Item Category";
        ParentCategory: Record "Item Category";
        CategoryManufacturer: Record "SI Category Manufacturer";
        MaterialTypeMgt: Codeunit "SI Recipe Material Type Mgt.";
        AttributeValue: Record Microsoft.Inventory.Item.Attribute."Item Attribute Value";
        CementValueId: Integer;
        ParentCode: Code[20];
        Depth: Integer;
    begin
        AttributeValue.SetRange("Attribute ID", MaterialTypeMgt.GetAttributeId());
        AttributeValue.SetRange(Value, CementValueTxt);
        if not AttributeValue.FindFirst() then
            Error(MissingCementValueErr);
        CementValueId := AttributeValue.ID;

        if Category.FindSet() then
            repeat
                if MaterialTypeMgt.GetEffectiveValueId(Category.Code) = CementValueId then begin
                    // Category-specific mapping may be defined at the category itself
                    // or at one of its parent categories.
                    ParentCode := Category.Code;
                    Depth := 0;
                    while ParentCode <> '' do begin
                        if (MaterialTypeMgt.GetEffectiveValueId(ParentCode) = CementValueId) and
                           CategoryManufacturer.Get(ParentCode, ManufacturerCode) then
                            exit(true);
                        if not ParentCategory.Get(ParentCode) then
                            break;
                        ParentCode := ParentCategory."Parent Category";
                        Depth += 1;
                        if Depth > 100 then
                            Error(CategoryCycleErr);
                    end;
                end;
            until Category.Next() = 0;
        exit(false);
    end;

    var
        CementValueTxt: Label 'ЦЕМЕНТ', Locked = true;
        MissingCementValueErr: Label 'У REC_MAT_TYPE немає значення ЦЕМЕНТ.';
        UnknownManufacturerErr: Label 'Виробника %1 не знайдено.';
        BlockedManufacturerErr: Label 'Виробника %1 заблоковано.';
        NotAllowedManufacturerErr: Label 'Виробника %1 не дозволено для категорій цементу.';
        CategoryCycleErr: Label 'Перевищено допустиму глибину ієрархії категорій.';
}
