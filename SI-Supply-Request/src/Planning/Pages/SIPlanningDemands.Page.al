page 61043 "SI Planning Demands"
{
    PageType = List;
    SourceTable = "SI Planning Demand";
    Caption = 'Єдиний реєстр планових потреб';
    ApplicationArea = All;
    UsageCategory = Tasks;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Source Type"; Rec."Source Type") { ApplicationArea = All; }
                field("Request No."; Rec."Request No.") { ApplicationArea = All; }
                field("Request Line No."; Rec."Request Line No.") { ApplicationArea = All; }
                field("Project No."; Rec."Project No.") { ApplicationArea = All; }
                field("Construction Site Code"; Rec."Construction Site Code") { ApplicationArea = All; }
                field("Item No."; Rec."Item No.") { ApplicationArea = All; }
                field("Variant Code"; Rec."Variant Code") { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
                field(Quantity; Rec.Quantity) { ApplicationArea = All; }
                field("Unit of Measure Code"; Rec."Unit of Measure Code") { ApplicationArea = All; }
                field("Required on Site At"; Rec."Required on Site At") { ApplicationArea = All; }
                field("Planning Date"; Rec."Planning Date") { ApplicationArea = All; }
                field("Target Location Code"; Rec."Target Location Code") { ApplicationArea = All; }
                field("Source Status"; Rec."Source Status") { ApplicationArea = All; }
                field("Decision No."; Rec."Decision No.") { ApplicationArea = All; }
                field("Decision Line No."; Rec."Decision Line No.") { ApplicationArea = All; }
                field("Allocation Line No."; Rec."Allocation Line No.") { ApplicationArea = All; }
                field("Requirement Line No."; Rec."Requirement Line No.") { ApplicationArea = All; }
                field("Last Rebuilt At"; Rec."Last Rebuilt At") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Rebuild)
            {
                Caption = 'Перебудувати';
                ApplicationArea = All;
                Image = Refresh;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    PlanningDemandMgt: Codeunit "SI Planning Demand Mgt.";
                begin
                    PlanningDemandMgt.RebuildAll();
                    CurrPage.Update(false);
                end;
            }
            action(SyncForecast)
            {
                Caption = 'Синхронізувати прогноз';
                ApplicationArea = All;
                Image = Calculate;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    ForecastMgt: Codeunit "SI Planning Forecast Mgt.";
                begin
                    ForecastMgt.SyncAll();
                    CurrPage.Update(false);
                end;
            }
            action(RefreshProcurementPlan)
            {
                Caption = 'Оновити план закупівель';
                ApplicationArea = All;
                Image = CalculatePlan;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    PlanningRunner: Codeunit "SI Proc. Planning Runner";
                begin
                    PlanningRunner.RefreshPlan();
                    CurrPage.Update(false);
                end;
            }
            action(OpenProcurementBoard)
            {
                Caption = 'Планування закупівель';
                ApplicationArea = All;
                Image = Planning;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                begin
                    Page.Run(Page::"SI Proc. Planning Board");
                end;
            }
            action(OpenProcurementSnapshot)
            {
                Caption = 'Відкрити знімок плану закупівель';
                ApplicationArea = All;
                Image = View;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    PlanningRunner: Codeunit "SI Proc. Planning Runner";
                begin
                    PlanningRunner.OpenProcurementSnapshot();
                end;
            }
            action(OpenPlanningWorksheet)
            {
                Caption = 'Відкрити результат планування';
                ApplicationArea = All;
                Image = Worksheet;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    PlanningRunner: Codeunit "SI Proc. Planning Runner";
                begin
                    PlanningRunner.OpenPlanningWorksheet();
                end;
            }
            action(OpenForecast)
            {
                Caption = 'Відкрити прогноз';
                ApplicationArea = All;
                Image = View;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    ForecastMgt: Codeunit "SI Planning Forecast Mgt.";
                begin
                    ForecastMgt.OpenForecast();
                end;
            }
            action(OpenProjection)
            {
                Caption = 'Відкрити рядок прогнозу';
                ApplicationArea = All;
                Image = Navigate;

                trigger OnAction()
                var
                    ForecastMgt: Codeunit "SI Planning Forecast Mgt.";
                begin
                    ForecastMgt.OpenProjection(Rec);
                end;
            }
        }
    }
}
