codeunit 50423 "SI EDS Inbound API"
{
    /// <summary>
    /// OData V4 unbound action for durable acceptance of inbound events.
    ///
    /// The codeunit must be published as an OData V4 web service.
    ///
    /// Return value is JSON serialized as Text.
    /// Business Central wraps the returned Text into the standard
    /// OData response property "value".
    /// </summary>
    procedure AcceptInboundEvent(
        serviceCode: Code[50];
        eventId: Text[250];
        eventType: Code[50];
        sourceSystem: Code[50];
        sourceRecordId: Text[100];
        payloadJson: Text): Text
    var
        InboundMgt: Codeunit "SI EDS Inbound Mgt.";
        InboundEvent: Record "SI EDS Inbound Event";
        ResponseJson: JsonObject;
        ResponseText: Text;
        IsNew: Boolean;
    begin
        IsNew :=
            InboundMgt.AcceptEvent(
                serviceCode,
                eventId,
                eventType,
                sourceSystem,
                sourceRecordId,
                payloadJson,
                InboundEvent);

        ResponseJson.Add('accepted', true);
        ResponseJson.Add('duplicate', not IsNew);
        ResponseJson.Add('serviceCode', serviceCode);
        ResponseJson.Add('eventId', eventId);
        ResponseJson.Add('entryNo', InboundEvent."Entry No.");

        ResponseJson.WriteTo(ResponseText);

        exit(ResponseText);
    end;
}