interface "SI Recipient Resolver"
{
    procedure ResolveRecipients(
        BusinessEventEntry: Record "SI Business Event Entry";
        RecipientGroup: Record "SI Recipient Group";
        var TempRecipientBuffer: Record "SI Notif. Recipient Buffer" temporary);
}
/*
Контракт навмисно не залежить від SI Request Management.

Майбутні реалізації:

    Explicit User Resolver
    User Group Resolver
    Request Requester Resolver
    Request Current Approver Resolver
    Salesperson Resolver
    Document Owner Resolver

повертатимуть результат в один стандартний temporary buffer
*/
