codeunit 52040 "SI Req. Notification Mgt."
{
    Permissions =
        tabledata "SI Req. Status Log" = I;

    procedure PublishSubmitted(
        RequestHeader: Record "SI Request Header")
    begin
        PublishRequestEvent(
            RequestSubmittedEventCodeLbl,
            RequestHeader,
            '');
    end;

    procedure PublishApprovalRequired(
        RequestHeader: Record "SI Request Header";
        ApproverId: Code[50])
    begin
        PublishRequestEvent(
            RequestApprovalRequiredCodeLbl,
            RequestHeader,
            ApproverId);
    end;

    procedure PublishReturned(
        RequestHeader: Record "SI Request Header")
    begin
        PublishRequestEvent(
            RequestReturnedEventCodeLbl,
            RequestHeader,
            '');
    end;

    procedure PublishRejected(
        RequestHeader: Record "SI Request Header")
    begin
        PublishRequestEvent(
            RequestRejectedEventCodeLbl,
            RequestHeader,
            '');
    end;

    procedure PublishApproved(
        RequestHeader: Record "SI Request Header")
    begin
        PublishRequestEvent(
            RequestApprovedEventCodeLbl,
            RequestHeader,
            '');
    end;

    local procedure PublishRequestEvent(
        EventCode: Code[50];
        RequestHeader: Record "SI Request Header";
        ApproverId: Code[50])
    var
        Payload: JsonObject;
        PublishErrorText: Text;
    begin
        BuildPayload(
            RequestHeader,
            ApproverId,
            Payload);

        if TryPublish(
            EventCode,
            RequestHeader.RecordId(),
            Payload)
        then
            exit;

        PublishErrorText := GetLastErrorText();
        ClearLastError();

        LogPublishFailure(
            EventCode,
            RequestHeader,
            PublishErrorText);
    end;

    local procedure BuildPayload(
        RequestHeader: Record "SI Request Header";
        ApproverId: Code[50];
        var Payload: JsonObject)
    begin
        Clear(Payload);

        Payload.Add(
            'requestNo',
            RequestHeader."No.");

        Payload.Add(
            'status',
            Format(RequestHeader.Status));

        Payload.Add(
            'requesterUserId',
            RequestHeader."Requester User ID");

        Payload.Add(
            'executionDate',
            Format(RequestHeader."Execution Date", 0, 9));

        Payload.Add(
            'constructionObjectNo',
            RequestHeader."Construction Object No.");

        Payload.Add(
            'publishedBy',
            UserId());

        Payload.Add(
            'publishedAt',
            Format(CurrentDateTime(), 0, 9));

        if ApproverId <> '' then
            Payload.Add(
                'approverId',
                ApproverId);
    end;

    local procedure LogPublishFailure(
        EventCode: Code[50];
        RequestHeader: Record "SI Request Header";
        PublishErrorText: Text)
    var
        StatusLog: Record "SI Req. Status Log";
    begin
        StatusLog.Init();
        StatusLog."Request No." := RequestHeader."No.";
        StatusLog."Old Status" := RequestHeader.Status;
        StatusLog."New Status" := RequestHeader.Status;
        StatusLog."Action Code" := 'NOTIF_ERROR';
        StatusLog."User ID" :=
            CopyStr(
                UserId(),
                1,
                MaxStrLen(StatusLog."User ID"));
        StatusLog."Date Time" := CurrentDateTime();
        StatusLog.Comment :=
            CopyStr(
                StrSubstNo(
                    NotificationPublishFailedTxt,
                    EventCode,
                    PublishErrorText),
                1,
                MaxStrLen(StatusLog.Comment));
        StatusLog.Insert(true);
    end;

    [TryFunction]
    local procedure TryPublish(
        EventCode: Code[50];
        SourceRecordId: RecordId;
        Payload: JsonObject)
    var
        BusinessEventService: Codeunit "SI Business Event Service";
    begin
        BusinessEventService.Publish(
            EventCode,
            SourceRecordId,
            Payload);
    end;

    var
        RequestSubmittedEventCodeLbl:
            Label 'REQUEST_SUBMITTED',
            Locked = true;

        RequestApprovalRequiredCodeLbl:
            Label 'REQUEST_APPROVAL_REQUIRED',
            Locked = true;

        RequestReturnedEventCodeLbl:
            Label 'REQUEST_RETURNED',
            Locked = true;

        RequestRejectedEventCodeLbl:
            Label 'REQUEST_REJECTED',
            Locked = true;

        RequestApprovedEventCodeLbl:
            Label 'REQUEST_APPROVED',
            Locked = true;

        NotificationPublishFailedTxt:
            Label 'Не вдалося опублікувати подію %1. %2';
}