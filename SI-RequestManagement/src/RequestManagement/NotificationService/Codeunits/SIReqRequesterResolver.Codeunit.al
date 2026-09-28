codeunit 52037 "SI Req. Requester Resolver"
    implements "SI Recipient Resolver"
{
    procedure ResolveRecipients(
        BusinessEventEntry: Record "SI Business Event Entry";
        RecipientGroup: Record "SI Recipient Group";
        var TempRecipientBuffer: Record "SI Notif. Recipient Buffer" temporary)
    var
        RequestHeader: Record "SI Request Header";
        RecipientHelper: Codeunit "SI Req. Recipient Helper";
    begin
        RecipientHelper.GetRequestHeader(
            BusinessEventEntry,
            RequestHeader);

        RequestHeader.TestField(
            "Requester User ID");

        RecipientHelper.AddUserRecipient(
            BusinessEventEntry,
            RecipientGroup,
            RequestHeader."Requester User ID",
            StrSubstNo(
                RequesterTraceTxt,
                RequestHeader."No."),
            TempRecipientBuffer);
    end;

    [EventSubscriber(
        ObjectType::Codeunit,
        Codeunit::"SI Notification Dispatcher",
        'OnResolveRecipients',
        '',
        false,
        false)]
    local procedure OnResolveRecipients(
        BusinessEventEntry: Record "SI Business Event Entry";
        RecipientGroup: Record "SI Recipient Group";
        var TempRecipientBuffer: Record "SI Notif. Recipient Buffer" temporary;
        var IsHandled: Boolean)
    begin
        if IsHandled then
            exit;

        if RecipientGroup."Resolver Type" <>
           RecipientGroup."Resolver Type"::Requester
        then
            exit;

        ResolveRecipients(
            BusinessEventEntry,
            RecipientGroup,
            TempRecipientBuffer);

        IsHandled := true;
    end;

    var
        RequesterTraceTxt:
            Label 'Поле «Заявник» заявки %1.';
}