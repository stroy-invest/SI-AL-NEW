page 57091 "SI Prok Production Facts"
{
    PageType = List;
    SourceTable = "SI Prok Production Fact";
    Caption = 'Факти виробництва Proktek (технічний список)';
    ApplicationArea = All;
    UsageCategory = None;
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
                field("Truck Code"; Rec."Truck Code") { ApplicationArea = All; }
                field("Truck Plate"; Rec."Truck Plate") { ApplicationArea = All; }
                field(ReportedQuantity; Rec.GetReportedQuantityText()) { ApplicationArea = All; Caption = 'Заявлено MES, м³'; Editable = false; ToolTip = 'Переданий MES обсяг; не є підтвердженням виробництва. Для історії читається canonical без зміни запису.'; }
                field(ReportedPresence; Rec.GetReportedPresenceText()) { ApplicationArea = All; Caption = 'Обсяг MES передано'; Editable = false; ToolTip = 'Для історичних записів первинну наявність значення не оцінено.'; }
                field("Technical Validation"; Rec."Technical Validation") { ApplicationArea = All; }
                field("Verification Status"; Rec."Verification Status") { ApplicationArea = All; }
                field("Execution Evidence"; Rec."Execution Evidence") { ApplicationArea = All; }
                field("Verification Message"; Rec."Verification Message") { ApplicationArea = All; }
                field(ProducedQuantity; Rec.GetProducedQuantityText()) { ApplicationArea = All; Caption = 'Підтверджено, м³'; Editable = false; ToolTip = 'Не підтверджено означає відсутність підтвердженого обсягу, а не доведений нуль виробництва.'; }
                field(ConfirmedOrderTotal; Rec.GetOrderTotalText()) { ApplicationArea = All; Caption = 'Підтверджено по Order, м³'; Editable = false; ToolTip = 'Сума підтвердженого випуску за Order UUID у межах конкретного підключення.'; }
                field(ReportedOrderTotal; Rec.GetReportedOrderTotalText()) { ApplicationArea = All; Caption = 'Заявлено MES по Order, м³'; Editable = false; ToolTip = 'Операційний підсумок MES за Order UUID у межах підключення, не підтверджений випуск.'; }
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
            action(RecoverProductionFact)
            {
                Caption = 'Прив’язати до заявки та повторити обробку';
                ApplicationArea = All;
                AccessByPermission = codeunit "SI Prok Fact Recovery" = X;
                trigger OnAction()
                var Recovery: Codeunit "SI Prok Fact Recovery";
                begin
                    Recovery.RecoverFact(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(OpenFactHierarchy)
            {
                Caption = 'Факти за заявками (ієрархія)';
                ApplicationArea = All;
                Image = List;
                RunObject = page "SI Prok Fact Hierarchy";
            }
            action(ExportPeriodPlanFact)
            {
                Caption = 'Підсумковий план/факт за період';
                ApplicationArea = All;
                Image = ExportToExcel;
                ToolTip = 'Звіт по всіх виробничих фактах за вибраний період, незалежно від виділення рядків.';
                trigger OnAction()
                var
                    Params: Page "SI Prok PF Sum Period";
                    Exporter: Codeunit "SI Prok PF Period Summary";
                begin
                    Params.SetDefaults(Today, Today);
                    Params.RunModal();
                    if Params.WasAccepted() then
                        Exporter.Export(Params.GetFromDate(), Params.GetToDate());
                end;
            }

            action(CaptureNormal)
            {
                Caption = 'Отримати факти';
                ApplicationArea = All;
                Image = Import;
                ToolTip = 'Зберегти реальні факти без обов’язкової заявки, підтвердження обсягу чи готовності до проведення.';
                trigger OnAction()
                begin
                    RunCapture(false);
                end;
            }

            action(CaptureRefresh)
            {
                Caption = 'Повторно отримати факти з Proktek';
                ApplicationArea = All;
                Image = Import;
                AccessByPermission = codeunit "SI Prok Fact Recovery" = X;
                ToolTip = 'Примусово отримує деталі за період; застосовує наявну перевірку конфліктів. Не перезаписує виробничі дані.';
                trigger OnAction()
                begin
                    RunCapture(true);
                end;
            }

            action(AuditFactShipmentIntegrity)
            {
                Caption = 'Аудит фактів і відвантажень (лише читання)';
                ApplicationArea = All;
                Image = Check;
                ToolTip = 'Перевіряє відсутні Shipment, ідентичність, кількості, будмайданчики й адреси. Не змінює даних.';
                trigger OnAction()
                var
                    Audit: Codeunit "SI Prok Fact Shipment Audit";
                begin
                    Audit.RunReadOnly();
                end;
            }

            action(CreateMissingShipments)
            {
                Caption = 'Створити відсутні документи відвантаження';
                ApplicationArea = All;
                Image = Create;
                ToolTip = 'Створює відсутні відкриті Shipment для вибраних/відфільтрованих фактів з Production UUID. Без повторного створення і без проведення.';
                trigger OnAction()
                var
                    SelectedFact: Record "SI Prok Production Fact";
                    ShipmentMgt: Codeunit "SI Prok Shipment Mgt.";
                    Shipment: Record "SI Prok Shipment";
                    Created: Integer;
                    Skipped: Integer;
                    Revision: Record "SI Concrete Recipe Revision";
                begin
                    CurrPage.SetSelectionFilter(SelectedFact);
                    if not Confirm('Створити відсутні документи відвантаження для вибраних/відфільтрованих фактів (%1 записів)? Проведення не виконується.',
                        false, SelectedFact.Count()) then
                        exit;
                    if SelectedFact.FindSet() then
                        repeat
                            Shipment.Reset();
                            Shipment.SetRange("Production UUID", SelectedFact."Production UUID");
                            if (SelectedFact."Produced Quantity M3" <= 0) or not Shipment.IsEmpty() then
                                Skipped += 1
                            else
                                if not Revision.Get(SelectedFact."Recipe No.", SelectedFact."Recipe Revision No.") then
                                    Error('Факт %1: редакцію рецептури %2/%3 не знайдено.', SelectedFact."Entry No.", SelectedFact."Recipe No.", SelectedFact."Recipe Revision No.")
                                else
                                    if Revision."Recipe Purpose" <> Revision."Recipe Purpose"::Commercial then
                                        Skipped += 1
                                    else begin
                                        ShipmentMgt.EnsureForFact(SelectedFact."Entry No.");
                                        Created += 1;
                                    end;
                        until SelectedFact.Next() = 0;
                    Message('Створено Shipment: %1; пропущено (наявні, нульовий випуск або технологічна рецептура): %2.', Created, Skipped);
                end;
            }

            action(OpenSimFactDeletionAudit)
            {
                Caption = 'Аудит видалення фактів';
                ApplicationArea = All;
                Image = Log;
                RunObject = page "SI Prok Sim Fact Del Audit";
            }

            action(DeleteSelectedSimulatedFacts)
            {
                Caption = 'Адміністративно видалити вибрані факти';
                ApplicationArea = All;
                Image = Delete;
                ToolTip = 'Видаляє лише явно виділені факти, без пов’язаних документів; записує аудит.';
                trigger OnAction()
                var
                    SelectedFacts: Record "SI Prok Production Fact";
                    DeleteMgt: Codeunit "SI Prok Sim Fact Admin Delete";
                    Deleted: Integer;
                begin
                    CurrPage.SetSelectionFilter(SelectedFacts);
                    Deleted := DeleteMgt.DeleteSelected(SelectedFacts);
                    if Deleted > 0 then begin
                        CurrPage.Update(false);
                        Message('Адміністративно видалено фактів: %1. Аудит збережено.', Deleted);
                    end;
                end;
            }

            action(ClearTestFacts)
            {
                Caption = 'Очистити факти';
                Visible = false; // PROD-safe: live production facts must not be deleted.
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
            action(AuditConcreteIdentity)
            {
                Caption = 'Аудит бетону в історичних фактах';
                ApplicationArea = All;
                Image = ViewDetails;
                ToolTip = 'Тільки читання: знаходить факти без Item/назви/M3 і Shipment із порожнім або невідповідним бетоном. Проведені дані не змінює.';
                trigger OnAction()
                var
                    ConcreteGuard: Codeunit "SI Prok Concrete Identity";
                begin
                    ConcreteGuard.AuditExisting();
                end;
            }
        }
    }

    local procedure RunCapture(ForceRefresh: Boolean)
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
        if not Confirm('Отримати факти з профілю %1? Приймання не підтверджує м³ і не виконує проведення.',
            false, Params.GetConnectionCode()) then
            exit;
        if ForceRefresh then begin
            if not Confirm('Примусово повторити API-запити за весь вибраний період?', false) then
                exit;
            CaptureMgt.CaptureRefresh(Params.GetDateFrom(), Params.GetDateTo(), Params.GetConnectionCode(), Imported, Existing, Conflicts, Failed);
        end else
            CaptureMgt.CaptureWithMode(Params.GetDateFrom(), Params.GetDateTo(),
                Params.GetConnectionCode(), Enum::"SI Prok Capture Mode"::Normal, Imported, Existing, Conflicts, Failed);
        CurrPage.Update(false);
        Message('Нові: %1; наявні: %2; конфлікти: %3; помилки: %4.',
            Imported, Existing, Conflicts, Failed);
    end;
}
