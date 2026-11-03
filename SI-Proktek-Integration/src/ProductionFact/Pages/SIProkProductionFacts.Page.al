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
                field("Produced Quantity M3"; Rec."Produced Quantity M3") { ApplicationArea = All; }
                field("Order Produced Total M3"; Rec."Order Produced Total M3") { ApplicationArea = All; }
                field("Order Remaining M3"; Rec."Order Remaining M3") { ApplicationArea = All; }
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
                var
                    Params: Page "SI Prok Prod Export Params";
                    ConnectionMgt: Codeunit "SI Prok Connection Mgt.";
                    ActiveConnection: Record "SI Prok Connection";
                    CaptureMgt: Codeunit "SI Prok Capture Mgt.";
                    Profile: Code[50];
                    Imported: Integer;
                    Existing: Integer;
                    Failed: Integer;
                begin
                    if ConnectionMgt.TryGetActive(ActiveConnection) then Profile := ActiveConnection.Code;
                    Params.SetDefaults(Today, Today, Profile);
                    if Params.RunModal() <> Action::OK then exit;
                    if not Confirm('Режим ТЕСТ: отримати факти з профілю %1 без проведень?', false, Params.GetConnectionCode()) then exit;
                    CaptureMgt.Capture(Params.GetDateFrom(), Params.GetDateTo(), Params.GetConnectionCode(), Imported, Existing, Failed);
                    CurrPage.Update(false);
                    Message('Отримано: %1; вже існували: %2; помилки: %3.', Imported, Existing, Failed);
                end;
            }
            action(ClearTestFacts)
            {
                Caption = 'Очистити тестові факти';
                ApplicationArea = All;
                Image = Delete;
                ToolTip = 'Видаляє лише факти з режимом приймання Тест та їхні рядки матеріалів за вибраний період і, за потреби, статус. Архів JSON не змінюється.';

                trigger OnAction()
                var
                    Params: Page "SI Prok Test Fact Clear Params";
                    ClearMgt: Codeunit "SI Prok Test Fact Clear Mgt.";
                    Deleted: Integer;
                begin
                    Params.SetDefaults(Today, Today);
                    if Params.RunModal() <> Action::OK then
                        exit;

                    Deleted := ClearMgt.ClearTestFacts(
                        Params.GetDateFrom(), Params.GetDateTo(),
                        Params.GetFilterByStatus(), Params.GetStatus());
                    CurrPage.Update(false);
                    Message('Видалено тестових фактів: %1. Архів JSON збережено.', Deleted);
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
}
