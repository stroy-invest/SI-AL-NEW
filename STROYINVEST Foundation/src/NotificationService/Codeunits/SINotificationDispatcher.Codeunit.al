codeunit 50232 "SI Notification Dispatcher"
{
    Permissions =
        tabledata "SI Business Event Definition" = R,
        tabledata "SI Recipient Group" = R,
        tabledata "SI Business Event Entry" = RM,
        tabledata "SI Notification Entry" = RIM;

    [TryFunction]
    procedure TryProcess(
        var BusinessEventEntry: Record "SI Business Event Entry")
    begin
        Process(BusinessEventEntry);
    end;

    procedure MarkFailed(
        var BusinessEventEntry: Record "SI Business Event Entry";
        ErrorMessage: Text)
    begin
        BusinessEventEntry.Status :=
            BusinessEventEntry.Status::Failed;

        BusinessEventEntry."Completed At" :=
            CurrentDateTime();

        BusinessEventEntry."Error Message" :=
            CopyStr(
                ErrorMessage,
                1,
                MaxStrLen(BusinessEventEntry."Error Message"));

        BusinessEventEntry.Modify(true);
    end;

    local procedure Process(
        var BusinessEventEntry: Record "SI Business Event Entry")
    var
        BusinessEventDefinition: Record "SI Business Event Definition";
        RecipientGroup: Record "SI Recipient Group";
        TempRecipientBuffer: Record "SI Notif. Recipient Buffer" temporary;
        Payload: JsonObject;
        SeenRecipients: Dictionary of [Guid, Boolean];
        NotificationCount: Integer;
        SkippedCount: Integer;
        IsHandled: Boolean;
    begin
        BusinessEventDefinition.Get(
            BusinessEventEntry."Event Code");

        BusinessEventDefinition.TestField(Active, true);
        BusinessEventDefinition.TestField("Recipient Group Code");

        RecipientGroup.Get(
            BusinessEventDefinition."Recipient Group Code");

        RecipientGroup.TestField(Active, true);

        MarkProcessing(BusinessEventEntry);

        LoadPayload(
            BusinessEventEntry,
            Payload);

        OnResolveRecipients(
            BusinessEventEntry,
            RecipientGroup,
            TempRecipientBuffer,
            IsHandled);

        if not IsHandled then begin
            MarkSkipped(
                BusinessEventEntry,
                NoRecipientResolverErr);
            exit;
        end;

        ProcessRecipients(
            BusinessEventEntry,
            BusinessEventDefinition,
            RecipientGroup,
            Payload,
            TempRecipientBuffer,
            SeenRecipients,
            NotificationCount,
            SkippedCount);

        FinalizeEvent(
            BusinessEventEntry,
            NotificationCount,
            SkippedCount);
    end;

    local procedure LoadPayload(
        var BusinessEventEntry: Record "SI Business Event Entry";
        var Payload: JsonObject)
    var
        PayloadInStream: InStream;
    begin
        Clear(Payload);

        BusinessEventEntry.CalcFields(Payload);

        if not BusinessEventEntry.Payload.HasValue() then
            exit;

        BusinessEventEntry.Payload.CreateInStream(
            PayloadInStream,
            TextEncoding::UTF8);

        if not Payload.ReadFrom(PayloadInStream) then
            Error(
                InvalidPayloadErr,
                BusinessEventEntry."Entry No.",
                BusinessEventEntry."Event Code");
    end;

    local procedure ProcessRecipients(
        BusinessEventEntry: Record "SI Business Event Entry";
        BusinessEventDefinition: Record "SI Business Event Definition";
        RecipientGroup: Record "SI Recipient Group";
        Payload: JsonObject;
        var TempRecipientBuffer: Record "SI Notif. Recipient Buffer" temporary;
        var SeenRecipients: Dictionary of [Guid, Boolean];
        var NotificationCount: Integer;
        var SkippedCount: Integer)
    begin
        TempRecipientBuffer.Reset();

        if not TempRecipientBuffer.FindSet() then
            exit;

        repeat
            if ShouldSkipRecipient(
                TempRecipientBuffer,
                RecipientGroup,
                SeenRecipients)
            then
                SkippedCount += 1
            else begin
                if CreateNotification(
                    BusinessEventEntry,
                    BusinessEventDefinition,
                    RecipientGroup,
                    Payload,
                    TempRecipientBuffer)
                then begin
                    SeenRecipients.Add(
                        TempRecipientBuffer."Security ID",
                        true);

                    NotificationCount += 1;
                end else
                    SkippedCount += 1;
            end;
        until TempRecipientBuffer.Next() = 0;
    end;

    local procedure ShouldSkipRecipient(
        TempRecipientBuffer: Record "SI Notif. Recipient Buffer" temporary;
        RecipientGroup: Record "SI Recipient Group";
        SeenRecipients: Dictionary of [Guid, Boolean]): Boolean
    begin
        if IsNullGuid(
            TempRecipientBuffer."Security ID")
        then
            exit(true);

        if
            (not TempRecipientBuffer.Active) and
            (not RecipientGroup."Include Inactive Users")
        then
            exit(true);

        if
            RecipientGroup."Remove Duplicates" and
            SeenRecipients.ContainsKey(
                TempRecipientBuffer."Security ID")
        then
            exit(true);

        exit(false);
    end;

    local procedure CreateNotification(
        BusinessEventEntry: Record "SI Business Event Entry";
        BusinessEventDefinition: Record "SI Business Event Definition";
        RecipientGroup: Record "SI Recipient Group";
        Payload: JsonObject;
        TempRecipientBuffer: Record "SI Notif. Recipient Buffer" temporary): Boolean
    var
        NotificationEntry: Record "SI Notification Entry";
        FingerprintMgt: Codeunit "SI Notif. Fingerprint Mgt.";
        PayloadRenderer: Codeunit "SI Payload Renderer";
        RenderedTitle: Text;
        RenderedMessage: Text;
        Fingerprint: Text[250];
    begin
        RenderedTitle :=
            PayloadRenderer.Render(
                BusinessEventDefinition."Title Template",
                Payload);

        RenderedMessage :=
            PayloadRenderer.Render(
                BusinessEventDefinition."Message Template",
                Payload);

        RenderedActionCaption :=
            PayloadRenderer.Render(
                BusinessEventDefinition."Action Caption Template",
                Payload);

        Fingerprint :=
            FingerprintMgt.BuildFingerprint(
                BusinessEventEntry,
                RecipientGroup.Code,
                TempRecipientBuffer."Security ID",
                RenderedTitle,
                RenderedMessage);

        if FingerprintMgt.IsThrottled(
            Fingerprint,
            BusinessEventDefinition."Throttle Minutes",
            BusinessEventDefinition."Allow Duplicate")
        then
            exit(false);

        NotificationEntry.Init();

        NotificationEntry."Event Entry No." :=
            BusinessEventEntry."Entry No.";

        NotificationEntry."Event Code" :=
            BusinessEventEntry."Event Code";

        NotificationEntry."Recipient Security ID" :=
            TempRecipientBuffer."Security ID";

        NotificationEntry."Recipient User Name" :=
            TempRecipientBuffer."User Name";

        NotificationEntry."Recipient Group Code" :=
            RecipientGroup.Code;

        NotificationEntry.Title :=
            CopyStr(
                RenderedTitle,
                1,
                MaxStrLen(NotificationEntry.Title));

        NotificationEntry.Message :=
            CopyStr(
                RenderedMessage,
                1,
                MaxStrLen(NotificationEntry.Message));

        NotificationEntry.Severity :=
            BusinessEventDefinition.Severity;

        NotificationEntry.Status :=
            NotificationEntry.Status::Unread;

        CopySourceData(
            BusinessEventEntry,
            NotificationEntry);

        NotificationEntry.Fingerprint :=
            Fingerprint;

        NotificationEntry."Resolver Trace" :=
            TempRecipientBuffer."Resolution Trace";

        NotificationEntry."Target Page ID" :=
            BusinessEventDefinition."Target Page ID";

        NotificationEntry."Action Caption" :=
            CopyStr(
                RenderedActionCaption,
                1,
                MaxStrLen(NotificationEntry."Action Caption"));

        NotificationEntry.Insert(true);

        exit(true);
    end;

    local procedure CopySourceData(
        BusinessEventEntry: Record "SI Business Event Entry";
        var NotificationEntry: Record "SI Notification Entry")
    begin
        NotificationEntry."Source Table ID" :=
            BusinessEventEntry."Source Table ID";

        NotificationEntry."Source Record ID" :=
            BusinessEventEntry."Source Record ID";

        NotificationEntry."Source System ID" :=
            BusinessEventEntry."Source System ID";

        NotificationEntry."Source Record Caption" :=
            BusinessEventEntry."Source Record Caption";
    end;

    local procedure MarkProcessing(
        var BusinessEventEntry: Record "SI Business Event Entry")
    begin
        BusinessEventEntry.Status :=
            BusinessEventEntry.Status::Processing;

        BusinessEventEntry."Processing Started At" :=
            CurrentDateTime();

        BusinessEventEntry."Error Message" := '';

        BusinessEventEntry.Modify(true);
    end;

    local procedure MarkSkipped(
        var BusinessEventEntry: Record "SI Business Event Entry";
        Reason: Text)
    begin
        BusinessEventEntry.Status :=
            BusinessEventEntry.Status::Skipped;

        BusinessEventEntry."Completed At" :=
            CurrentDateTime();

        BusinessEventEntry."Error Message" :=
            CopyStr(
                Reason,
                1,
                MaxStrLen(BusinessEventEntry."Error Message"));

        BusinessEventEntry.Modify(true);
    end;

    local procedure FinalizeEvent(
        var BusinessEventEntry: Record "SI Business Event Entry";
        NotificationCount: Integer;
        SkippedCount: Integer)
    begin
        BusinessEventEntry."Notification Count" :=
            NotificationCount;

        BusinessEventEntry."Skipped Count" :=
            SkippedCount;

        BusinessEventEntry."Completed At" :=
            CurrentDateTime();

        if NotificationCount = 0 then
            BusinessEventEntry.Status :=
                BusinessEventEntry.Status::Skipped
        else
            if SkippedCount > 0 then
                BusinessEventEntry.Status :=
                    BusinessEventEntry.Status::PartiallyCompleted
            else
                BusinessEventEntry.Status :=
                    BusinessEventEntry.Status::Completed;

        BusinessEventEntry.Modify(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnResolveRecipients(
        BusinessEventEntry: Record "SI Business Event Entry";
        RecipientGroup: Record "SI Recipient Group";
        var TempRecipientBuffer: Record "SI Notif. Recipient Buffer" temporary;
        var IsHandled: Boolean)
    begin
    end;

    var
        NoRecipientResolverErr:
            Label 'Для групи отримувачів не знайдено провайдера визначення адресатів.';

        InvalidPayloadErr:
            Label 'Не вдалося прочитати Payload бізнес-події %1 з кодом %2. JSON має некоректний формат.';

        RenderedActionCaption: Text;
}