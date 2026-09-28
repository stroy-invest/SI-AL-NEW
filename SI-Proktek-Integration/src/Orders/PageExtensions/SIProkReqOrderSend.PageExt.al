pageextension 57030 "SI Prok Req Order Send" extends "SI Concrete Prod Req Card"
{

    actions
    {
        addlast(Processing)
        {
            action(ClearProktekOrder)
            {
                ApplicationArea = All;
                Caption = 'Очистити Proktek Order';
                Image = ClearLog;
                ToolTip = 'Очищає з виробничої заявки збережені ID/UUID та службові дані синхронізації Proktek Order. Використовувати для контрольованого повторного тесту.';

                trigger OnAction()
                begin
                    if not Confirm(
                        'Очистити прив\''язку заявки #%1 до Proktek Order?\Ця дія не видаляє Order у Proktek.',
                        false, Rec."Entry No.")
                    then
                        exit;

                    Rec."Proktek Order ID" := 0;
                    Clear(Rec."Proktek Order UUID");
                    Rec."Proktek Order Synced At" := 0DT;
                    Rec."Proktek Last Message" := '';
                    Rec.Modify(true);
                    CurrPage.Update(false);
                end;
            }

            action(SendProktekOrder)
            {
                ApplicationArea = All;
                Caption = 'Proktek: створити Order';
                Image = SendTo;
                ToolTip = 'Створює реальний Order у Proktek з поточної виробничої заявки.';

                trigger OnAction()
                var
                    OrderSync: Codeunit "SI Prok Order Sync";
                begin
                    CurrPage.SaveRecord();
                    OrderSync.SendOrder(Rec);
                    CurrPage.Update(false);
                end;
            }
        }
    }
}
