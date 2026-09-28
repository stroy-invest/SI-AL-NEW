page 50430 "SI EDS Inbound Evidence API"
{
    PageType = API;

    APIPublisher = 'stroyinvest';
    APIGroup = 'eds';
    APIVersion = 'v1.0';

    EntityName = 'inboundEvidence';
    EntitySetName = 'inboundEvidences';

    EntityCaption = 'Inbound Evidence';
    EntitySetCaption = 'Inbound Evidences';

    SourceTable = "SI EDS Inbound Evidence";

    ODataKeyFields = SystemId;

    DelayedInsert = true;

    InsertAllowed = true;
    ModifyAllowed = true;
    DeleteAllowed = false;

    Extensible = false;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }

                field(serviceCode; Rec."Service Code")
                {
                    Caption = 'Service Code';
                }

                field(evidenceId; Rec."Evidence ID")
                {
                    Caption = 'Evidence ID';
                }

                field(parentEventId; Rec."Parent Event ID")
                {
                    Caption = 'Parent Event ID';
                }

                field(sourceSystem; Rec."Source System")
                {
                    Caption = 'Source System';
                }

                field(sourceEvidenceId; Rec."Source Evidence ID")
                {
                    Caption = 'Source Evidence ID';
                }

                field(sourceSlot; Rec."Source Slot")
                {
                    Caption = 'Source Slot';
                }

                field(contentType; Rec."Content Type")
                {
                    Caption = 'Content Type';
                }

                field(fileSize; Rec."File Size")
                {
                    Caption = 'File Size';
                }

                field(sha256; Rec."SHA-256")
                {
                    Caption = 'SHA-256';
                }

                field(capturedAt; Rec."Captured At")
                {
                    Caption = 'Captured At';
                }

                //
                // Media field.
                //
                // Business Central exposes this field as a media resource.
                // After metadata registration the API response can provide
                // the corresponding OData media edit/read links.
                //
                /*
                field(evidenceContent; Rec.Content)
                {
                    Caption = 'Content';

                    trigger OnValidate()
                    var
                        InboundEvidenceMgt: Codeunit "SI EDS Inbound Evidence Mgt.";
                    begin
                        //
                        // PATCH of raw binary content ends here.
                        //
                        // Once Media has been durably persisted, move the
                        // evidence transport state from Registered to Received.
                        //
                        InboundEvidenceMgt.MarkContentReceived(Rec);
                    end;
                }
                */
                field(registeredAt; Rec."Registered At")
                {
                    Caption = 'Registered At';
                    Editable = false;
                }

                field(receivedAt; Rec."Received At")
                {
                    Caption = 'Received At';
                    Editable = false;
                }

                field(status; Rec.Status)
                {
                    Caption = 'Status';
                    Editable = false;
                }

                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified Date Time';
                    Editable = false;
                }
            }

            part(evidenceContent; "SI EDS Inb. Evid. Content API")
            {
                Caption = 'Evidence Content';
                SubPageLink = Id = field(SystemId);
                Multiplicity = ZeroOrOne;
            }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        InboundEvidenceMgt: Codeunit "SI EDS Inbound Evidence Mgt.";
        PersistedEvidence: Record "SI EDS Inbound Evidence";
        IsNew: Boolean;
    begin
        //
        // API POST is not allowed to bypass the EDS domain boundary.
        //
        // Registration must go through the management codeunit so that:
        //
        // - parent event existence is validated;
        // - EDS service is validated;
        // - canonical evidence identity is enforced;
        // - duplicate metadata is validated for immutability;
        // - concurrent duplicate insertion is handled safely.
        //
        IsNew :=
            InboundEvidenceMgt.RegisterEvidence(
                Rec."Service Code",
                Rec."Evidence ID",
                Rec."Parent Event ID",
                Rec."Source System",
                Rec."Source Evidence ID",
                Rec."Source Slot",
                Rec."Content Type",
                Rec."File Size",
                Rec."SHA-256",
                Rec."Captured At",
                PersistedEvidence);

        Rec := PersistedEvidence;

        //
        // RegisterEvidence already performs the physical Insert().
        //
        // Returning false prevents the API page runtime from inserting
        // the record a second time.
        //
        exit(false);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        //
        // Metadata is immutable after registration.
        //
        // The only supported external modification is the Media content
        // upload through the platform-generated media endpoint.
        //
        // The field-level content OnValidate trigger performs reception
        // finalization.
        //
        exit(true);
    end;
}