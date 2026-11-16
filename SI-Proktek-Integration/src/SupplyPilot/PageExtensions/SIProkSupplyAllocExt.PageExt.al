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

        }
    }
}
