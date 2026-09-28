codeunit 52038 "SI Req. Curr. Appr. Resolver"
    implements "SI Recipient Resolver"
{
    procedure ResolveRecipients(
        BusinessEventEntry: Record "SI Business Event Entry";
        RecipientGroup: Record "SI Recipient Group";
        var TempRecipientBuffer: Record "SI Notif. Recipient Buffer" temporary)
    var
        RequestHeader: Record "SI Request Header";
        CurrentApprovalEntry: Record "Approval Entry";
        RecipientHelper: Codeunit "SI Req. Recipient Helper";
    begin
        RecipientHelper.GetRequestHeader(
            BusinessEventEntry,
            RequestHeader);

        if not RecipientHelper.GetCurrentOpenApprovalEntry(
            RequestHeader,
            CurrentApprovalEntry)
        then
            Error(
                CurrentApproverNotFoundErr,
                RequestHeader."No.");

        CurrentApprovalEntry.TestField(
            "Approver ID");

        RecipientHelper.AddUserRecipient(
            BusinessEventEntry,
            RecipientGroup,
            CurrentApprovalEntry."Approver ID",
            StrSubstNo(
                CurrentApproverTraceTxt,
                RequestHeader."No.",
                CurrentApprovalEntry."Entry No.",
                CurrentApprovalEntry."Sequence No."),
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
           RecipientGroup."Resolver Type"::CurrentApprover
        then
            exit;

        ResolveRecipients(
            BusinessEventEntry,
            RecipientGroup,
            TempRecipientBuffer);

        IsHandled := true;
    end;

    var
        CurrentApproverNotFoundErr:
            Label 'Для заявки %1 не знайдено відкритого погодження.';

        CurrentApproverTraceTxt:
            Label 'Відкрите погодження заявки %1: запис %2, послідовність %3.';
}