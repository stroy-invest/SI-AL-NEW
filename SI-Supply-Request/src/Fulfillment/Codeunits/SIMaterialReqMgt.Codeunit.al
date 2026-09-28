codeunit 61014 "SI Material Req. Mgt."
{
    procedure Calculate(var Allocation: Record "SI Supply Allocation")
    var
        RecipeMgt: Codeunit "SI Supply Recipe Mgt.";
        Recipe: Record "SI Concrete Recipe";
        RecipeRevision: Record "SI Concrete Recipe Revision";
        RecipeLine: Record "SI Concrete Recipe Line";
        MaterialReq: Record "SI Supply Material Req.";
        MaterialLocation: Record Location;
        ProcurementLine: Record "SI Procurement Line";
        CheckedAt: DateTime;
        HasShortage: Boolean;
        NextLineNo: Integer;
    begin
        ValidateContext(Allocation);

        // Revalidate the selected revision immediately before using it for planning.
        RecipeMgt.RevalidateForExecution(Allocation);
        Allocation.Get(Allocation."Decision No.", Allocation."Decision Line No.", Allocation."Line No.");
        Allocation.TestField("Recipe Resolution Status", Allocation."Recipe Resolution Status"::Resolved);
        Allocation.TestField("Selected Recipe No.");
        if Allocation."Selected Revision No." = 0 then
            Error(NoRevisionErr);

        Recipe.Get(Allocation."Selected Recipe No.");
        Recipe.TestField("Output Quantity");
        RecipeRevision.Get(Allocation."Selected Recipe No.", Allocation."Selected Revision No.");
        if not RecipeRevision.IsApplicable(DT2Date(Allocation."Required on Site At")) then
            Error(RevisionNotApplicableErr, Allocation."Selected Recipe No.", Allocation."Selected Revision No.");

        ResolveMaterialWarehouse(MaterialLocation);
        CheckedAt := CurrentDateTime();

        ProcurementLine.SetRange("Decision No.", Allocation."Decision No.");
        ProcurementLine.SetRange("Decision Line No.", Allocation."Decision Line No.");
        ProcurementLine.SetRange("Allocation Line No.", Allocation."Line No.");
        if not ProcurementLine.IsEmpty() then
            Error(ProcurementPreparedErr);

        MaterialReq.SetRange("Decision No.", Allocation."Decision No.");
        MaterialReq.SetRange("Decision Line No.", Allocation."Decision Line No.");
        MaterialReq.SetRange("Allocation Line No.", Allocation."Line No.");
        MaterialReq.DeleteAll();

        RecipeLine.SetRange("Recipe No.", Allocation."Selected Recipe No.");
        RecipeLine.SetRange("Revision No.", Allocation."Selected Revision No.");
        if not RecipeLine.FindSet() then
            Error(NoRecipeLinesErr, Allocation."Selected Recipe No.", Allocation."Selected Revision No.");

        repeat
            NextLineNo += 10000;
            CreateRequirementLine(MaterialReq, Allocation, Recipe, RecipeLine, MaterialLocation.Code, CheckedAt, NextLineNo);
            if MaterialReq."Shortage Quantity" > 0 then
                HasShortage := true;
        until RecipeLine.Next() = 0;

        Allocation."Material Req. Status" := Allocation."Material Req. Status"::Available;
        if HasShortage then
            Allocation."Material Req. Status" := Allocation."Material Req. Status"::Shortage;
        Allocation."Material Req. Checked At" := CheckedAt;
        Allocation."Material Warehouse Code" := MaterialLocation.Code;
        Allocation."Material Req. Message" := '';
        Allocation.Modify(true);
    end;

    procedure OpenRequirements(Allocation: Record "SI Supply Allocation")
    var
        MaterialReq: Record "SI Supply Material Req.";
    begin
        MaterialReq.SetRange("Decision No.", Allocation."Decision No.");
        MaterialReq.SetRange("Decision Line No.", Allocation."Decision Line No.");
        MaterialReq.SetRange("Allocation Line No.", Allocation."Line No.");
        Page.Run(Page::"SI Supply Material Reqs.", MaterialReq);
    end;

    local procedure CreateRequirementLine(var MaterialReq: Record "SI Supply Material Req."; Allocation: Record "SI Supply Allocation"; Recipe: Record "SI Concrete Recipe"; RecipeLine: Record "SI Concrete Recipe Line"; MaterialLocationCode: Code[10]; CheckedAt: DateTime; LineNo: Integer)
    var
        RequiredQty: Decimal;
        AvailableQty: Decimal;
    begin
        RequiredQty := Allocation.Quantity * RecipeLine.Quantity / Recipe."Output Quantity";
        AvailableQty := GetAvailableQuantity(RecipeLine."Item No.", RecipeLine."Variant Code", RecipeLine."Unit of Measure Code", MaterialLocationCode);

        MaterialReq.Init();
        MaterialReq."Decision No." := Allocation."Decision No.";
        MaterialReq."Decision Line No." := Allocation."Decision Line No.";
        MaterialReq."Allocation Line No." := Allocation."Line No.";
        MaterialReq."Line No." := LineNo;
        MaterialReq."Item No." := RecipeLine."Item No.";
        MaterialReq."Variant Code" := RecipeLine."Variant Code";
        MaterialReq.Description := RecipeLine.Description;
        MaterialReq."Unit of Measure Code" := RecipeLine."Unit of Measure Code";
        MaterialReq."Quantity per" := RecipeLine.Quantity;
        MaterialReq."Required Quantity" := RequiredQty;
        MaterialReq."Available Quantity" := AvailableQty;
        if RequiredQty > AvailableQty then
            MaterialReq."Shortage Quantity" := RequiredQty - AvailableQty;
        MaterialReq."Location Code" := MaterialLocationCode;
        MaterialReq."Recipe No." := Allocation."Selected Recipe No.";
        MaterialReq."Revision No." := Allocation."Selected Revision No.";
        MaterialReq."Checked At" := CheckedAt;
        MaterialReq.Insert();
    end;

    local procedure GetAvailableQuantity(ItemNo: Code[20]; VariantCode: Code[10]; UoMCode: Code[10]; LocationCode: Code[10]): Decimal
    var
        Item: Record Item;
        ItemUoM: Record "Item Unit of Measure";
        QtyPerUoM: Decimal;
    begin
        Item.Get(ItemNo);
        Item.SetRange("Location Filter", LocationCode);
        if VariantCode <> '' then
            Item.SetRange("Variant Filter", VariantCode);
        Item.CalcFields(Inventory);

        QtyPerUoM := 1;
        if UoMCode <> '' then begin
            if not ItemUoM.Get(ItemNo, UoMCode) then
                Error(UoMNotFoundErr, UoMCode, ItemNo);
            ItemUoM.TestField("Qty. per Unit of Measure");
            QtyPerUoM := ItemUoM."Qty. per Unit of Measure";
        end;

        exit(Item.Inventory / QtyPerUoM);
    end;

    local procedure ResolveMaterialWarehouse(var MaterialLocation: Record Location)
    var
        LocationSetup: Record "SI Location Setup";
    begin
        if not LocationSetup.Get('') then
            Error(LocationSetupErr);
        LocationSetup.TestField("Material Warehouse Type");

        MaterialLocation.SetRange("SI Location Type Code", LocationSetup."Material Warehouse Type");
        if not MaterialLocation.FindFirst() then
            Error(NoMaterialWarehouseErr, LocationSetup."Material Warehouse Type");
        if MaterialLocation.Next() <> 0 then
            Error(MultipleMaterialWarehousesErr, LocationSetup."Material Warehouse Type");
        MaterialLocation.FindFirst();
    end;

    local procedure ValidateContext(Allocation: Record "SI Supply Allocation")
    begin
        Allocation.TestField("Supply Method", Allocation."Supply Method"::Production);
        Allocation.TestField(Quantity);
        Allocation.TestField("Item No.");
        Allocation.TestField("Required on Site At");
        if not IsNullGuid(Allocation."Execution System ID") then
            Error(ExecutionExistsErr);
    end;

    var
        NoRevisionErr: Label 'Не вибрано ревізію рецептури.';
        RevisionNotApplicableErr: Label 'Рецептура %1, ревізія %2 більше не застосовна на дату потреби.';
        NoRecipeLinesErr: Label 'Рецептура %1, ревізія %2 не містить компонентів.';
        UoMNotFoundErr: Label 'Одиницю виміру %1 не налаштовано для матеріалу %2.';
        LocationSetupErr: Label 'Не налаштовано Налаштування типів складів у STROYINVEST Foundation.';
        NoMaterialWarehouseErr: Label 'Не знайдено склад матеріалів типу %1.';
        MultipleMaterialWarehousesErr: Label 'Знайдено більше одного складу матеріалів типу %1. Для MVP джерело матеріалів має бути однозначним.';
        ExecutionExistsErr: Label 'Потребу в матеріалах не можна перераховувати після створення документа виконання.';
        ProcurementPreparedErr: Label 'Потребу в матеріалах не можна перераховувати, доки для цього розподілу є рядки у підготовці закупівлі. Спочатку видаліть їх із підготовки.';
}
