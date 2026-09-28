codeunit 52039 "SI Req. Next Appr. Resolver"
    implements "SI Recipient Resolver"
{
    procedure ResolveRecipients(
        BusinessEventEntry: Record "SI Business Event Entry";
        RecipientGroup: Record "SI Recipient Group";
        var TempRecipientBuffer: Record "SI Notif. Recipient Buffer" temporary)
    var
        RequestHeader: Record "SI Request Header";
        RecipientHelper: Codeunit "SI Req. Recipient Helper";
        NextApproverId: Code[50];
    begin
        RecipientHelper.GetRequestHeader(
            BusinessEventEntry,
            RequestHeader);

        if not RecipientHelper.GetNextApproverId(
            RequestHeader,
            NextApproverId)
        then
            exit;

        RecipientHelper.AddUserRecipient(
            BusinessEventEntry,
            RecipientGroup,
            NextApproverId,
            StrSubstNo(
                NextApproverTraceTxt,
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
           RecipientGroup."Resolver Type"::NextApprover
        then
            exit;

        ResolveRecipients(
            BusinessEventEntry,
            RecipientGroup,
            TempRecipientBuffer);

        IsHandled := true;
    end;

    var
        NextApproverTraceTxt:
            Label 'Поле «Погоджувач» у налаштуванні поточного погоджувача заявки %1.';
}