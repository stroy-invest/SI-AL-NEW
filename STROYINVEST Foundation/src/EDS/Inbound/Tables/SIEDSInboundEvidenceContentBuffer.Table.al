table 50432 "SI EDS Inb. Evid. Content Buf."
{
    Caption = 'EDS Inbound Evidence Content Buffer';
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Guid)
        {
            Caption = 'Id';
        }

        field(10; "Content Type"; Text[100])
        {
            Caption = 'Content Type';
        }

        //
        // IMPORTANT:
        //
        // This BLOB is an API transport buffer only.
        //
        // The final evidence content is stored in
        // SI EDS Inbound Evidence.Content : Media.
        //
        // Business Central exposes a BLOB field on an API resource
        // as an OData stream, following the same pattern used by
        // the standard Picture API.
        //
        field(20; Content; Blob)
        {
            Caption = 'Content';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; Id)
        {
            Clustered = true;
        }
    }

    /// <summary>
    /// Loads the persistent inbound evidence into the temporary
    /// API buffer.
    ///
    /// IdFilter is the SystemId of SI EDS Inbound Evidence,
    /// supplied by the parent API SubPageLink.
    ///
    /// If evidence content has already been received, the Media
    /// object is exported into the temporary BLOB so the same API
    /// resource can also serve raw binary GET requests.
    /// </summary>
    procedure LoadFromEvidence(IdFilter: Text)
    var
        InboundEvidence: Record "SI EDS Inbound Evidence";
        EvidenceSystemId: Guid;
        ContentOutStream: OutStream;
    begin
        if IdFilter = '' then
            Error(EvidenceIdRequiredErr);

        if not Evaluate(EvidenceSystemId, IdFilter) then
            Error(InvalidEvidenceIdErr, IdFilter);

        if not InboundEvidence.GetBySystemId(EvidenceSystemId) then
            Error(EvidenceNotFoundErr, IdFilter);

        Init();

        Id := InboundEvidence.SystemId;
        "Content Type" := InboundEvidence."Content Type";

        if not InboundEvidence.Content.HasValue() then
            exit;

        Content.CreateOutStream(ContentOutStream);
        InboundEvidence.Content.ExportStream(ContentOutStream);
    end;

    /// <summary>
    /// Persists the raw API BLOB stream into the canonical
    /// SI EDS Inbound Evidence.Content Media field.
    ///
    /// The persistent evidence record remains the source of truth;
    /// this buffer is temporary and has no business lifecycle of
    /// its own.
    /// </summary>
    procedure SaveToEvidence()
    var
        InboundEvidence: Record "SI EDS Inbound Evidence";
        InboundEvidenceMgt: Codeunit "SI EDS Inbound Evidence Mgt.";
        ContentInStream: InStream;
        MediaDescription: Text;
    begin
        if IsNullGuid(Id) then
            Error(EvidenceIdRequiredErr);

        if not InboundEvidence.GetBySystemId(Id) then
            Error(EvidenceNotFoundErr, Format(Id));

        //
        // Evidence delivery is idempotent.
        //
        // If Business Central has already durably received this
        // evidence, a repeated PATCH does not create another Media
        // object and does not change the canonical record.
        //
        if InboundEvidence.Status = InboundEvidence.Status::Received then
            exit;

        if InboundEvidence.Status <> InboundEvidence.Status::Registered then
            Error(
                InvalidEvidenceStatusErr,
                InboundEvidence."Evidence ID",
                Format(InboundEvidence.Status));

        //
        // IMPORTANT:
        //
        // Do NOT call CalcFields(Content) here.
        //
        // This record is a temporary API transport buffer.
        // During a raw OData media PATCH, Business Central has
        // already populated this BLOB in the current Rec buffer.
        //
        // Recalculating the BLOB here would reload its value from
        // the temporary table state instead of using the binary
        // stream supplied by the current HTTP request.
        //
        if not Content.HasValue() then
            Error(
                ContentMissingErr,
                InboundEvidence."Evidence ID");

        Content.CreateInStream(ContentInStream);

        MediaDescription :=
            StrSubstNo(
                EvidenceMediaDescriptionLbl,
                InboundEvidence."Evidence ID");

        //
        // Import the transport BLOB into Business Central Tenant Media.
        //
        // The MIME type comes from the immutable evidence metadata
        // registered before the binary upload.
        //
        InboundEvidence.Content.ImportStream(
            ContentInStream,
            MediaDescription,
            InboundEvidence."Content Type");

        //
        // MarkContentReceived() verifies that Media now exists and
        // performs the durable:
        //
        //     Registered -> Received
        //
        // transition together with Received At.
        //
        InboundEvidenceMgt.MarkContentReceived(InboundEvidence);
    end;

    var
        EvidenceIdRequiredErr: Label 'Inbound Evidence Id is required.';
        InvalidEvidenceIdErr: Label 'Inbound Evidence Id %1 is not a valid GUID.';
        EvidenceNotFoundErr: Label 'Inbound Evidence with SystemId %1 does not exist.';
        InvalidEvidenceStatusErr: Label 'Inbound Evidence %1 cannot receive content while its status is %2.';
        ContentMissingErr: Label 'No binary content was supplied for Inbound Evidence %1.';
        EvidenceMediaDescriptionLbl: Label 'EDS inbound evidence %1';
}