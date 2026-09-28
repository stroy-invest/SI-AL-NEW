page 50431 "SI EDS Inb. Evid. Content API"
{
    PageType = API;

    APIPublisher = 'stroyinvest';
    APIGroup = 'eds';
    APIVersion = 'v1.0';

    EntityName = 'evidenceContent';
    EntitySetName = 'evidenceContents';

    EntityCaption = 'Inbound Evidence Content';
    EntitySetCaption = 'Inbound Evidence Contents';

    //
    // IMPORTANT:
    //
    // This API works through a temporary BLOB buffer.
    //
    // The permanent binary content is stored in:
    //
    //     SI EDS Inbound Evidence.Content : Media
    //
    // This follows the same general pattern as the standard
    // Business Central Pictures API.
    //
    SourceTable = "SI EDS Inb. Evid. Content Buf.";
    SourceTableTemporary = true;

    ODataKeyFields = Id;

    DelayedInsert = true;

    InsertAllowed = false;
    ModifyAllowed = true;
    DeleteAllowed = false;

    Extensible = false;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(id; Rec.Id)
                {
                    Caption = 'Id';
                    Editable = false;
                }

                field(contentType; Rec."Content Type")
                {
                    Caption = 'Content Type';
                    Editable = false;
                }

                //
                // OData stream property.
                //
                // Unlike the previous implementation, this field
                // is a BLOB in a temporary API buffer rather than
                // the permanent Media field itself.
                //
                field(evidenceContent; Rec.Content)
                {
                    Caption = 'Evidence Content';
                }
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    var
        EvidenceIdFilter: Text;
    begin
        //
        // The parent inboundEvidence API supplies:
        //
        //     Id = parent SystemId
        //
        // through SubPageLink.
        //
        // API pages can place the SubPageLink filter in filter
        // group 4, therefore check both the normal and API filter
        // groups. This mirrors the standard BC Pictures API pattern.
        //
        if not DataLoaded then begin
            EvidenceIdFilter := Rec.GetFilter(Id);

            if EvidenceIdFilter = '' then begin
                Rec.FilterGroup(4);
                EvidenceIdFilter := Rec.GetFilter(Id);
                Rec.FilterGroup(0);

                if EvidenceIdFilter = '' then
                    Error(ParentNotSpecifiedErr);
            end;

            Rec.LoadFromEvidence(EvidenceIdFilter);

            //
            // SourceTableTemporary = true.
            // This inserts only into the temporary API buffer.
            //
            Rec.Insert(true);

            DataLoaded := true;
        end;

        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        //
        // At this point Business Central has populated Rec.Content
        // with the raw HTTP request body.
        //
        // SaveToEvidence() imports the BLOB stream into the
        // persistent Media field and finalizes the technical
        // delivery lifecycle.
        //
        Rec.SaveToEvidence();

        //
        // Persistence has already been performed explicitly.
        // Do not ask the API runtime to modify a permanent record:
        // Rec is only a temporary transport buffer.
        //
        exit(false);
    end;

    var
        DataLoaded: Boolean;
        ParentNotSpecifiedErr: Label 'You must access inbound evidence content through its parent inbound evidence resource.';
}