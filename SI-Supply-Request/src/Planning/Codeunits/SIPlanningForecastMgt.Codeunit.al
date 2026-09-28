codeunit 61044 "SI Planning Forecast Mgt."
{
    procedure SyncAll()
    var
        Demand: Record "SI Planning Demand";
        Projection: Record "SI Planning Forecast Proj.";
        Setup: Record "SI Supply Req Setup";
        ForecastName: Record "Production Forecast Name";
        SyncToken: Guid;
        CountSynced: Integer;
        CountDeleted: Integer;
    begin
        ValidateConfiguration(Setup, ForecastName);
        SyncToken := CreateGuid();

        Demand.Reset();
        Demand.SetRange("Planning Status", Demand."Planning Status"::Active);
        Demand.SetFilter(Quantity, '>0');
        if Demand.FindSet() then
            repeat
                SyncDemand(Demand, Setup."Planning Forecast Name", SyncToken);
                CountSynced += 1;
            until Demand.Next() = 0;

        Projection.Reset();
        Projection.SetFilter("Sync Token", '<>%1', SyncToken);
        if Projection.FindSet(true) then
            repeat
                DeleteProjectedEntry(Projection);
                Projection.Delete(true);
                CountDeleted += 1;
            until Projection.Next() = 0;

        Message(SyncDoneMsg, CountSynced, CountDeleted, Setup."Planning Forecast Name");
    end;

    procedure OpenForecast()
    var
        Setup: Record "SI Supply Req Setup";
        ForecastName: Record "Production Forecast Name";
        ForecastEntry: Record "Production Forecast Entry";
    begin
        ValidateConfiguration(Setup, ForecastName);
        ForecastEntry.SetRange("Production Forecast Name", Setup."Planning Forecast Name");
        Page.Run(Page::"Demand Forecast Entries", ForecastEntry);
    end;

    procedure OpenProjection(Demand: Record "SI Planning Demand")
    var
        Projection: Record "SI Planning Forecast Proj.";
        ForecastEntry: Record "Production Forecast Entry";
    begin
        if not Projection.Get(Demand."Entry No.") then
            Error(NoProjectionErr, Demand."Entry No.");
        if not ForecastEntry.Get(Projection."Forecast Entry No.") then
            Error(ForecastEntryMissingErr, Projection."Forecast Entry No.", Demand."Entry No.");
        if ForecastEntry."Production Forecast Name" <> Projection."Forecast Name" then
            Error(ForecastEntryMismatchErr, Projection."Forecast Entry No.", Projection."Forecast Name");

        ForecastEntry.SetRange("Entry No.", Projection."Forecast Entry No.");
        Page.Run(Page::"Demand Forecast Entries", ForecastEntry);
    end;

    local procedure SyncDemand(Demand: Record "SI Planning Demand"; ForecastName: Code[10]; SyncToken: Guid)
    var
        Projection: Record "SI Planning Forecast Proj.";
        ForecastEntry: Record "Production Forecast Entry";
        ProjectionExists: Boolean;
    begin
        ValidateDemand(Demand);
        ProjectionExists := Projection.Get(Demand."Entry No.");

        if ProjectionExists then begin
            if Projection."Forecast Name" <> ForecastName then
                Error(ForecastChangedErr, Demand."Entry No.", Projection."Forecast Name", ForecastName);
            if not ForecastEntry.Get(Projection."Forecast Entry No.") then
                Error(ForecastEntryMissingErr, Projection."Forecast Entry No.", Demand."Entry No.");
            if ForecastEntry."Production Forecast Name" <> Projection."Forecast Name" then
                Error(ForecastEntryMismatchErr, Projection."Forecast Entry No.", Projection."Forecast Name");

            AssignPlanningForOldEntry(ForecastEntry);
            ApplyDemandToForecast(ForecastEntry, Demand, ForecastName);
            ForecastEntry.Modify(true);
        end else begin
            ForecastEntry.Init();
            ApplyDemandToForecast(ForecastEntry, Demand, ForecastName);
            ForecastEntry.Insert(true);

            Projection.Init();
            Projection."Planning Demand Entry No." := Demand."Entry No.";
        end;

        UpdateProjection(Projection, ForecastEntry, SyncToken, not ProjectionExists);
    end;

    local procedure ApplyDemandToForecast(var ForecastEntry: Record "Production Forecast Entry"; Demand: Record "SI Planning Demand"; ForecastName: Code[10])
    var
        ItemVariant: Record "Item Variant";
    begin
        if (Demand."Variant Code" <> '') and (not ItemVariant.Get(Demand."Item No.", Demand."Variant Code")) then
            Error(InvalidItemVariantErr, Demand."Entry No.", Demand."Item No.", Demand."Variant Code");

        ForecastEntry.Validate("Production Forecast Name", ForecastName);
        ForecastEntry.Validate("Item No.", Demand."Item No.");
        ForecastEntry.Validate("Forecast Date", Demand."Planning Date");
        ForecastEntry.Validate("Location Code", Demand."Target Location Code");
        ForecastEntry.Validate("Variant Code", Demand."Variant Code");
        ForecastEntry.Validate("Component Forecast", Demand."Source Type" = Demand."Source Type"::"Production Material");
        ForecastEntry.Description := CopyStr(StrSubstNo(DescriptionTxt, Demand."Entry No.", Demand."Request No.", Demand."Request Line No."), 1, MaxStrLen(ForecastEntry.Description));
        ForecastEntry.Validate("Unit of Measure Code", Demand."Unit of Measure Code");
        ForecastEntry.Validate("Forecast Quantity", Demand.Quantity);
    end;

    local procedure UpdateProjection(var Projection: Record "SI Planning Forecast Proj."; ForecastEntry: Record "Production Forecast Entry"; SyncToken: Guid; InsertNew: Boolean)
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
        Projection."Sync Token" := SyncToken;
        if InsertNew then
            Projection.Insert(true)
        else
            Projection.Modify(true);
    end;

    local procedure DeleteProjectedEntry(Projection: Record "SI Planning Forecast Proj.")
    var
        ForecastEntry: Record "Production Forecast Entry";
    begin
        if not ForecastEntry.Get(Projection."Forecast Entry No.") then
            exit;
        if ForecastEntry."Production Forecast Name" <> Projection."Forecast Name" then
            Error(ForecastEntryMismatchErr, Projection."Forecast Entry No.", Projection."Forecast Name");
        AssignPlanningForOldEntry(ForecastEntry);
        ForecastEntry.Delete(true);
    end;

    local procedure ValidateDemand(Demand: Record "SI Planning Demand")
    var
        ItemUoM: Record "Item Unit of Measure";
    begin
        Demand.TestField("Item No.");
        Demand.TestField("Unit of Measure Code");
        Demand.TestField("Planning Date");
        Demand.TestField("Target Location Code");
        if Demand.Quantity <= 0 then
            Error(DemandQtyErr, Demand."Entry No.", Demand.Quantity);
        if not ItemUoM.Get(Demand."Item No.", Demand."Unit of Measure Code") then
            Error(UoMNotFoundErr, Demand."Unit of Measure Code", Demand."Item No.");
        ItemUoM.TestField("Qty. per Unit of Measure");
    end;

    local procedure ValidateConfiguration(var Setup: Record "SI Supply Req Setup"; var ForecastName: Record "Production Forecast Name")
    begin
        EnsurePlanningForecast(Setup, ForecastName);
    end;

    local procedure EnsurePlanningForecast(var Setup: Record "SI Supply Req Setup"; var ForecastName: Record "Production Forecast Name")
    var
        ForecastCode: Code[10];
    begin
        if not Setup.Get('') then
            Error(SetupMissingErr);

        if Setup."Planning Forecast Name" <> '' then begin
            if not ForecastName.Get(Setup."Planning Forecast Name") then
                Error(ConfiguredForecastMissingErr, Setup."Planning Forecast Name");
            exit;
        end;

        ForecastCode := DefaultForecastCodeLbl;
        if not Confirm(CreateForecastQst, false, ForecastCode) then
            Error(ForecastSetupCancelledErr);

        if not ForecastName.Get(ForecastCode) then begin
            ForecastName.Init();
            ForecastName.Name := ForecastCode;
            ForecastName.Insert(true);
        end;

        Setup.Validate("Planning Forecast Name", ForecastCode);
        Setup.Modify(true);
    end;

    local procedure AssignPlanningForOldEntry(ForecastEntry: Record "Production Forecast Entry")
    var
        PlanningAssignment: Record "Planning Assignment";
    begin
        PlanningAssignment.AssignOne(ForecastEntry."Item No.", ForecastEntry."Variant Code", ForecastEntry."Location Code", ForecastEntry."Forecast Date");
    end;

    var
        SyncDoneMsg: Label 'Синхронізацію завершено. Спроєктовано/оновлено: %1. Видалено застарілих проєкцій: %2. Прогноз: %3.';
        DescriptionTxt: Label 'SI PD %1 / %2 / line %3';
        SetupMissingErr: Label 'Не налаштовано Налаштування заявок на забезпечення.';
        DefaultForecastCodeLbl: Label 'SI-PLAN', Locked = true;
        CreateForecastQst: Label 'Прогноз планових потреб не налаштовано. Створити системний прогноз %1?';
        ForecastSetupCancelledErr: Label 'Синхронізацію прогнозу скасовано. Прогноз планових потреб не налаштовано.';
        ConfiguredForecastMissingErr: Label 'У налаштуваннях указано прогноз %1, але такого стандартного прогнозу не існує.';
        ForecastChangedErr: Label 'Планова потреба %1 уже спроєктована у прогноз %2. Налаштовано прогноз %3. Автоматичне переприв’язування заборонено; спочатку очистіть стару проєкцію.';
        ForecastEntryMissingErr: Label 'Не знайдено Forecast Entry %1, на який посилається планова потреба %2. Автоматичний fallback заборонено.';
        ForecastEntryMismatchErr: Label 'Forecast Entry %1 більше не належить прогнозу %2. Автоматичний fallback заборонено.';
        InvalidItemVariantErr: Label 'Планова потреба %1 містить невалідну стандартну пару Item/Variant: товар %2, варіант %3. Варіант повинен існувати в таблиці Item Variant саме для цього товару. Виправте джерело потреби та виконайте Перебудувати.';
        DemandQtyErr: Label 'Планова потреба %1 має неприпустиму кількість %2.';
        UoMNotFoundErr: Label 'Одиницю виміру %1 не налаштовано для товару %2.';
        NoProjectionErr: Label 'Планову потребу %1 ще не спроєктовано у стандартний прогноз.';
}
