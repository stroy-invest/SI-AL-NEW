codeunit 52042 "SI Req. Assign. Appr. Resolver"
    implements "SI Recipient Resolver"
{
    procedure ResolveRecipients(
        BusinessEventEntry: Record "SI Business Event Entry";
        RecipientGroup: Record "SI Recipient Group";
        var TempRecipientBuffer: Record "SI Notif. Recipient Buffer" temporary)
    var
        RequestRecipientHelper: Codeunit "SI Req. Recipient Helper";
        PayloadInStream: InStream;
        PayloadText: Text;
        PayloadJson: JsonObject;
        ApproverToken: JsonToken;
        ApproverId: Code[50];
    begin
        BusinessEventEntry.CalcFields(Payload);

        if not BusinessEventEntry.Payload.HasValue() then
            Error(
                MissingPayloadErr,
                BusinessEventEntry."Entry No.");

        BusinessEventEntry.Payload.CreateInStream(
            PayloadInStream,
            TextEncoding::UTF8);

        PayloadInStream.ReadText(PayloadText);

        if PayloadText = '' then
            Error(
                MissingPayloadErr,
                BusinessEventEntry."Entry No.");

        if not PayloadJson.ReadFrom(PayloadText) then
            Error(
                InvalidPayloadErr,
                BusinessEventEntry."Entry No.");

        if not PayloadJson.Get(
            'approverId',
            ApproverToken)
        then
            Error(
                ApproverIdMissingErr,
                BusinessEventEntry."Entry No.");

        if not ApproverToken.IsValue() then
            Error(
                ApproverIdInvalidErr,
                BusinessEventEntry."Entry No.");

        ApproverId :=
            CopyStr(
                ApproverToken.AsValue().AsText(),
                1,
                MaxStrLen(ApproverId));

        if ApproverId = '' then
            Error(
                ApproverIdMissingErr,
                BusinessEventEntry."Entry No.");

        RequestRecipientHelper.AddUserRecipient(
            BusinessEventEntry,
            RecipientGroup,
            ApproverId,
            AssignedApproverResolutionLbl,
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
           RecipientGroup."Resolver Type"::AssignedApprover
        then
            exit;

        ResolveRecipients(
            BusinessEventEntry,
            RecipientGroup,
            TempRecipientBuffer);

        IsHandled := true;
    end;

    var
        MissingPayloadErr:
            Label 'Для бізнес-події %1 не знайдено payload.';

        InvalidPayloadErr:
            Label 'Payload бізнес-події %1 має некоректний JSON.';

        ApproverIdMissingErr:
            Label 'У payload бізнес-події %1 не знайдено approverId.';

        ApproverIdInvalidErr:
            Label 'Значення approverId у payload бізнес-події %1 має некоректний формат.';

        AssignedApproverResolutionLbl:
            Label 'Assigned Approver',
            Locked = true;
}