codeunit 59150 "SI WB Test Data Cleanup"
{
    procedure CleanupSandboxData()
    var
        WeighbridgeDocument: Record "SI Weighbridge Document";
        DocumentCreationQueue: Record "SI WB Document Creation Queue";
        WeighingRecord: Record "SI Weighing Record";
        InboundEvidence: Record "SI EDS Inbound Evidence";
        InboundEvent: Record "SI EDS Inbound Event";
        DeletedDocumentCount: Integer;
        DeletedQueueCount: Integer;
        DeletedWeighingCount: Integer;
        DeletedEvidenceCount: Integer;
        DeletedInboundCount: Integer;
    begin
        if not Confirm(
            ConfirmCleanupQst,
            false)
        then
            exit;

        DeletedQueueCount :=
            DocumentCreationQueue.Count();

        if DeletedQueueCount > 0 then
            DocumentCreationQueue.DeleteAll(true);

        DeletedDocumentCount :=
            WeighbridgeDocument.Count();

        if DeletedDocumentCount > 0 then
            WeighbridgeDocument.DeleteAll(true);

        DeletedWeighingCount :=
            WeighingRecord.Count();

        if DeletedWeighingCount > 0 then
            WeighingRecord.DeleteAll(true);

        InboundEvidence.SetRange(
            "Service Code",
            WeighbridgeServiceCodeLbl);

        DeletedEvidenceCount :=
            InboundEvidence.Count();

        if DeletedEvidenceCount > 0 then
            InboundEvidence.DeleteAll(true);

        InboundEvent.SetRange(
            "Service Code",
            WeighbridgeServiceCodeLbl);

        DeletedInboundCount :=
            InboundEvent.Count();

        if DeletedInboundCount > 0 then
            InboundEvent.DeleteAll(true);

        Message(
            CleanupCompletedMsg,
            DeletedQueueCount,
            DeletedDocumentCount,
            DeletedWeighingCount,
            DeletedEvidenceCount,
            DeletedInboundCount);
    end;

    var
        WeighbridgeServiceCodeLbl: Label 'WEIGHBRIDGE', Locked = true;

        ConfirmCleanupQst: Label 'УВАГА! Будуть видалені ВСІ тестові дані вагової в поточній компанії:\- черга створення операційних документів;\- операційні документи вагової;\- записи зважувань;\- EDS evidence для WEIGHBRIDGE;\- EDS inbound events для WEIGHBRIDGE.\\Налаштування EDS, Service, Endpoint, credentials та інші інтеграції НЕ видаляються.\\Продовжити?';

        CleanupCompletedMsg: Label 'Очищення завершено.\\Черга створення документів: %1\Операційні документи: %2\Зважування: %3\Evidence: %4\Inbound events: %5';
}