codeunit 50234 "SI Explicit User Resolver"
    implements "SI Recipient Resolver"
{
    Permissions =
        tabledata User = R;

    procedure ResolveRecipients(
        BusinessEventEntry: Record "SI Business Event Entry";
        RecipientGroup: Record "SI Recipient Group";
        var TempRecipientBuffer: Record "SI Notif. Recipient Buffer" temporary)
    var
        UserRecord: Record User;
    begin
        RecipientGroup.TestField("Provider Code");

        UserRecord.SetRange(
            "User Name",
            RecipientGroup."Provider Code");

        if not UserRecord.FindFirst() then
            Error(
                UserNotFoundErr,
                RecipientGroup."Provider Code",
                RecipientGroup.Code);

        AddRecipient(
            BusinessEventEntry,
            RecipientGroup,
            UserRecord,
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
           RecipientGroup."Resolver Type"::ExplicitUser
        then
            exit;

        ResolveRecipients(
            BusinessEventEntry,
            RecipientGroup,
            TempRecipientBuffer);

        IsHandled := true;
    end;

    local procedure AddRecipient(
        BusinessEventEntry: Record "SI Business Event Entry";
        RecipientGroup: Record "SI Recipient Group";
        UserRecord: Record User;
        var TempRecipientBuffer: Record "SI Notif. Recipient Buffer" temporary)
    begin
        TempRecipientBuffer.Init();

        TempRecipientBuffer."Entry No." :=
            GetNextEntryNo(TempRecipientBuffer);

        TempRecipientBuffer."Security ID" :=
            UserRecord."User Security ID";

        TempRecipientBuffer."User Name" :=
            CopyStr(
                UserRecord."User Name",
                1,
                MaxStrLen(TempRecipientBuffer."User Name"));

        TempRecipientBuffer."Display Name" :=
            CopyStr(
                UserRecord."Full Name",
                1,
                MaxStrLen(TempRecipientBuffer."Display Name"));

        TempRecipientBuffer."Recipient Group Code" :=
            RecipientGroup.Code;

        TempRecipientBuffer."Resolver Type" :=
            RecipientGroup."Resolver Type";

        TempRecipientBuffer."Provider Code" :=
            RecipientGroup."Provider Code";

        TempRecipientBuffer.Active := true;

        TempRecipientBuffer."Resolution Trace" :=
            CopyStr(
                StrSubstNo(
                    ResolutionTraceTxt,
                    RecipientGroup.Code,
                    RecipientGroup."Provider Code",
                    UserRecord."User Name",
                    UserRecord."User Security ID",
                    BusinessEventEntry."Entry No."),
                1,
                MaxStrLen(
                    TempRecipientBuffer."Resolution Trace"));

        TempRecipientBuffer."Source Reference" :=
            CopyStr(
                Format(UserRecord.RecordId()),
                1,
                MaxStrLen(
                    TempRecipientBuffer."Source Reference"));

        TempRecipientBuffer.Insert();
    end;

    local procedure GetNextEntryNo(
        var TempRecipientBuffer: Record "SI Notif. Recipient Buffer" temporary): Integer
    begin
        TempRecipientBuffer.Reset();

        if TempRecipientBuffer.FindLast() then
            exit(TempRecipientBuffer."Entry No." + 1);

        exit(1);
    end;

    var
        UserNotFoundErr:
            Label 'Користувача %1, зазначеного для групи отримувачів %2, не знайдено.';

        ResolutionTraceTxt:
            Label 'Група: %1; провайдер: %2; визначено користувача: %3; Security ID: %4; бізнес-подія: %5.';
}