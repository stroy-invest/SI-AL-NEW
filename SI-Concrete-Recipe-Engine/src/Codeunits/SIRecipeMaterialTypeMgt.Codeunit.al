namespace STROYINVEST.ConcreteRecipeEngine;

using Microsoft.Inventory.Item;

codeunit 62210 "SI Recipe Material Type Mgt."
{
    procedure GetAttributeId(): Integer
    var
        Attribute: Record Microsoft.Inventory.Item.Attribute."Item Attribute";
    begin
        Attribute.SetRange("SI Semantic Code", 'REC_MAT_TYPE');
        if not Attribute.FindFirst() then
            Error(MissingSemanticErr);
        exit(Attribute.ID);
    end;

    procedure GetEffectiveValueId(CategoryCode: Code[20]): Integer
    var
        Category: Record "Item Category";
        Mapping: Record Microsoft.Inventory.Item.Attribute."Item Attribute Value Mapping";
        AttributeId: Integer;
        CurrentCode: Code[20];
        Depth: Integer;
    begin
        AttributeId := GetAttributeId();
        CurrentCode := CategoryCode;
        while CurrentCode <> '' do begin
            Mapping.Reset();
            Mapping.SetRange("Table ID", Database::"Item Category");
            Mapping.SetRange("No.", CurrentCode);
            Mapping.SetRange("Item Attribute ID", AttributeId);
            if Mapping.FindFirst() then
                exit(Mapping."Item Attribute Value ID");

            if not Category.Get(CurrentCode) then
                exit(0);
            CurrentCode := Category."Parent Category";
            Depth += 1;
            if Depth > 100 then
                Error(CategoryCycleErr, CategoryCode);
        end;
        exit(0);
    end;

    procedure ValidateMaterialValue(ValueId: Integer)
    var
        AttributeValue: Record Microsoft.Inventory.Item.Attribute."Item Attribute Value";
    begin
        if ValueId = 0 then
            exit;
        if not AttributeValue.Get(GetAttributeId(), ValueId) then
            Error(InvalidValueErr, ValueId);
    end;

    procedure ValidateItem(MaterialValueId: Integer; ItemNo: Code[20])
    var
        Item: Record Item;
    begin
        if (MaterialValueId = 0) or (ItemNo = '') then
            exit;
        ValidateMaterialValue(MaterialValueId);
        Item.Get(ItemNo);
        if GetEffectiveValueId(Item."Item Category Code") <> MaterialValueId then
            Error(ItemTypeMismatchErr, ItemNo, Item."Item Category Code");
    end;

    procedure LookupMaterialType(var ValueId: Integer): Boolean
    var
        Values: Record Microsoft.Inventory.Item.Attribute."Item Attribute Value";
    begin
        Values.SetRange("Attribute ID", GetAttributeId());
        if Page.RunModal(Page::Microsoft.Inventory.Item.Attribute."Item Attribute Values", Values) <> Action::LookupOK then
            exit(false);
        ValueId := Values.ID;
        exit(true);
    end;

    procedure LookupItem(MaterialValueId: Integer; var ItemNo: Code[20]): Boolean
    var
        Item: Record Item;
        SelectedItem: Record Item;
        HasMatches: Boolean;
    begin
        if MaterialValueId = 0 then
            Error(ChooseTypeFirstErr);
        ValidateMaterialValue(MaterialValueId);

        if Item.FindSet() then
            repeat
                if GetEffectiveValueId(Item."Item Category Code") = MaterialValueId then begin
                    Item.Mark(true);
                    HasMatches := true;
                end;
            until Item.Next() = 0;

        if not HasMatches then
            exit(false);

        Item.MarkedOnly(true);
        if Page.RunModal(Page::"Item List", Item) <> Action::LookupOK then
            exit(false);
        ItemNo := Item."No.";
        if not SelectedItem.Get(ItemNo) then
            exit(false);
        ValidateItem(MaterialValueId, ItemNo);
        exit(true);
    end;

    var
        MissingSemanticErr: Label 'Не знайдено атрибут товару із семантикою REC_MAT_TYPE.';
        InvalidValueErr: Label 'Значення типу матеріалу %1 не належить атрибуту REC_MAT_TYPE.';
        ItemTypeMismatchErr: Label 'Товар %1 (категорія %2) не відповідає вибраному типу матеріалу рецептури.';
        ChooseTypeFirstErr: Label 'Спочатку виберіть тип матеріалу рецептури.';
        CategoryCycleErr: Label 'Перевищено допустиму глибину ієрархії категорії %1.';
}
