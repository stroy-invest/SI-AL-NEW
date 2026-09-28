codeunit 61047 "SI Proc. Planning Runner"
{
    Permissions =
        tabledata "Req. Wksh. Template" = RIMD,
        tabledata "Requisition Wksh. Name" = RIMD,
        tabledata "Requisition Line" = RIMD;

    procedure RefreshPlan()
    var
        PlanningDemandMgt: Codeunit "SI Planning Demand Mgt.";
        PlanningForecastMgt: Codeunit "SI Planning Forecast Mgt.";
    begin
        PlanningDemandMgt.RebuildAllSilent();
        PlanningForecastMgt.SyncAll();
        CalculateStandardPlan();
    end;

    procedure CalculateStandardPlan()
    var
        Setup: Record "SI Supply Req Setup";
        PlanningDemand: Record "SI Planning Demand";
        CalculatePlan: Report "Calculate Plan - Req. Wksh.";
        RunContext: Codeunit "SI Planning Run Context";
        TraceMgt: Codeunit "SI Proc. Plan Trace Mgt.";
        SnapshotMgt: Codeunit "SI Proc. Plan Snapshot Mgt.";
        StartDate: Date;
        EndDate: Date;
    begin
        if not Setup.Get('') then
            Error(SetupMissingErr);
        Setup.TestField("Planning Forecast Name");

        EnsureDedicatedWorksheet();
        GetPlanningHorizon(PlanningDemand, StartDate, EndDate);

        CalculatePlan.SetTemplAndWorksheet(PlanningTemplateCodeLbl, PlanningBatchCodeLbl);
        CalculatePlan.InitializeRequest(StartDate, EndDate);

        // Report 699 initializes Use Forecast from Inventory Setup and does not
        // expose a public setter. The scoped context below overrides only this
        // runner invocation through the standard integration event.
        TraceMgt.BeginCapture(PlanningTemplateCodeLbl, PlanningBatchCodeLbl);
        RunContext.Arm(Setup."Planning Forecast Name");
        CalculatePlan.InitializeFromSetup();
        CalculatePlan.UseRequestPage(false);
        CalculatePlan.Run();
        Clear(CalculatePlan);


        TraceMgt.EndCapture();

        SnapshotMgt.Capture(PlanningTemplateCodeLbl, PlanningBatchCodeLbl, Setup."Planning Forecast Name", StartDate, EndDate);
        Message(PlanningDoneMsg, StartDate, EndDate, Setup."Planning Forecast Name");
    end;

    procedure OpenProcurementSnapshot()
    var
        SnapshotMgt: Codeunit "SI Proc. Plan Snapshot Mgt.";
    begin
        SnapshotMgt.OpenCurrentSnapshot();
    end;

    procedure OpenPlanningWorksheet()
    var
        ReqLine: Record "Requisition Line";
    begin
        EnsureDedicatedWorksheet();
        ReqLine.SetRange("Worksheet Template Name", PlanningTemplateCodeLbl);
        ReqLine.SetRange("Journal Batch Name", PlanningBatchCodeLbl);
        Page.Run(Page::"Req. Worksheet", ReqLine);
    end;

    local procedure EnsureDedicatedWorksheet()
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
        ReqWkshName: Record "Requisition Wksh. Name";
    begin
        if not ReqWkshTemplate.Get(PlanningTemplateCodeLbl) then begin
            ReqWkshTemplate.Init();
            ReqWkshTemplate.Validate(Name, PlanningTemplateCodeLbl);
            ReqWkshTemplate.Validate(Description, PlanningTemplateDescriptionLbl);
            ReqWkshTemplate.Validate(Type, ReqWkshTemplate.Type::"Req.");
            ReqWkshTemplate.Validate(Recurring, false);
            ReqWkshTemplate.Insert(true);
        end else begin
            if ReqWkshTemplate.Type <> ReqWkshTemplate.Type::"Req." then
                Error(InvalidTemplateTypeErr, PlanningTemplateCodeLbl);
            if ReqWkshTemplate.Recurring then
                Error(RecurringTemplateErr, PlanningTemplateCodeLbl);
        end;

        if not ReqWkshName.Get(PlanningTemplateCodeLbl, PlanningBatchCodeLbl) then begin
            ReqWkshName.Init();
            ReqWkshName.Validate("Worksheet Template Name", PlanningTemplateCodeLbl);
            ReqWkshName.Validate(Name, PlanningBatchCodeLbl);
            ReqWkshName.Validate(Description, PlanningBatchDescriptionLbl);
            ReqWkshName.Insert(true);
        end;
    end;

    local procedure GetPlanningHorizon(var PlanningDemand: Record "SI Planning Demand"; var StartDate: Date; var EndDate: Date)
    begin
        PlanningDemand.Reset();
        PlanningDemand.SetRange("Planning Status", PlanningDemand."Planning Status"::Active);
        PlanningDemand.SetFilter(Quantity, '>0');
        PlanningDemand.SetFilter("Planning Date", '<>%1', 0D);
        if not PlanningDemand.FindFirst() then
            Error(NoPlanningDemandErr);

        StartDate := PlanningDemand."Planning Date";
        EndDate := PlanningDemand."Planning Date";
        repeat
            if PlanningDemand."Planning Date" < StartDate then
                StartDate := PlanningDemand."Planning Date";
            if PlanningDemand."Planning Date" > EndDate then
                EndDate := PlanningDemand."Planning Date";
        until PlanningDemand.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Calculate Plan - Req. Wksh.", 'OnBeforeInitializeFromSetup', '', false, false)]
    local procedure OnBeforeInitializeFromSetup(var UseForecast: Code[10]; var IsHandled: Boolean; var InventorySetup: Record "Inventory Setup")
    var
        RunContext: Codeunit "SI Planning Run Context";
        TraceMgt: Codeunit "SI Proc. Plan Trace Mgt.";
        SnapshotMgt: Codeunit "SI Proc. Plan Snapshot Mgt.";
        ForecastName: Code[10];
    begin
        if not RunContext.Consume(ForecastName) then
            exit;

        UseForecast := ForecastName;
        IsHandled := true;
    end;

    var
        PlanningTemplateCodeLbl: Label 'SI-PLAN', Locked = true;
        PlanningBatchCodeLbl: Label 'SI-PLAN', Locked = true;
        PlanningTemplateDescriptionLbl: Label 'SI Procurement Planning';
        PlanningBatchDescriptionLbl: Label 'SI Procurement Planning';
        SetupMissingErr: Label 'Не налаштовано Налаштування заявок на забезпечення.';
        NoPlanningDemandErr: Label 'Немає активних планових потреб для розрахунку.';
        InvalidTemplateTypeErr: Label 'Стандартний шаблон аркуша %1 уже існує, але має тип, відмінний від Requisition.';
        RecurringTemplateErr: Label 'Стандартний шаблон аркуша %1 уже існує як періодичний. Для SI Procurement Planning потрібен неперіодичний шаблон.';
        PlanningDoneMsg: Label 'Стандартний розрахунок Business Central завершено. Період: %1..%2. Прогноз: %3.';
}
