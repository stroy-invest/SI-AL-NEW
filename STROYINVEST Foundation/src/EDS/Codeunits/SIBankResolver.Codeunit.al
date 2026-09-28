codeunit 50445 "SI Bank Resolver"
{
    procedure ResolveByIBAN(
        IBAN: Text;
        var Bank: Record "SI Bank Directory"): Boolean
    var
        IBANMgt: Codeunit "SI IBAN Mgt.";
        NBUBankSyncMgt: Codeunit "SI NBU Bank Sync Mgt.";
        NBUId: Code[20];
    begin
        IBANMgt.ValidateUA(IBAN);

        NBUId := IBANMgt.GetNBUId(IBAN);

        if Bank.Get(NBUId) then
            exit(true);

        if not NBUBankSyncMgt.SyncBank(NBUId, Bank) then
            exit(false);

        exit(Bank.Get(NBUId));
    end;

    procedure ResolveByNBUId(
        NBUId: Code[20];
        var Bank: Record "SI Bank Directory"): Boolean
    var
        NBUBankSyncMgt: Codeunit "SI NBU Bank Sync Mgt.";
    begin
        if NBUId = '' then
            Error('Не зазначено ID НБУ.');

        if Bank.Get(NBUId) then
            exit(true);

        if not NBUBankSyncMgt.SyncBank(NBUId, Bank) then
            exit(false);

        exit(Bank.Get(NBUId));
    end;
}
