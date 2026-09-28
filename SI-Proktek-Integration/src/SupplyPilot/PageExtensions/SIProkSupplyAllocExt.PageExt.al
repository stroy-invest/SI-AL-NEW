pageextension 57076 "SI Prok Supply Alloc Ext" extends "SI Supply Allocations"
{
    actions
    {
        addlast(Processing)
        {
            action(SendAllocationToProktek)
            {
                ApplicationArea = All;
                Caption = 'Надіслати в Proktek';
                Image = SendTo;
                Enabled = Rec."Supply Method" = Rec."Supply Method"::Production;
                ToolTip = 'Перевіряє Customer, Site і Formula та створює Order у Proktek для виробничого розподілу.';

                trigger OnAction()
                var
                    SupplyOrderMgt: Codeunit "SI Prok Supply Order Mgt.";
                begin
                    CurrPage.SaveRecord();
                    SupplyOrderMgt.SendAllocation(Rec);
                    CurrPage.Update(false);
                end;
            }

            action(DiagnoseProktekOrder)
            {
                ApplicationArea = All;
                Caption = 'Діагностика Order Proktek';
                Image = ViewDetails;
                Enabled = Rec."Supply Method" = Rec."Supply Method"::Production;
                ToolTip = 'Виконує тільки GET-ORDERS і показує точний request/response, який використовує reconciliation. Нічого не створює і не змінює.';

                trigger OnAction()
                var
                    SupplyOrderMgt: Codeunit "SI Prok Supply Order Mgt.";
                begin
                    CurrPage.SaveRecord();
                    SupplyOrderMgt.ShowOrderDiagnostic(Rec);
                end;
            }

            action(ImportProktekProductionFact)
            {
                ApplicationArea = All;
                Caption = 'Отримати факт Proktek';
                Image = Import;
                Enabled = Rec."Supply Method" = Rec."Supply Method"::Production;
                ToolTip = 'Отримує фактичні виробництва для Proktek Order, корелює їх із розподілом та зберігає persistent Production Fact.';

                trigger OnAction()
                var
                    FactMgt: Codeunit "SI Prok Prod Fact Mgt.";
                    ImportedCount: Integer;
                    ExistingCount: Integer;
                begin
                    CurrPage.SaveRecord();
                    FactMgt.ImportForAllocation(Rec, ImportedCount, ExistingCount);
                    Message('Отримання завершено. Нових фактів: %1, вже існували: %2.', ImportedCount, ExistingCount);
                end;
            }

            action(SimulateProktekProdPart1)
            {
                ApplicationArea = All;
                Caption = 'Імітувати факт #1';
                Image = TestReport;
                Enabled = Rec."Supply Method" = Rec."Supply Method"::Production;
                ToolTip = 'PRODUCTION-01: формує перший частковий Production (75% Order), пропускає RAW JSON через штатний parser/correlation pipeline та зберігає persistent Production Fact.';

                trigger OnAction()
                var
                    Simulator: Codeunit "SI Prok Prod Simulator";
                begin
                    CurrPage.SaveRecord();
                    Simulator.RunForAllocation(Rec, 1);
                    CurrPage.Update(false);
                end;
            }

            action(SimulateProktekProdPart2)
            {
                ApplicationArea = All;
                Caption = 'Імітувати факт #2';
                Image = TestReport;
                Enabled = Rec."Supply Method" = Rec."Supply Method"::Production;
                ToolTip = 'PRODUCTION-01: формує другий Production на залишок 25% Order і перевіряє агрегування 1 Order → N Production Facts до Complete.';

                trigger OnAction()
                var
                    Simulator: Codeunit "SI Prok Prod Simulator";
                begin
                    CurrPage.SaveRecord();
                    Simulator.RunForAllocation(Rec, 2);
                    CurrPage.Update(false);
                end;
            }

            action(ReplayProktekProdPart2)
            {
                ApplicationArea = All;
                Caption = 'Повторити факт #2';
                Image = Refresh;
                Enabled = Rec."Supply Method" = Rec."Supply Method"::Production;
                ToolTip = 'Повторно подає той самий Production UUID #2 для перевірки idempotency. Новий Production Fact створюватися не повинен.';

                trigger OnAction()
                var
                    Simulator: Codeunit "SI Prok Prod Simulator";
                begin
                    CurrPage.SaveRecord();
                    Simulator.RunForAllocation(Rec, 3);
                    CurrPage.Update(false);
                end;
            }
        }
    }
}
