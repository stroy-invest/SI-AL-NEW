codeunit 61053 "SI Proc. Plan Trace Mgt."
{
    Permissions = tabledata "SI Proc. Plan Trace" = RIMD;

    procedure BeginCapture(TemplateName: Code[10]; BatchName: Code[10])
    var
        Trace: Record "SI Proc. Plan Trace";
        Context: Codeunit "SI Proc. Plan Trace Context";
    begin
        Trace.SetRange("Worksheet Template Name", TemplateName);
        Trace.SetRange("Worksheet Batch Name", BatchName);
        Trace.DeleteAll();
        Context.BeginCapture(TemplateName, BatchName);
    end;

    procedure EndCapture()
    var
        Context: Codeunit "SI Proc. Plan Trace Context";
    begin
        Context.EndCapture();
    end;

    // BC aggregates all forecast entries with the same planning dimensions/date
    // into one Inventory Profile demand. The ProductionForecastEntry parameter is
    // only the representative record after CalcSums/Find('+'), so it must NOT be
    // treated as the sole source of that demand profile.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Profile Offsetting", 'OnAfterForecastInitDemand', '', false, false)]
    local procedure OnAfterForecastInitDemand(var InventoryProfile: Record "Inventory Profile"; ProductionForecastEntry: Record "Production Forecast Entry"; ItemNo: Code[20]; LocationCode: Code[10]; TotalForecastQty: Decimal)
    var
        Context: Codeunit "SI Proc. Plan Trace Context";
        ForecastEntry: Record "Production Forecast Entry";
        Projection: Record "SI Planning Forecast Proj.";
        InventorySetup: Record "Inventory Setup";
    begin
        if not Context.IsActive() then
            exit;

        Context.BeginForecastProfile(InventoryProfile."Line No.");

        InventorySetup.Get();
        ForecastEntry.SetRange("Production Forecast Name", ProductionForecastEntry."Production Forecast Name");
        ForecastEntry.SetRange("Item No.", ItemNo);
        ForecastEntry.SetRange("Forecast Date", ProductionForecastEntry."Forecast Date");
        ForecastEntry.SetRange("Component Forecast", ProductionForecastEntry."Component Forecast");
        if InventorySetup."Use Forecast on Locations" then
            ForecastEntry.SetRange("Location Code", ProductionForecastEntry."Location Code");
        if InventorySetup."Use Forecast on Variants" then
            ForecastEntry.SetRange("Variant Code", ProductionForecastEntry."Variant Code");

        if ForecastEntry.FindSet() then
            repeat
                // Only SI-owned forecast projections participate in SI lineage.
                Projection.SetRange("Forecast Entry No.", ForecastEntry."Entry No.");
                if Projection.FindFirst() then
                    Context.RegisterForecastProfileEntry(
                        InventoryProfile."Line No.", ForecastEntry."Entry No.");
                Projection.Reset();
            until ForecastEntry.Next() = 0;

    end;

    // Real BC demand/supply matching boundary. A forecast Inventory Profile can
    // represent several atomic SI forecast entries after standard forecast
    // aggregation. Persist every one of them against the resulting planning line.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Profile Offsetting", 'OnAfterTrack', '', false, false)]
    local procedure OnAfterTrack(FromProfile: Record "Inventory Profile"; ToProfile: Record "Inventory Profile"; IsSurplus: Boolean; IssueActionMessage: Boolean; Binding: Enum "Reservation Binding")
    var
        Context: Codeunit "SI Proc. Plan Trace Context";
        ForecastEntries: List of [Integer];
        ForecastEntryNo: Integer;
    begin
        if not Context.IsActive() then
            exit;


        Context.GetForecastEntries(FromProfile."Line No.", ForecastEntries);
        if ForecastEntries.Count > 0 then begin
            foreach ForecastEntryNo in ForecastEntries do
                CapturePlanningMatch(ForecastEntryNo, ToProfile);
            exit;
        end;

        Context.GetForecastEntries(ToProfile."Line No.", ForecastEntries);
        foreach ForecastEntryNo in ForecastEntries do
            CapturePlanningMatch(ForecastEntryNo, FromProfile);
    end;

    procedure CapturePlanningMatch(ForecastEntryNo: Integer; PlanningProfile: Record "Inventory Profile")
    var
        Trace: Record "SI Proc. Plan Trace";
        Context: Codeunit "SI Proc. Plan Trace Context";
        TemplateName: Code[10];
        BatchName: Code[10];
    begin
        // Matches against existing inventory/supply have no requisition planning
        // line and therefore are intentionally not procurement lineage.
        if PlanningProfile."Planning Line No." = 0 then
            exit;

        if not Context.GetActiveWorksheet(TemplateName, BatchName) then
            exit;

        if Trace.Get(TemplateName, BatchName, PlanningProfile."Planning Line No.", ForecastEntryNo) then
            exit;

        Trace.Init();
        Trace."Worksheet Template Name" := TemplateName;
        Trace."Worksheet Batch Name" := BatchName;
        Trace."Worksheet Line No." := PlanningProfile."Planning Line No.";
        Trace."Forecast Entry No." := ForecastEntryNo;
        Trace."Attributed Qty. (Base)" := 0;
        Trace.Insert();
    end;
}
