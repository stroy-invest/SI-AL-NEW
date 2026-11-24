pageextension 57120 "SI Prok Vehicle Card Ext" extends "SI Vehicle Card"
{
    actions
    {
        addlast(Processing)
        {
            group(ProktekIntegration)
            {
                Caption = 'Proktek';
                Image = Integration;
                action(ProkSyncOneMixer)
                {
                    ApplicationArea = All;
                    Caption = 'Синхронізувати міксер із Proktek';
                    Image = Refresh;
                    trigger OnAction()
                    var
                        Connection: Record "SI Prok Connection";
                        Manager: Codeunit "SI Prok Mixer Sync Manager";
                    begin
                        CurrPage.SaveRecord();
                        Rec.TestField("No.");
                        Rec.TestField("Vehicle Type Code", 'CONCRETE-MIXER');
                        if not SelectConnection(Connection) then
                            exit;
                        if not Confirm('Синхронізувати міксер %1 через підключення %2 (середовище %3)?', false,
                            Rec."No.", Connection.Code, Format(Connection.Environment)) then
                            exit;
                        Manager.SyncOne(Connection.Code, Rec."No.");
                        CurrPage.Update(false);
                        Message('Синхронізацію міксера %1 завершено. Відповідність Proktek оновлено.', Rec."No.");
                    end;
                }
                action(ProkOpenVehicleMappings)
                {
                    ApplicationArea = All;
                    Caption = 'Відповідності Proktek';
                    Image = Link;
                    trigger OnAction()
                    var
                        Mapping: Record "SI Prok Vehicle Mapping";
                    begin
                        Rec.TestField("No.");
                        Mapping.SetRange("Vehicle No.", Rec."No.");
                        Page.Run(Page::"SI Prok Vehicle Mappings", Mapping);
                    end;
                }
            }
        }
    }
    local procedure SelectConnection(var Connection: Record "SI Prok Connection"): Boolean
    var
        ConnectionList: Page "SI Prok Connections";
    begin
        Connection.Reset();
        ConnectionList.LookupMode(true);
        ConnectionList.SetTableView(Connection);
        if ConnectionList.RunModal() <> Action::LookupOK then
            exit(false);
        ConnectionList.GetRecord(Connection);
        exit(Connection.Code <> '');
    end;
}
