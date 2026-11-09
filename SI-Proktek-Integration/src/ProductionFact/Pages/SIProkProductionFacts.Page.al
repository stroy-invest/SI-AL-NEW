page 57091 "SI Prok Production Facts"
{
    PageType = List;
    SourceTable = "SI Prok Production Fact";
    Caption = 'Факти виробництва Proktek';
    ApplicationArea = All;
    UsageCategory = Tasks;
    CardPageId = "SI Prok Production Fact Card";
    Editable = false;
    SourceTableView = sorting("Entry No.") order(descending);

    layout
    {
        area(Content)
        {
            repeater(Facts)
            {
                field("Production Date/Time"; Rec."Production Date/Time") { ApplicationArea = All; }
                field("Production ID"; Rec."Production ID") { ApplicationArea = All; }
                field("Order No."; Rec."Order No.") { ApplicationArea = All; }
                field("Project No."; Rec."Project No.") { ApplicationArea = All; }
                field("Recipe No."; Rec."Recipe No.") { ApplicationArea = All; }
                field("Recipe Revision No."; Rec."Recipe Revision No.") { ApplicationArea = All; }
                field("Capture Mode"; Rec."Capture Mode") { ApplicationArea = All; }
                field("Simulation"; Rec."Simulation") { ApplicationArea = All; }
                field("Truck Code"; Rec."Truck Code") { ApplicationArea = All; }
                field("Truck Plate"; Rec."Truck Plate") { ApplicationArea = All; }
                field(ReportedQuantity; Rec.GetReportedQuantityText()) { ApplicationArea = All; Caption = 'Заявлено MES, м³'; Editable = false; ToolTip = 'Переданий MES обсяг; не є підтвердженням виробництва. Для історії читається canonical без зміни запису.'; }
                field(ReportedPresence; Rec.GetReportedPresenceText()) { ApplicationArea = All; Caption = 'Обсяг MES передано'; Editable = false; ToolTip = 'Для історичних записів первинну наявність значення не оцінено.'; }
                field("Technical Validation"; Rec."Technical Validation") { ApplicationArea = All; }
                field("Verification Status"; Rec."Verification Status") { ApplicationArea = All; }
                field("Execution Evidence"; Rec."Execution Evidence") { ApplicationArea = All; }
                field("Verification Message"; Rec."Verification Message") { ApplicationArea = All; }
                field(ProducedQuantity; Rec.GetProducedQuantityText()) { ApplicationArea = All; Caption = 'Підтверджено, м³'; Editable = false; ToolTip = 'Не підтверджено означає відсутність підтвердженого обсягу, а не доведений нуль виробництва.'; }
                field(ConfirmedOrderTotal; Rec.GetOrderTotalText()) { ApplicationArea = All; Caption = 'Підтверджено по Order, м³'; Editable = false; ToolTip = 'Лише реальні Normal-факти з підтвердженим обсягом; симуляції показано окремо.'; }
                field(ReportedOrderTotal; Rec.GetReportedOrderTotalText()) { ApplicationArea = All; Caption = 'Заявлено MES по Order, м³'; Editable = false; ToolTip = 'Операційний підсумок у межах підключення, Order, режиму і ознаки симуляції. Не підтверджений випуск.'; }
                field(OrderRemaining; Rec.GetOrderRemainingText()) { ApplicationArea = All; Caption = 'Залишок за підтвердженнями, м³'; Editable = false; ToolTip = 'Непідтверджені обсяги MES не зменшують цей залишок. За невідомої замовленої кількості залишок невідомий.'; }
                field(Status; Rec.Status) { ApplicationArea = All; }
                field("Ready for Posting"; Rec."Ready for Posting") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(CaptureTest)
            {
                Caption = 'Отримати факти (Тест)';
                ApplicationArea = All;
                Image = Import;
                trigger OnAction()
                begin
                    RunCapture(Enum::"SI Prok Capture Mode"::Test);
                end;
            }
            action(CaptureNormal)
            {
                Caption = 'Отримати факти (Normal)';
                ApplicationArea = All;
                Image = Import;
                ToolTip = 'Зберегти реальні факти без обов’язкової заявки, підтвердження обсягу чи готовності до проведення.';
                trigger OnAction()
                begin
                    RunCapture(Enum::"SI Prok Capture Mode"::Normal);
                end;
            }

            action(ClearTestFacts)
            {
                Caption = 'Очистити факти';
                ApplicationArea = All;
                Image = Delete;
                ToolTip = 'Адміністративне очищення фактів за періодом, режимом і Production ID. Архів JSON зберігається.';

                trigger OnAction()
                var
                    Params: Page "SI Prok Test Fact Clear Params";
                    ClearMgt: Codeunit "SI Prok Test Fact Clear Mgt.";
                    Deleted: Integer;
                begin
                    Params.SetDefaults(Today, Today);

                    if Params.RunModal() <> Action::OK then
                        exit;

                    Deleted := ClearMgt.ClearFacts(
                        Params.GetDateFrom(),
                        Params.GetDateTo(),
                        Params.GetFilterByStatus(),
                        Params.GetStatus(),
                        Params.GetCaptureMode(),
                        Params.GetProductionIdFilter());

                    CurrPage.Update(false);

                    Message(
                        'Видалено фактів: %1. Архів JSON збережено.',
                        Deleted);
                end;
            }

            action(OpenRawArchive)
            {
                Caption = 'Архів JSON Proktek';
                ApplicationArea = All;
                Image = Archive;
                RunObject = page "SI Prok Raw API Responses";
            }
        }
    }

    local procedure RunCapture(Mode: Enum "SI Prok Capture Mode")
    var
        Params: Page "SI Prok Prod Export Params";
        ConnectionMgt: Codeunit "SI Prok Connection Mgt.";
        Connection: Record "SI Prok Connection";
        CaptureMgt: Codeunit "SI Prok Capture Mgt.";
        Profile: Code[50];
        Imported: Integer;
        Existing: Integer;
        Conflicts: Integer;
        Failed: Integer;
    begin
        if ConnectionMgt.TryGetActive(Connection) then
            Profile := Connection.Code;
        Params.SetDefaults(Today, Today, Profile);
        if Params.RunModal() <> Action::OK then
            exit;
        if not Confirm('Отримати факти з профілю %1 у режимі %2? Capture не підтверджує м³ і не виконує проведення.',
            false, Params.GetConnectionCode(), Format(Mode)) then
            exit;
        CaptureMgt.CaptureWithMode(Params.GetDateFrom(), Params.GetDateTo(),
            Params.GetConnectionCode(), Mode, Imported, Existing, Conflicts, Failed);
        CurrPage.Update(false);
        Message('Нові: %1; незмінені: %2; конфлікти: %3; помилки: %4.',
            Imported, Existing, Conflicts, Failed);
    end;
}
