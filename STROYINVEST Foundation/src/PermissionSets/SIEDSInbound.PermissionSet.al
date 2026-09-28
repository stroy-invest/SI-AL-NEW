permissionset 50426 "SI EDS INBOUND"
{
    Assignable = true;
    Caption = 'SI EDS: Inbound';

    Permissions =
        // AcceptInboundEvent validates that the configured EDS service exists.
        tabledata "SI EDS Service" = R,

        // Edge may only read existing inbound events for idempotency
        // and insert newly accepted events.
        //
        // No Modify/Delete permission is required for the ingress boundary.
        tabledata "SI EDS Inbound Event" = RI,

        // External OData entry point.
        codeunit "SI EDS Inbound API" = X,

        // Durable acceptance / idempotency service called by the API codeunit.
        codeunit "SI EDS Inbound Mgt." = X,

        //
        // Evidence metadata and final Media persistence.
        //
        // Modify is required because binary reception changes:
        //
        //     Registered -> Received
        //
        // and stores the Media object on the evidence record.
        //
        tabledata "SI EDS Inbound Evidence" = RIM,

        // Evidence registration and lifecycle management.
        codeunit "SI EDS Inbound Evidence Mgt." = X,

        // Evidence metadata API.
        page "SI EDS Inbound Evidence API" = X,

        //
        // Temporary BLOB transport buffer used by the binary content API.
        //
        // No Delete permission is required.
        //
        tabledata "SI EDS Inb. Evid. Content Buf." = RIM,

        // Raw binary evidence content API.
        page "SI EDS Inb. Evid. Content API" = X;
}