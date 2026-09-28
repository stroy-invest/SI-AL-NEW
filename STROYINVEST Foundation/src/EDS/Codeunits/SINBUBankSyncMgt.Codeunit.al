codeunit 50443 "SI NBU Bank Sync Mgt."
{
    procedure SyncDirectory(
        var InsertedCount: Integer;
        var UpdatedCount: Integer;
        var DeactivatedCount: Integer)
    var
        EDSOrchestrator: Codeunit "SI EDS Orchestrator";
        NBUResolver: Codeunit "SI NBU Bank Resolver";
        ResponseBuffer: Record "SI EDS Response Buffer" temporary;
        SyncRunId: Guid;
        SyncAt: DateTime;
    begin
        SyncRunId := CreateGuid();
        SyncAt := CurrentDateTime;

        EDSOrchestrator.Execute(
            NBUServiceCodeLbl,
            BankDirectoryOperationLbl,
            ResponseBuffer);

        EnsureSuccess(ResponseBuffer);

        NBUResolver.ApplyDirectoryResponse(
            ResponseBuffer,
            SyncRunId,
            SyncAt,
            InsertedCount,
            UpdatedCount);

        DeactivatedCount :=
            NBUResolver.DeactivateMissing(SyncRunId);
    end;

    procedure SyncBank(
        NBUId: Code[20];
        var Bank: Record "SI Bank Directory"): Boolean
    var
        EDSOrchestrator: Codeunit "SI EDS Orchestrator";
        NBUResolver: Codeunit "SI NBU Bank Resolver";
        RuntimeParam: Record "SI EDS Runtime Param" temporary;
        ResponseBuffer: Record "SI EDS Response Buffer" temporary;
        SyncRunId: Guid;
        SyncAt: DateTime;
        InsertedCount: Integer;
        UpdatedCount: Integer;
    begin
        if NBUId = '' then
            Error('Не зазначено ID НБУ.');

        RuntimeParam.Add(
            NBUIdRuntimeKeyLbl,
            NBUId);

        EDSOrchestrator.Execute(
            NBUServiceCodeLbl,
            BankDirectoryOperationLbl,
            RuntimeParam,
            ResponseBuffer);

        EnsureSuccess(ResponseBuffer);

        SyncRunId := CreateGuid();
        SyncAt := CurrentDateTime;

        NBUResolver.ApplyDirectoryResponse(
            ResponseBuffer,
            SyncRunId,
            SyncAt,
            InsertedCount,
            UpdatedCount);

        if (InsertedCount + UpdatedCount) = 0 then
            exit(false);

        if (InsertedCount + UpdatedCount) > 1 then
            Error(
                'НБУ повернув більше одного банку для ID НБУ %1.',
                NBUId);

        if not Bank.Get(NBUId) then
            exit(false);

        exit(Bank."Last Sync Run ID" = SyncRunId);
    end;

    local procedure EnsureSuccess(
        var ResponseBuffer: Record "SI EDS Response Buffer" temporary)
    begin
        if ResponseBuffer."Result Type" =
           ResponseBuffer."Result Type"::Success
        then
            exit;

        Error(
            'Синхронізацію з НБУ не виконано. %1 %2',
            ResponseBuffer."Error Code",
            ResponseBuffer."Error Message");
    end;

    var
        NBUServiceCodeLbl: Label 'NBU', Locked = true;
        BankDirectoryOperationLbl: Label 'BANK_DIRECTORY', Locked = true;
        NBUIdRuntimeKeyLbl: Label 'NBU_ID', Locked = true;
}