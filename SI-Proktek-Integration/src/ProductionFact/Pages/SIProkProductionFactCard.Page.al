page 57093 "SI Prok Production Fact Card"
{
    PageType = Card;
    SourceTable = "SI Prok Production Fact";
    Caption = 'Факт виробництва Proktek';
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Загальне';
                field("Production ID"; Rec."Production ID") { ApplicationArea = All; }
                field("Production UUID"; Rec."Production UUID") { ApplicationArea = All; }
                field("Production Date/Time"; Rec."Production Date/Time") { ApplicationArea = All; }
                field("Capture Mode"; Rec."Capture Mode") { ApplicationArea = All; }
                field("Connection Code"; Rec."Connection Code")
                {
                    ApplicationArea = All;
                    Caption = 'Профіль Proktek';
                    Editable = false;
                    ToolTip = 'Профіль підключення Proktek, через який отримано виробничий факт.';
                }
                field(Status; Rec.Status) { ApplicationArea = All; }
                field("Ready for Posting"; Rec."Ready for Posting") { ApplicationArea = All; }
                field("Validation Message"; Rec."Validation Message") { ApplicationArea = All; }
            }
            group(RecipeContext)
            {
                Caption = 'Рецептура та ревізія';
                field("Recipe No."; Rec."Recipe No.") { ApplicationArea = All; }
                field("Recipe Revision No."; Rec."Recipe Revision No.") { ApplicationArea = All; }
                field("Recipe Resolution Note"; Rec."Recipe Resolution Note") { ApplicationArea = All; }
                field("Item No."; Rec."Item No.") { ApplicationArea = All; }
                field("Variant Code"; Rec."Variant Code") { ApplicationArea = All; }
            }
            group(ProktekFormula)
            {
                Caption = 'Формула Proktek';
                field("Formula ID"; Rec."Formula ID") { ApplicationArea = All; }
                field("Formula UUID"; Rec."Formula UUID") { ApplicationArea = All; }
                field("Formula Code"; Rec."Formula Code") { ApplicationArea = All; }
                field("Formula Name"; Rec."Formula Name") { ApplicationArea = All; }
                field("Formula ERP Code"; Rec."Formula ERP Code") { ApplicationArea = All; }
            }
            group(BOMIdentity)
            {
                Caption = 'Виробнича специфікація BC';
                field("Production BOM No."; Rec."Production BOM No.") { ApplicationArea = All; }
                field("Production BOM Version Code"; Rec."Production BOM Version Code") { ApplicationArea = All; }
            }
            group(Correlation)
            {
                Caption = 'Виробниче замовлення та кореляція';
                field("Order ID"; Rec."Order ID") { ApplicationArea = All; }
                field("Order UUID"; Rec."Order UUID") { ApplicationArea = All; }
                field("Order No."; Rec."Order No.") { ApplicationArea = All; }
                field("Supply Decision No."; Rec."Supply Decision No.") { ApplicationArea = All; }
                field("Supply Decision Line No."; Rec."Supply Decision Line No.") { ApplicationArea = All; }
                field("Supply Allocation Line No."; Rec."Supply Allocation Line No.") { ApplicationArea = All; }
                field("Project No."; Rec."Project No.") { ApplicationArea = All; }
            }
            group(Quantity)
            {
                Caption = 'Кількість';
                field("Ordered Quantity M3"; Rec."Ordered Quantity M3") { ApplicationArea = All; }
                field("Simulation"; Rec."Simulation") { ApplicationArea = All; }
                field("Truck Code"; Rec."Truck Code") { ApplicationArea = All; }
                field("Truck Plate"; Rec."Truck Plate") { ApplicationArea = All; }
                field(ReportedQuantity; Rec.GetReportedQuantityText()) { ApplicationArea = All; Caption = 'Заявлено MES, м³'; Editable = false; ToolTip = 'Переданий MES обсяг; не є підтвердженням виробництва. Для історії читається canonical без зміни запису.'; }
                field(ReportedPresence; Rec.GetReportedPresenceText()) { ApplicationArea = All; Caption = 'Обсяг MES передано'; Editable = false; ToolTip = 'Для історичних записів первинну наявність значення не оцінено.'; }
                field("Verification Status"; Rec."Verification Status") { ApplicationArea = All; }
                field("Execution Evidence"; Rec."Execution Evidence") { ApplicationArea = All; }
                field("Verification Message"; Rec."Verification Message") { ApplicationArea = All; }
                field(ProducedQuantity; Rec.GetProducedQuantityText()) { ApplicationArea = All; Caption = 'Підтверджено, м³'; Editable = false; ToolTip = 'Не підтверджено означає відсутність підтвердженого обсягу, а не доведений нуль виробництва.'; }
                field(ConfirmedOrderTotal; Rec.GetOrderTotalText()) { ApplicationArea = All; Caption = 'Підтверджено по Order, м³'; Editable = false; ToolTip = 'Лише реальні Normal-факти з підтвердженим обсягом; симуляції показано окремо.'; }
                field(ReportedOrderTotal; Rec.GetReportedOrderTotalText()) { ApplicationArea = All; Caption = 'Заявлено MES по Order, м³'; Editable = false; ToolTip = 'Операційний підсумок у межах підключення, Order, режиму і ознаки симуляції. Не підтверджений випуск.'; }
                field(OrderRemaining; Rec.GetOrderRemainingText()) { ApplicationArea = All; Caption = 'Залишок за підтвердженнями, м³'; Editable = false; ToolTip = 'Непідтверджені обсяги MES не зменшують цей залишок. За невідомої замовленої кількості залишок невідомий.'; }
            }
            part(Materials; "SI Prok Prod Fact Materials")
            {
                ApplicationArea = All;
                SubPageLink = "Production Fact Entry No." = field("Entry No.");
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(EnrichAndRevalidate)
            {
                ApplicationArea = All;
                Caption = 'Оновити зв’язки та перевірити';
                Image = Refresh;
                ToolTip = 'Повторно визначити BOM Version та рецептуру за збереженими даними без проведення в облік.';
                trigger OnAction()
                var
                    FactMgt: Codeunit "SI Prok Prod Fact Mgt.";
                begin
                    FactMgt.EnrichAndRevalidate(Rec);
                    CurrPage.Update(false);
                end;
            }

            action(ViewRawResponses)
            {
                ApplicationArea = All;
                Caption = 'Первинні відповіді MES';
                Image = Archive;
                trigger OnAction()
                var
                    Raw: Record "SI Prok Raw API Response";
                begin
                    Raw.SetRange("Production Fact Entry No.", Rec."Entry No.");
                    Page.Run(Page::"SI Prok Raw API Responses", Raw);
                end;
            }
            action(ViewCanonicalJson)
            {
                ApplicationArea = All;
                Caption = 'Canonical JSON';
                Image = View;
                trigger OnAction()
                var
                    JsonText: Text;
                begin
                    JsonText := Rec.GetCanonicalJson();
                    Message('%1', JsonText);
                end;
            }
        }
    }
}
