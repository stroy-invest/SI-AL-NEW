pageextension 65000 "SI IW Vehicle Card Ext"
    extends "SI Vehicle Card"
{
    actions
    {
        addlast(Processing)
        {
            action(SyncVehicleToIW)
            {
                ApplicationArea = All;
                Caption = 'Синхронізувати з IW';
                ToolTip = 'Створити або оновити транспортний засіб у IW Foundation.';
                Image = Refresh;

                trigger OnAction()
                var
                    VehicleProjectionMgt: Codeunit "SI IW Vehicle Projection Mgt.";
                begin
                    CurrPage.SaveRecord();

                    VehicleProjectionMgt.PublishVehicle(Rec."No.");

                    Message(
                        'Транспортний засіб %1 успішно синхронізовано з IW.',
                        Rec."No.");
                end;
            }
        }
    }
}
