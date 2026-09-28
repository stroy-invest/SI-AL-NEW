codeunit 61040 "SI Planning PoC Mgt."
{
    procedure ProjectRequirement(MaterialReq: Record "SI Supply Material Req.")
    var
        Projection: Record "SI Planning PoC Projection";
        ForecastEntry: Record "Production Forecast Entry";
        ForecastName: Record "Production Forecast Name";
        InventorySetup: Record "Inventory Setup";
        Allocation: Record "SI Supply Allocation";
        PlanningDate: Date;
        ProjectionExists: Boolean;
    begin
        ValidateMaterialRequirement(MaterialReq, Allocation);
        ValidatePlanningConfiguration(InventorySetup, ForecastName);
        PlanningDate := ResolveMaterialPlanningDate(Allocation);

        ProjectionExists := GetProjection(MaterialReq, Projection);
        if ProjectionExists then begin
            if not ForecastEntry.Get(Projection."Forecast Entry No.") then
                Error(ProjectionEntryMissingErr, Projection."Forecast Entry No.", Projection."Forecast Name");
            if ForecastEntry."Production Forecast Name" <> Projection."Forecast Name" then
                Error(ProjectionEntryMismatchErr, Projection."Forecast Entry No.");

            AssignPlanningForOldEntry(ForecastEntry);
            ApplyForecastEntry(ForecastEntry, MaterialReq, InventorySetup."Current Demand Forecast", PlanningDate);
            ForecastEntry.Modify(true);
        end else begin
            ForecastEntry.Init();
            ApplyForecastEntry(ForecastEntry, MaterialReq, InventorySetup."Current Demand Forecast", PlanningDate);
            ForecastEntry.Insert(true);

            Projection.Init();
            Projection."Decision No." := MaterialReq."Decision No.";
            Projection."Decision Line No." := MaterialReq."Decision Line No.";
            Projection."Allocation Line No." := MaterialReq."Allocation Line No.";
            Projection."Requirement Line No." := MaterialReq."Line No.";
        end;

        UpdateProjection(Projection, ForecastEntry, not ProjectionExists);
        Message(ProjectedMsg, ForecastEntry."Entry No.", ForecastEntry."Production Forecast Name", ForecastEntry."Item No.", ForecastEntry."Forecast Quantity", ForecastEntry."Unit of Measure Code", ForecastEntry."Location Code", ForecastEntry."Forecast Date");
    end;

    procedure DeleteProjection(MaterialReq: Record "SI Supply Material Req.")
    var
        Projection: Record "SI Planning PoC Projection";
        ForecastEntry: Record "Production Forecast Entry";
    begin
        if not GetProjection(MaterialReq, Projection) then
            Error(NoProjectionErr);

        if ForecastEntry.Get(Projection."Forecast Entry No.") then begin
            if ForecastEntry."Production Forecast Name" <> Projection."Forecast Name" then
                Error(ProjectionEntryMismatchErr, Projection."Forecast Entry No.");
            AssignPlanningForOldEntry(ForecastEntry);
            ForecastEntry.Delete(true);
        end;

        Projection.Delete(true);
        Message(ProjectionDeletedMsg);
    end;

    procedure OpenProjection(MaterialReq: Record "SI Supply Material Req.")
    var
        Projection: Record "SI Planning PoC Projection";
        ForecastEntry: Record "Production Forecast Entry";
    begin
        if not GetProjection(MaterialReq, Projection) then
            Error(NoProjectionErr);
        if not ForecastEntry.Get(Projection."Forecast Entry No.") then
            Error(ProjectionEntryMissingErr, Projection."Forecast Entry No.", Projection."Forecast Name");

        ForecastEntry.SetRange("Entry No.", Projection."Forecast Entry No.");
        Page.Run(Page::"Demand Forecast Entries", ForecastEntry);
    end;

    procedure HasProjection(MaterialReq: Record "SI Supply Material Req."): Boolean
    var
        Projection: Record "SI Planning PoC Projection";
    begin
        exit(GetProjection(MaterialReq, Projection));
    end;

    local procedure ValidateMaterialRequirement(MaterialReq: Record "SI Supply Material Req."; var Allocation: Record "SI Supply Allocation")
    var
        Item: Record Item;
        ItemUoM: Record "Item Unit of Measure";
        Location: Record Location;
        LocationSetup: Record "SI Location Setup";
    begin
        MaterialReq.TestField("Item No.");
        MaterialReq.TestField("Unit of Measure Code");
        MaterialReq.TestField("Location Code");
        if MaterialReq."Required Quantity" <= 0 then
            Error(RequiredQtyErr, MaterialReq."Required Quantity");

        Item.Get(MaterialReq."Item No.");
        if not ItemUoM.Get(MaterialReq."Item No.", MaterialReq."Unit of Measure Code") then
            Error(UoMNotFoundErr, MaterialReq."Unit of Measure Code", MaterialReq."Item No.");
        ItemUoM.TestField("Qty. per Unit of Measure");

        Location.Get(MaterialReq."Location Code");
        if not LocationSetup.Get('') then
            Error(LocationSetupErr);
        LocationSetup.TestField("Material Warehouse Type");
        if Location."SI Location Type Code" <> LocationSetup."Material Warehouse Type" then
            Error(LocationSemanticErr, Location.Code, Location."SI Location Type Code", LocationSetup."Material Warehouse Type");

        if not Allocation.Get(MaterialReq."Decision No.", MaterialReq."Decision Line No.", MaterialReq."Allocation Line No.") then
            Error(AllocationNotFoundErr, MaterialReq."Decision No.", MaterialReq."Decision Line No.", MaterialReq."Allocation Line No.");
        Allocation.TestField("Supply Method", Allocation."Supply Method"::Production);
        Allocation.TestField("Required on Site At");
    end;

    local procedure ValidatePlanningConfiguration(var InventorySetup: Record "Inventory Setup"; var ForecastName: Record "Production Forecast Name")
    begin
        InventorySetup.Get();
        InventorySetup.TestField("Current Demand Forecast");
        if not InventorySetup."Use Forecast on Locations" then
            Error(UseLocationsErr);
        if not InventorySetup."Use Forecast on Variants" then
            Error(UseVariantsErr);

        ForecastName.Get(InventorySetup."Current Demand Forecast");
        if not (ForecastName."Forecast Type" in [ForecastName."Forecast Type"::Component, ForecastName."Forecast Type"::Both]) then
            Error(ForecastTypeErr, ForecastName.Name);
        if not ForecastName."Forecast By Locations" then
            Error(ForecastByLocationsErr, ForecastName.Name);
        if not ForecastName."Forecast By Variants" then
            Error(ForecastByVariantsErr, ForecastName.Name);
    end;

    local procedure ResolveMaterialPlanningDate(Allocation: Record "SI Supply Allocation"): Date
    begin
        // PoC contract: temporary resolver boundary. Stage 4 replaces this implementation.
        Allocation.TestField("Required on Site At");
        exit(DT2Date(Allocation."Required on Site At"));
    end;

    local procedure ApplyForecastEntry(var ForecastEntry: Record "Production Forecast Entry"; MaterialReq: Record "SI Supply Material Req."; ForecastName: Code[10]; PlanningDate: Date)
    begin
        ForecastEntry.Validate("Production Forecast Name", ForecastName);
        ForecastEntry.Validate("Item No.", MaterialReq."Item No.");
        ForecastEntry.Validate("Forecast Date", PlanningDate);
        ForecastEntry.Validate("Location Code", MaterialReq."Location Code");
        ForecastEntry.Validate("Variant Code", MaterialReq."Variant Code");
        ForecastEntry.Validate("Component Forecast", true);
        ForecastEntry.Description := CopyStr(StrSubstNo(DescriptionTxt, MaterialReq."Decision No.", MaterialReq."Allocation Line No.", MaterialReq."Line No."), 1, MaxStrLen(ForecastEntry.Description));
        ForecastEntry.Validate("Unit of Measure Code", MaterialReq."Unit of Measure Code");
        ForecastEntry.Validate("Forecast Quantity", MaterialReq."Required Quantity");
    end;

    local procedure AssignPlanningForOldEntry(ForecastEntry: Record "Production Forecast Entry")
    var
        PlanningAssignment: Record "Planning Assignment";
    begin
        PlanningAssignment.AssignOne(ForecastEntry."Item No.", ForecastEntry."Variant Code", ForecastEntry."Location Code", ForecastEntry."Forecast Date");
    end;

    local procedure UpdateProjection(var Projection: Record "SI Planning PoC Projection"; ForecastEntry: Record "Production Forecast Entry"; InsertNew: Boolean)
    begin
        Projection."Forecast Name" := ForecastEntry."Production Forecast Name";
        Projection."Forecast Entry No." := ForecastEntry."Entry No.";
        Projection."Item No." := ForecastEntry."Item No.";
        Projection."Variant Code" := ForecastEntry."Variant Code";
        Projection."Location Code" := ForecastEntry."Location Code";
        Projection."Unit of Measure Code" := ForecastEntry."Unit of Measure Code";
        Projection."Forecast Date" := ForecastEntry."Forecast Date";
        Projection."Projected Quantity" := ForecastEntry."Forecast Quantity";
        Projection."Projected At" := CurrentDateTime();
        if InsertNew then
            Projection.Insert(true)
        else
            Projection.Modify(true);
    end;

    local procedure GetProjection(MaterialReq: Record "SI Supply Material Req."; var Projection: Record "SI Planning PoC Projection"): Boolean
    begin
        exit(Projection.Get(MaterialReq."Decision No.", MaterialReq."Decision Line No.", MaterialReq."Allocation Line No.", MaterialReq."Line No."));
    end;

    var
        RequiredQtyErr: Label 'Кількість потреби має бути більшою за нуль. Поточне значення: %1.';
        UoMNotFoundErr: Label 'Одиницю виміру %1 не налаштовано для матеріалу %2.';
        LocationSetupErr: Label 'Не налаштовано Налаштування типів складів у STROYINVEST Foundation.';
        LocationSemanticErr: Label 'Склад %1 має семантичний тип %2, але для потреби матеріалів очікується тип %3.';
        AllocationNotFoundErr: Label 'Не знайдено розподіл %1 / %2 / %3, з якого походить потреба.';
        UseLocationsErr: Label 'У Налаштуваннях модуля Запаси потрібно увімкнути "Використовувати прогноз по складах".';
        UseVariantsErr: Label 'У Налаштуваннях модуля Запаси потрібно увімкнути використання прогнозу по варіантах.';
        ForecastTypeErr: Label 'Поточний прогноз попиту %1 не має тип Component або Both.';
        ForecastByLocationsErr: Label 'Для прогнозу попиту %1 потрібно увімкнути Forecast By Locations.';
        ForecastByVariantsErr: Label 'Для прогнозу попиту %1 потрібно увімкнути Forecast By Variants.';
        ProjectionEntryMissingErr: Label 'PoC-проєкція посилається на відсутній Forecast Entry %1 у прогнозі %2. Автоматичний fallback заборонено; стан потрібно виправити явно.';
        ProjectionEntryMismatchErr: Label 'Forecast Entry %1 більше не належить прогнозу, записаному в PoC-проєкції. Автоматичний fallback заборонено.';
        NoProjectionErr: Label 'Для цієї потреби Planning PoC-проєкцію ще не створено.';
        DescriptionTxt: Label 'SI MR %1 / alloc %2 / req %3';
        ProjectedMsg: Label 'PoC-проєкцію створено/оновлено. Forecast Entry %1, прогноз %2, матеріал %3, кількість %4 %5, склад %6, дата %7.';
        ProjectionDeletedMsg: Label 'Planning PoC-проєкцію видалено.';
}
