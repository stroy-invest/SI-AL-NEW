codeunit 59051 "SI WB Inbound Worker"
{
    TableNo = "SI EDS Inbound Event";

    trigger OnRun()
    begin
        ProcessInboundEvent(Rec);
    end;

    local procedure ProcessInboundEvent(
        var InboundEvent: Record "SI EDS Inbound Event")
    var
        WeighingRecord: Record "SI Weighing Record";
        RootJson: JsonObject;
        SourceJson: JsonObject;
        EventJson: JsonObject;
        WeighingJson: JsonObject;
        TransportJson: JsonObject;
        PayloadText: Text;
        SourceOperationType: Integer;
    begin
        if InboundEvent.Status <> InboundEvent.Status::Processing then
            Error(
                'EDS inbound event %1 має статус %2. Очікувався статус Processing.',
                InboundEvent."Entry No.",
                Format(InboundEvent.Status));

        if InboundEvent."Event Type" <> CompletedEventType() then
            Error(
                'EDS inbound event %1 має непідтримуваний тип події %2.',
                InboundEvent."Entry No.",
                InboundEvent."Event Type");

        // ------------------------------------------------------------
        // Domain idempotency
        //
        // EDS already guarantees unique Service Code + Event ID.
        // Here we additionally guarantee that one EDS Entry No.
        // cannot create more than one SI Weighing Record.
        // ------------------------------------------------------------

        WeighingRecord.Reset();
        WeighingRecord.SetRange(
            "Inbound Entry No.",
            InboundEvent."Entry No.");

        if WeighingRecord.FindFirst() then begin
            // --------------------------------------------------------
            // Compatibility/backfill for weighing records created
            // before source.operationType was introduced.
            //
            // Integer 0 cannot by itself distinguish:
            //   - real PromSoft type_operation = 0
            //   - legacy record where the property was never parsed.
            //
            // Therefore the Present flag is authoritative.
            // --------------------------------------------------------

            EnsureSourceOperationType(
                InboundEvent,
                WeighingRecord);

            MarkProcessed(InboundEvent);
            exit;
        end;

        PayloadText := InboundEvent.GetPayload();

        if PayloadText = '' then
            Error(
                'EDS inbound event %1 не містить payload.',
                InboundEvent."Entry No.");

        if not RootJson.ReadFrom(PayloadText) then
            Error(
                'EDS inbound event %1 містить некоректний JSON.',
                InboundEvent."Entry No.");

        GetRequiredObject(
            RootJson,
            'source',
            SourceJson);

        GetRequiredObject(
            RootJson,
            'event',
            EventJson);

        GetRequiredObject(
            RootJson,
            'weighing',
            WeighingJson);

        GetRequiredObject(
            RootJson,
            'transport',
            TransportJson);

        // ------------------------------------------------------------
        // Cross-check envelope vs payload
        // ------------------------------------------------------------

        if GetRequiredText(
            EventJson,
            'type') <> CompletedEventType()
        then
            Error(
                'Тип події у payload (%1) не відповідає EDS Event Type (%2).',
                GetRequiredText(EventJson, 'type'),
                InboundEvent."Event Type");

        // ------------------------------------------------------------
        // Required raw PromSoft operation type.
        //
        // Business interpretation is deliberately NOT taken from Edge.
        // Edge transports the raw value as source.operationType.
        //
        // BC owns the business contract:
        //     0 -> Receipt
        //     1 -> Shipment
        //
        // Any other value is invalid input.
        // ------------------------------------------------------------

        SourceOperationType :=
            GetRequiredInteger(
                SourceJson,
                'operationType');

        ValidateSourceOperationType(
            SourceOperationType);

        // ------------------------------------------------------------
        // Create technological weighing fact
        // ------------------------------------------------------------

        WeighingRecord.Init();

        // ------------------------------------------------------------
        // EDS traceability
        // ------------------------------------------------------------

        WeighingRecord."Inbound Entry No." :=
            InboundEvent."Entry No.";

        WeighingRecord."External Event ID" := CopyStr(
            GetRequiredText(
                RootJson,
                'eventId'),
            1,
            MaxStrLen(
                WeighingRecord."External Event ID"));

        WeighingRecord."Source Event Type" := CopyStr(
            GetRequiredText(
                EventJson,
                'type'),
            1,
            MaxStrLen(
                WeighingRecord."Source Event Type"));

        // ------------------------------------------------------------
        // Source
        // ------------------------------------------------------------

        WeighingRecord."Source System" := CopyStr(
            GetRequiredText(
                SourceJson,
                'system'),
            1,
            MaxStrLen(
                WeighingRecord."Source System"));

        WeighingRecord."Site Code" := CopyStr(
            GetRequiredText(
                SourceJson,
                'site'),
            1,
            MaxStrLen(
                WeighingRecord."Site Code"));

        WeighingRecord."Source Table" := CopyStr(
            GetRequiredText(
                SourceJson,
                'table'),
            1,
            MaxStrLen(
                WeighingRecord."Source Table"));

        WeighingRecord."Source Record ID" :=
            GetRequiredBigInteger(
                SourceJson,
                'recordId');

        WeighingRecord."Scale No." :=
            GetRequiredInteger(
                SourceJson,
                'scale');

        WeighingRecord."Source Operation Type" :=
            SourceOperationType;

        WeighingRecord."Source Operation Type Present" :=
            true;

        WeighingRecord."Source Evidence Record ID" :=
            GetOptionalBigInteger(
                SourceJson,
                'evidenceRecordId');

        // ------------------------------------------------------------
        // Event
        // ------------------------------------------------------------

        WeighingRecord."Event Date/Time" :=
            GetRequiredDateTime(
                EventJson,
                'detectedAt');

        // ------------------------------------------------------------
        // Physical weighing fact
        // ------------------------------------------------------------

        WeighingRecord."Gross Weight" :=
            GetRequiredDecimal(
                WeighingJson,
                'grossKg');

        WeighingRecord."Tare Weight" :=
            GetRequiredDecimal(
                WeighingJson,
                'tareKg');

        WeighingRecord."Net Weight" :=
            GetRequiredDecimal(
                WeighingJson,
                'netKg');

        // ------------------------------------------------------------
        // Raw source plate values.
        //
        // Effective values are initialized in
        // SI Weighing Record.OnInsert().
        // ------------------------------------------------------------

        WeighingRecord."Source Vehicle Plate" := CopyStr(
            GetOptionalText(
                TransportJson,
                'vehiclePlate'),
            1,
            MaxStrLen(
                WeighingRecord."Source Vehicle Plate"));

        WeighingRecord."Source Trailer Plate" := CopyStr(
            GetOptionalText(
                TransportJson,
                'trailerPlate'),
            1,
            MaxStrLen(
                WeighingRecord."Source Trailer Plate"));

        WeighingRecord.Insert(true);

        MarkProcessed(InboundEvent);
    end;

    local procedure EnsureSourceOperationType(
        InboundEvent: Record "SI EDS Inbound Event";
        var WeighingRecord: Record "SI Weighing Record")
    var
        RootJson: JsonObject;
        SourceJson: JsonObject;
        PayloadText: Text;
        SourceOperationType: Integer;
    begin
        if WeighingRecord."Source Operation Type Present" then begin
            ValidateSourceOperationType(
                WeighingRecord."Source Operation Type");

            exit;
        end;

        PayloadText := InboundEvent.GetPayload();

        if PayloadText = '' then
            Error(
                'EDS inbound event %1 не містить payload.',
                InboundEvent."Entry No.");

        if not RootJson.ReadFrom(PayloadText) then
            Error(
                'EDS inbound event %1 містить некоректний JSON.',
                InboundEvent."Entry No.");

        GetRequiredObject(
            RootJson,
            'source',
            SourceJson);

        SourceOperationType :=
            GetRequiredInteger(
                SourceJson,
                'operationType');

        ValidateSourceOperationType(
            SourceOperationType);

        WeighingRecord."Source Operation Type" :=
            SourceOperationType;

        WeighingRecord."Source Operation Type Present" :=
            true;

        WeighingRecord.Modify(true);
    end;

    local procedure ValidateSourceOperationType(
        SourceOperationType: Integer)
    begin
        case SourceOperationType of
            0,
            1:
                exit;
            else
                Error(
                    'Некоректний PromSoft source.operationType: %1. Очікується 0 або 1.',
                    SourceOperationType);
        end;
    end;

    local procedure MarkProcessed(
        var InboundEvent: Record "SI EDS Inbound Event")
    begin
        InboundEvent.Status :=
            InboundEvent.Status::Processed;

        InboundEvent."Processed At" :=
            CurrentDateTime();

        InboundEvent.SetLastError('');

        InboundEvent.Modify(true);
    end;

    local procedure CompletedEventType(): Code[50]
    begin
        exit('WEIGHING_COMPLETED');
    end;

    local procedure GetRequiredObject(
        ParentJson: JsonObject;
        PropertyName: Text;
        var ChildJson: JsonObject)
    var
        JsonToken: JsonToken;
    begin
        if not ParentJson.Get(
            PropertyName,
            JsonToken)
        then
            Error(
                'JSON property "%1" відсутня.',
                PropertyName);

        if not JsonToken.IsObject() then
            Error(
                'JSON property "%1" повинна бути object.',
                PropertyName);

        ChildJson :=
            JsonToken.AsObject();
    end;

    local procedure GetRequiredText(
        JsonObj: JsonObject;
        PropertyName: Text): Text
    var
        JsonToken: JsonToken;
    begin
        GetRequiredValueToken(
            JsonObj,
            PropertyName,
            JsonToken);

        exit(
            JsonToken
                .AsValue()
                .AsText());
    end;

    local procedure GetOptionalText(
        JsonObj: JsonObject;
        PropertyName: Text): Text
    var
        JsonToken: JsonToken;
    begin
        if not JsonObj.Get(
            PropertyName,
            JsonToken)
        then
            exit('');

        if not JsonToken.IsValue() then
            exit('');

        if JsonToken.AsValue().IsNull() then
            exit('');

        exit(
            JsonToken
                .AsValue()
                .AsText());
    end;

    local procedure GetRequiredBigInteger(
        JsonObj: JsonObject;
        PropertyName: Text): BigInteger
    var
        JsonToken: JsonToken;
    begin
        GetRequiredValueToken(
            JsonObj,
            PropertyName,
            JsonToken);

        exit(
            JsonToken
                .AsValue()
                .AsBigInteger());
    end;

    local procedure GetOptionalBigInteger(
        JsonObj: JsonObject;
        PropertyName: Text): BigInteger
    var
        JsonToken: JsonToken;
    begin
        if not JsonObj.Get(
            PropertyName,
            JsonToken)
        then
            exit(0);

        if not JsonToken.IsValue() then
            exit(0);

        if JsonToken.AsValue().IsNull() then
            exit(0);

        exit(
            JsonToken
                .AsValue()
                .AsBigInteger());
    end;

    local procedure GetRequiredInteger(
        JsonObj: JsonObject;
        PropertyName: Text): Integer
    var
        JsonToken: JsonToken;
    begin
        GetRequiredValueToken(
            JsonObj,
            PropertyName,
            JsonToken);

        exit(
            JsonToken
                .AsValue()
                .AsInteger());
    end;

    local procedure GetRequiredDecimal(
        JsonObj: JsonObject;
        PropertyName: Text): Decimal
    var
        JsonToken: JsonToken;
    begin
        GetRequiredValueToken(
            JsonObj,
            PropertyName,
            JsonToken);

        exit(
            JsonToken
                .AsValue()
                .AsDecimal());
    end;

    local procedure GetRequiredDateTime(
        JsonObj: JsonObject;
        PropertyName: Text): DateTime
    var
        JsonToken: JsonToken;
    begin
        GetRequiredValueToken(
            JsonObj,
            PropertyName,
            JsonToken);

        exit(
            JsonToken
                .AsValue()
                .AsDateTime());
    end;

    local procedure GetRequiredValueToken(
        JsonObj: JsonObject;
        PropertyName: Text;
        var JsonToken: JsonToken)
    begin
        if not JsonObj.Get(
            PropertyName,
            JsonToken)
        then
            Error(
                'JSON property "%1" відсутня.',
                PropertyName);

        if not JsonToken.IsValue() then
            Error(
                'JSON property "%1" повинна містити scalar value.',
                PropertyName);

        if JsonToken.AsValue().IsNull() then
            Error(
                'JSON property "%1" не може бути null.',
                PropertyName);
    end;
}