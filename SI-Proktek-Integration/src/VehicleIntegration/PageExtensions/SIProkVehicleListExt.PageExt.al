pageextension 57121 "SI Prok Vehicle List Ext" extends "SI Vehicle List"
{
    actions
    {
        addlast(Processing)
        {
            group(ProktekIntegration)
            {
                Caption = 'Proktek';
                Image = Integration;
                action(ProkSyncAllMixers)
                {
                    ApplicationArea = All;
                    Caption = 'Синхронізувати всі міксери з Proktek';
                    Image = Refresh;
                    trigger OnAction()
                    var
                        Connection: Record "SI Prok Connection";
                        Manager: Codeunit "SI Prok Mixer Sync Manager";
                    begin
                        if not SelectConnection(Connection) then
                            exit;
                        if not Confirm('Синхронізувати ВСІ міксери типу CONCRETE-MIXER через %1 (середовище %2)?', false,
                            Connection.Code, Format(Connection.Environment)) then
                            exit;
                        Manager.SyncAll(Connection.Code);
                        CurrPage.Update(false);
                    end;
                }
                action(ProkOpenMappings)
                {
                    ApplicationArea = All;
                    Caption = 'Відповідності Proktek';
                    Image = Link;
                    RunObject = page "SI Prok Vehicle Mappings";
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
