codeunit 50231 "SI Business Event Service"
{
    Permissions =
        tabledata "SI Business Event Definition" = R,
        tabledata "SI Business Event Entry" = RIM;

    procedure Publish(
        EventCode: Code[50];
        SourceRecordId: RecordId): BigInteger
    var
        Payload: JsonObject;
    begin
        exit(Publish(EventCode, SourceRecordId, Payload));
    end;

    procedure Publish(
        EventCode: Code[50];
        SourceRecordId: RecordId;
        Payload: JsonObject): BigInteger
    var
        BusinessEventDefinition: Record "SI Business Event Definition";
        BusinessEventEntry: Record "SI Business Event Entry";
        NotificationDispatcher: Codeunit "SI Notification Dispatcher";
    begin
        BusinessEventDefinition.Get(EventCode);
        BusinessEventDefinition.TestField(Active, true);

        CreateBusinessEventEntry(
            BusinessEventEntry,
            BusinessEventDefinition,
            SourceRecordId,
            Payload);

        if not NotificationDispatcher.TryProcess(BusinessEventEntry) then begin
            BusinessEventEntry.Get(BusinessEventEntry."Entry No.");

            NotificationDispatcher.MarkFailed(
                BusinessEventEntry,
                GetLastErrorText());

            ClearLastError();
        end;

        exit(BusinessEventEntry."Entry No.");
    end;

    local procedure CreateBusinessEventEntry(
        var BusinessEventEntry: Record "SI Business Event Entry";
        BusinessEventDefinition: Record "SI Business Event Definition";
        SourceRecordId: RecordId;
        Payload: JsonObject)
    var
        SourceRecordRef: RecordRef;
        PayloadOutStream: OutStream;
        PayloadText: Text;
    begin
        BusinessEventEntry.Init();

        BusinessEventEntry."Event Code" :=
            BusinessEventDefinition.Code;

        BusinessEventEntry.Status :=
            BusinessEventEntry.Status::New;

        BusinessEventEntry."Source Module" :=
            BusinessEventDefinition."Source Module";

        BusinessEventEntry."Payload Schema Version" :=
            BusinessEventDefinition."Payload Schema Version";

        if SourceRecordId.TableNo() <> 0 then begin
            SourceRecordRef.Get(SourceRecordId);

            BusinessEventEntry."Source Table ID" :=
                SourceRecordId.TableNo();

            BusinessEventEntry."Source Record ID" :=
                SourceRecordId;

            BusinessEventEntry."Source System ID" :=
                GetSourceSystemId(SourceRecordRef);

            BusinessEventEntry."Source Record Caption" :=
                CopyStr(
                    Format(SourceRecordId),
                    1,
                    MaxStrLen(
                        BusinessEventEntry."Source Record Caption"));
        end;

        Payload.WriteTo(PayloadText);

        if PayloadText <> '' then begin
            BusinessEventEntry.Payload.CreateOutStream(
                PayloadOutStream,
                TextEncoding::UTF8);

            PayloadOutStream.WriteText(PayloadText);
        end;

        BusinessEventEntry.Insert(true);
    end;

    local procedure GetSourceSystemId(
        SourceRecordRef: RecordRef): Guid
    var
        SystemIdFieldRef: FieldRef;
        SourceSystemId: Guid;
    begin
        SystemIdFieldRef :=
            SourceRecordRef.Field(
                SourceRecordRef.SystemIdNo());

        Evaluate(
            SourceSystemId,
            Format(SystemIdFieldRef.Value()));

        exit(SourceSystemId);
    end;
}