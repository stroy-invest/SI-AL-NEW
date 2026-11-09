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
            group(Summary)
            {
                Caption = 'Контроль виробничого факту';
                field("Technical Validation"; Rec."Technical Validation") { ApplicationArea = All; StyleExpr = ValidationStyle; }
                field("Execution Evidence"; Rec."Execution Evidence") { ApplicationArea = All; }
                field("Verification Status"; Rec."Verification Status") { ApplicationArea = All; }
                field("Simulation"; Rec."Simulation") { ApplicationArea = All; }
            }
            group(General)
            {
                Caption = 'Загальне';
                field("Production ID"; Rec."Production ID") { ApplicationArea = All; }
                field("Production Date/Time"; Rec."Production Date/Time") { ApplicationArea = All; }
                field("Connection Code"; Rec."Connection Code") { ApplicationArea = All; Caption = 'Профіль Proktek'; }
                field(Status; Rec.Status) { ApplicationArea = All; }
            }
            group(RecipeContext)
            {
                Caption = 'Продукція та рецептура';
                field("Recipe No."; Rec."Recipe No.") { ApplicationArea = All; }
                field("Recipe Revision No."; Rec."Recipe Revision No.") { ApplicationArea = All; }
                field("Item No."; Rec."Item No.") { ApplicationArea = All; }
                field("Variant Code"; Rec."Variant Code") { ApplicationArea = All; }
                field("Production BOM No."; Rec."Production BOM No.") { ApplicationArea = All; }
                field("Production BOM Version Code"; Rec."Production BOM Version Code") { ApplicationArea = All; }
            }
            group(Quantity)
            {
                Caption = 'Виробництво';
                field("Ordered Quantity M3"; Rec."Ordered Quantity M3") { ApplicationArea = All; }
                field(ReportedOrderTotalSummary; Rec.GetReportedOrderSummaryText()) { ApplicationArea = All; Caption = 'Заявлено MES за замовленням, м³'; Editable = false; }
                field(ConfirmedOrderTotalSummary; Rec.GetOrderTotalText()) { ApplicationArea = All; Caption = 'Підтверджено за замовленням, м³'; Editable = false; }
                field(OrderDeviationSummary; Rec.GetOrderDeviationText()) { ApplicationArea = All; Caption = 'Надлишок / недостача, м³'; Editable = false; StyleExpr = OrderDeviationStyle; }
                field(CurrentBatchSummary; Rec.GetProducedQuantityText()) { ApplicationArea = All; Caption = 'Поточний заміс, м³'; Editable = false; }
                field("Truck Code"; Rec."Truck Code") { ApplicationArea = All; }
                field("Truck Plate"; Rec."Truck Plate") { ApplicationArea = All; }
            }
            part(Materials; "SI Prok Prod Fact Materials")
            {
                ApplicationArea = All;
                Caption = 'Матеріали';
                SubPageLink = "Production Fact Entry No." = field("Entry No.");
            }
            part(ValidationLines; "SI Prok Fact Validation Lines")
            {
                ApplicationArea = All;
                Caption = 'Діагностика технічної перевірки';
                SubPageLink = "Production Fact Entry No." = field("Entry No.");
            }
            group(Additional)
            {
                Caption = 'Додаткові відомості';
                field("Production UUID"; Rec."Production UUID") { ApplicationArea = All; }
                field("Capture Mode"; Rec."Capture Mode") { ApplicationArea = All; }
                field("Order ID"; Rec."Order ID") { ApplicationArea = All; }
                field("Order UUID"; Rec."Order UUID") { ApplicationArea = All; }
                field("Order No."; Rec."Order No.") { ApplicationArea = All; }
                field("Supply Decision No."; Rec."Supply Decision No.") { ApplicationArea = All; }
                field("Supply Decision Line No."; Rec."Supply Decision Line No.") { ApplicationArea = All; }
                field("Supply Allocation Line No."; Rec."Supply Allocation Line No.") { ApplicationArea = All; }
                field("Project No."; Rec."Project No.") { ApplicationArea = All; }
                field("Formula ID"; Rec."Formula ID") { ApplicationArea = All; }
                field("Formula UUID"; Rec."Formula UUID") { ApplicationArea = All; }
                field("Formula Code"; Rec."Formula Code") { ApplicationArea = All; }
                field("Formula Name"; Rec."Formula Name") { ApplicationArea = All; }
                field("Formula ERP Code"; Rec."Formula ERP Code") { ApplicationArea = All; }
                field("Recipe Resolution Note"; Rec."Recipe Resolution Note") { ApplicationArea = All; }
                field("Validation Message"; Rec."Validation Message") { ApplicationArea = All; }
                field("Technical Diagnostics"; Rec."Technical Diagnostics") { ApplicationArea = All; MultiLine = true; }
                field("Verification Message"; Rec."Verification Message") { ApplicationArea = All; MultiLine = true; }
                field(ReportedPresence; Rec.GetReportedPresenceText()) { ApplicationArea = All; Caption = 'Обсяг MES передано'; Editable = false; }
                field(ConfirmedOrderTotal; Rec.GetOrderTotalText()) { ApplicationArea = All; Caption = 'Підтверджено по Order, м³'; Editable = false; }
                field(ReportedOrderTotal; Rec.GetReportedOrderTotalText()) { ApplicationArea = All; Caption = 'Заявлено MES по Order, м³'; Editable = false; }
                field(OrderRemaining; Rec.GetOrderRemainingText()) { ApplicationArea = All; Caption = 'Залишок за підтвердженнями, м³'; Editable = false; }
                field("Ready for Posting"; Rec."Ready for Posting") { ApplicationArea = All; Visible = false; }
            }
        }
        area(FactBoxes)
        {
            part(ControlFactBox; "SI Prok Fact Control FactBox") { ApplicationArea = All; SubPageLink = "Entry No." = field("Entry No."); }
            part(SourceFactBox; "SI Prok Fact Source FactBox") { ApplicationArea = All; SubPageLink = "Entry No." = field("Entry No."); }
            part(LinksFactBox; "SI Prok Fact Links FactBox") { ApplicationArea = All; SubPageLink = "Entry No." = field("Entry No."); }
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

            action(RevalidateTechnical)
            {
                ApplicationArea = All;
                Caption = 'Повторна технічна перевірка';
                Image = Check;
                trigger OnAction()
                var
                    Validator: Codeunit "SI Prok Technical Validator";
                begin
                    Validator.Assess(Rec);
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
    trigger OnAfterGetRecord()
    begin
        ValidationStyle := 'Standard';
        OrderDeviationStyle := 'Standard';
        if Rec."Ordered Quantity M3" > 0 then begin
            if Rec.Simulation then begin
                if Rec."Order Produced Total M3" > Rec."Ordered Quantity M3" then
                    OrderDeviationStyle := 'Attention'
                else
                    if Rec."Order Produced Total M3" < Rec."Ordered Quantity M3" then
                        OrderDeviationStyle := 'Unfavorable';
            end else
                if Rec.GetConfirmedOrderTotal() > Rec."Ordered Quantity M3" then
                    OrderDeviationStyle := 'Attention'
                else
                    if Rec.GetConfirmedOrderTotal() < Rec."Ordered Quantity M3" then
                        OrderDeviationStyle := 'Unfavorable';
        end;
        case Rec."Technical Validation" of
            Rec."Technical Validation"::Complete: ValidationStyle := 'Favorable';
            Rec."Technical Validation"::Incomplete, Rec."Technical Validation"::Inconsistent: ValidationStyle := 'Unfavorable';
            Rec."Technical Validation"::CompleteWithWarnings: ValidationStyle := 'Attention';
        end;
    end;
    var
        ValidationStyle: Text;
        OrderDeviationStyle: Text;
}
