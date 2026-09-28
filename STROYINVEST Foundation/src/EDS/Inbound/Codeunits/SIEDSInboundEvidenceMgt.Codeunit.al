codeunit 50428 "SI EDS Inbound Evidence Mgt."
{
    /// <summary>
    /// Registers inbound evidence metadata.
    ///
    /// This operation does NOT mean that the binary content has already
    /// been received by Business Central.
    ///
    /// Return value:
    ///   true  - new evidence metadata record was created;
    ///   false - the same immutable evidence was already registered.
    ///
    /// Canonical evidence identity:
    ///
    ///     Service Code + Evidence ID
    ///
    /// Binary content is uploaded separately through the Media API.
    /// </summary>
    procedure RegisterEvidence(
        ServiceCode: Code[50];
        EvidenceId: Text[250];
        ParentEventId: Text[250];
        SourceSystem: Code[50];
        SourceEvidenceId: Text[100];
        SourceSlot: Integer;
        ContentType: Text[100];
        FileSize: BigInteger;
        Sha256: Text[64];
        CapturedAt: DateTime;
        var InboundEvidence: Record "SI EDS Inbound Evidence"): Boolean
    var
        ParentEvent: Record "SI EDS Inbound Event";
    begin
        ValidateRequest(
            ServiceCode,
            EvidenceId,
            ParentEventId,
            SourceSystem,
            SourceSlot,
            ContentType,
            FileSize,
            Sha256);

        FindParentEvent(
            ServiceCode,
            ParentEventId,
            ParentEvent);

        //
        // Fast-path idempotency check.
        //
        if FindExistingEvidence(
            ServiceCode,
            EvidenceId,
            InboundEvidence)
        then begin
            ValidateDuplicate(
                InboundEvidence,
                ParentEventId,
                SourceSystem,
                SourceEvidenceId,
                SourceSlot,
                ContentType,
                FileSize,
                Sha256);

            exit(false);
        end;

        Clear(InboundEvidence);
        InboundEvidence.Init();

        InboundEvidence."Service Code" := ServiceCode;
        InboundEvidence."Evidence ID" := EvidenceId;
        InboundEvidence."Parent Event ID" := ParentEventId;
        InboundEvidence."Source System" := SourceSystem;
        InboundEvidence."Source Evidence ID" := SourceEvidenceId;
        InboundEvidence."Source Slot" := SourceSlot;
        InboundEvidence."Content Type" := ContentType;
        InboundEvidence."File Size" := FileSize;
        InboundEvidence."SHA-256" := LowerCase(Sha256);
        InboundEvidence."Captured At" := CapturedAt;
        InboundEvidence."Registered At" := CurrentDateTime();
        InboundEvidence.Status := InboundEvidence.Status::Registered;

        if TryInsertInboundEvidence(InboundEvidence) then
            exit(true);

        //
        // Concurrency path:
        //
        // another request may have inserted the same canonical
        // Evidence ID after our first duplicate check.
        //
        if FindExistingEvidence(
            ServiceCode,
            EvidenceId,
            InboundEvidence)
        then begin
            ValidateDuplicate(
                InboundEvidence,
                ParentEventId,
                SourceSystem,
                SourceEvidenceId,
                SourceSlot,
                ContentType,
                FileSize,
                Sha256);

            exit(false);
        end;

        Error(
            InboundInsertFailedErr,
            ServiceCode,
            EvidenceId,
            GetLastErrorText());
    end;

    /// <summary>
    /// Marks evidence as physically received after its Media content
    /// has been durably persisted.
    ///
    /// This is the technical ACK boundary for evidence delivery.
    /// </summary>
    procedure MarkContentReceived(
        var InboundEvidence: Record "SI EDS Inbound Evidence")
    begin
        InboundEvidence.TestField("Service Code");
        InboundEvidence.TestField("Evidence ID");

        if not InboundEvidence.Content.HasValue() then
            Error(
                EvidenceContentMissingErr,
                InboundEvidence."Evidence ID");

        //
        // Idempotent finalization.
        //
        if InboundEvidence.Status = InboundEvidence.Status::Received then
            exit;

        if InboundEvidence.Status <> InboundEvidence.Status::Registered then
            Error(
                InvalidReceptionStatusErr,
                InboundEvidence."Evidence ID",
                Format(InboundEvidence.Status));

        InboundEvidence.Status := InboundEvidence.Status::Received;
        InboundEvidence."Received At" := CurrentDateTime();
        InboundEvidence.Modify(true);
    end;

    procedure FindExistingEvidence(
        ServiceCode: Code[50];
        EvidenceId: Text[250];
        var InboundEvidence: Record "SI EDS Inbound Evidence"): Boolean
    begin
        Clear(InboundEvidence);
        InboundEvidence.SetRange("Service Code", ServiceCode);
        InboundEvidence.SetRange("Evidence ID", EvidenceId);

        exit(InboundEvidence.FindFirst());
    end;

    procedure FindParentEvent(
        ServiceCode: Code[50];
        ParentEventId: Text[250];
        var ParentEvent: Record "SI EDS Inbound Event")
    begin
        Clear(ParentEvent);
        ParentEvent.SetRange("Service Code", ServiceCode);
        ParentEvent.SetRange("Event ID", ParentEventId);

        if ParentEvent.FindFirst() then
            exit;

        Error(
            ParentEventNotFoundErr,
            ServiceCode,
            ParentEventId);
    end;

    local procedure ValidateRequest(
        ServiceCode: Code[50];
        EvidenceId: Text[250];
        ParentEventId: Text[250];
        SourceSystem: Code[50];
        SourceSlot: Integer;
        ContentType: Text[100];
        FileSize: BigInteger;
        Sha256: Text[64])
    var
        EDSService: Record "SI EDS Service";
    begin
        if ServiceCode = '' then
            Error(ServiceCodeRequiredErr);

        if EvidenceId = '' then
            Error(EvidenceIdRequiredErr);

        if ParentEventId = '' then
            Error(ParentEventIdRequiredErr);

        if SourceSystem = '' then
            Error(SourceSystemRequiredErr);

        if SourceSlot < 0 then
            Error(SourceSlotInvalidErr, SourceSlot);

        if ContentType = '' then
            Error(ContentTypeRequiredErr);

        if FileSize <= 0 then
            Error(FileSizeInvalidErr, FileSize);

        if Sha256 = '' then
            Error(Sha256RequiredErr);

        if StrLen(Sha256) <> 64 then
            Error(Sha256LengthErr);

        if not EDSService.Get(ServiceCode) then
            Error(ServiceNotFoundErr, ServiceCode);
    end;

    local procedure ValidateDuplicate(
        InboundEvidence: Record "SI EDS Inbound Evidence";
        ParentEventId: Text[250];
        SourceSystem: Code[50];
        SourceEvidenceId: Text[100];
        SourceSlot: Integer;
        ContentType: Text[100];
        FileSize: BigInteger;
        Sha256: Text[64])
    begin
        //
        // Same canonical Evidence ID may only refer to the exact same
        // immutable evidence.
        //

        if InboundEvidence."Parent Event ID" <> ParentEventId then
            Error(
                DuplicateConflictErr,
                InboundEvidence."Evidence ID",
                'Parent Event ID');

        if InboundEvidence."Source System" <> SourceSystem then
            Error(
                DuplicateConflictErr,
                InboundEvidence."Evidence ID",
                'Source System');

        if InboundEvidence."Source Evidence ID" <> SourceEvidenceId then
            Error(
                DuplicateConflictErr,
                InboundEvidence."Evidence ID",
                'Source Evidence ID');

        if InboundEvidence."Source Slot" <> SourceSlot then
            Error(
                DuplicateConflictErr,
                InboundEvidence."Evidence ID",
                'Source Slot');

        if InboundEvidence."Content Type" <> ContentType then
            Error(
                DuplicateConflictErr,
                InboundEvidence."Evidence ID",
                'Content Type');

        if InboundEvidence."File Size" <> FileSize then
            Error(
                DuplicateConflictErr,
                InboundEvidence."Evidence ID",
                'File Size');

        if LowerCase(InboundEvidence."SHA-256") <> LowerCase(Sha256) then
            Error(
                DuplicateConflictErr,
                InboundEvidence."Evidence ID",
                'SHA-256');
    end;

    [TryFunction]
    local procedure TryInsertInboundEvidence(
        var InboundEvidence: Record "SI EDS Inbound Evidence")
    begin
        InboundEvidence.Insert(true);
    end;

    var
        ServiceCodeRequiredErr: Label 'EDS Service Code is required.';
        EvidenceIdRequiredErr: Label 'Inbound Evidence ID is required.';
        ParentEventIdRequiredErr: Label 'Parent Event ID is required.';
        SourceSystemRequiredErr: Label 'Inbound Source System is required.';
        SourceSlotInvalidErr: Label 'Source Slot %1 is invalid.';
        ContentTypeRequiredErr: Label 'Evidence Content Type is required.';
        FileSizeInvalidErr: Label 'Evidence File Size must be greater than zero. Value: %1.';
        Sha256RequiredErr: Label 'Evidence SHA-256 is required.';
        Sha256LengthErr: Label 'Evidence SHA-256 must contain exactly 64 characters.';
        ServiceNotFoundErr: Label 'EDS Service %1 does not exist.';
        ParentEventNotFoundErr: Label 'Parent inbound event does not exist. Service: %1, Event ID: %2.';
        DuplicateConflictErr: Label 'Inbound Evidence %1 already exists with conflicting %2.';
        EvidenceContentMissingErr: Label 'Inbound Evidence %1 does not contain media content.';
        InvalidReceptionStatusErr: Label 'Inbound Evidence %1 cannot be marked as received while its status is %2.';
        InboundInsertFailedErr: Label 'Failed to persist EDS inbound evidence. Service: %1, Evidence ID: %2. Error: %3';
}