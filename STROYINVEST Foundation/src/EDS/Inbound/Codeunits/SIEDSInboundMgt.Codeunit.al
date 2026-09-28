codeunit 50422 "SI EDS Inbound Mgt."
{
    /// <summary>
    /// Accepts an inbound event into the durable EDS inbound store.
    ///
    /// Return value:
    ///   true  - a new inbound event was created;
    ///   false - the event had already been accepted earlier.
    ///
    /// Duplicate delivery is treated as successful technical acceptance.
    /// This is required by the at-least-once delivery contract.
    /// </summary>
    procedure AcceptEvent(
        ServiceCode: Code[50];
        EventId: Text[250];
        EventType: Code[50];
        SourceSystem: Code[50];
        SourceRecordId: Text[100];
        PayloadText: Text;
        var InboundEvent: Record "SI EDS Inbound Event"): Boolean
    begin
        ValidateRequest(
            ServiceCode,
            EventId,
            EventType,
            SourceSystem,
            PayloadText);

        // Fast-path duplicate check.
        //
        // This is not the final concurrency guarantee.
        // The unique key on Service Code + Event ID remains the
        // authoritative protection against duplicate persistence.
        if FindExistingEvent(ServiceCode, EventId, InboundEvent) then
            exit(false);

        Clear(InboundEvent);
        InboundEvent.Init();

        InboundEvent."Service Code" := ServiceCode;
        InboundEvent."Event ID" := EventId;
        InboundEvent."Event Type" := EventType;
        InboundEvent."Source System" := SourceSystem;
        InboundEvent."Source Record ID" := SourceRecordId;
        InboundEvent.Status := InboundEvent.Status::Accepted;
        InboundEvent."Received At" := CurrentDateTime();
        InboundEvent.SetPayload(PayloadText);

        if TryInsertInboundEvent(InboundEvent) then
            exit(true);

        // Another request may have inserted the same event between
        // our initial duplicate check and Insert().
        //
        // In that case the event is already durably accepted and
        // must be returned to the producer as a successful duplicate.
        if FindExistingEvent(ServiceCode, EventId, InboundEvent) then
            exit(false);

        // Insert failed for some reason other than duplicate identity.
        // Do not ACK the producer.
        Error(
            InboundInsertFailedErr,
            ServiceCode,
            EventId,
            GetLastErrorText());
    end;

    procedure FindExistingEvent(
        ServiceCode: Code[50];
        EventId: Text[250];
        var InboundEvent: Record "SI EDS Inbound Event"): Boolean
    begin
        Clear(InboundEvent);
        InboundEvent.SetRange("Service Code", ServiceCode);
        InboundEvent.SetRange("Event ID", EventId);

        exit(InboundEvent.FindFirst());
    end;

    local procedure ValidateRequest(
        ServiceCode: Code[50];
        EventId: Text[250];
        EventType: Code[50];
        SourceSystem: Code[50];
        PayloadText: Text)
    var
        EDSService: Record "SI EDS Service";
    begin
        if ServiceCode = '' then
            Error(ServiceCodeRequiredErr);

        if EventId = '' then
            Error(EventIdRequiredErr);

        if EventType = '' then
            Error(EventTypeRequiredErr);

        if SourceSystem = '' then
            Error(SourceSystemRequiredErr);

        if PayloadText = '' then
            Error(PayloadRequiredErr);

        if not EDSService.Get(ServiceCode) then
            Error(ServiceNotFoundErr, ServiceCode);
    end;

    [TryFunction]
    local procedure TryInsertInboundEvent(
        var InboundEvent: Record "SI EDS Inbound Event")
    begin
        InboundEvent.Insert(true);
    end;

    var
        ServiceCodeRequiredErr: Label 'EDS Service Code is required.';
        EventIdRequiredErr: Label 'Inbound Event ID is required.';
        EventTypeRequiredErr: Label 'Inbound Event Type is required.';
        SourceSystemRequiredErr: Label 'Inbound Source System is required.';
        PayloadRequiredErr: Label 'Inbound event payload is required.';
        ServiceNotFoundErr: Label 'EDS Service %1 does not exist.';
        InboundInsertFailedErr: Label 'Failed to persist EDS inbound event. Service: %1, Event ID: %2. Error: %3';
}