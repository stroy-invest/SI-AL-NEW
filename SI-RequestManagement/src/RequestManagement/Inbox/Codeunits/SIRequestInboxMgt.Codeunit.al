codeunit 52054 "SI Request Inbox Mgt."
{
    procedure LoadApproverInbox(
        var TempInbox: Record "SI Request Inbox Buffer" temporary)
    var
        NotificationEntry: Record "SI Notification Entry";
    begin
        TempInbox.Reset();
        TempInbox.DeleteAll();

        NotificationEntry.Reset();

        NotificationEntry.SetRange(
            "Recipient Security ID",
            UserSecurityId());

        NotificationEntry.SetRange(
            "Source Table ID",
            Database::"SI Request Header");

        NotificationEntry.SetFilter(
            "Event Code",
            '%1|%2',
            RequestSubmittedEventCodeLbl,
            RequestApprovalRequiredEventCodeLbl);

        NotificationEntry.SetCurrentKey(
            "Recipient Security ID",
            "Created At");

        NotificationEntry.Ascending(false);

        if NotificationEntry.FindSet() then
            repeat
                AddNotificationToInbox(
                    NotificationEntry,
                    TempInbox);
            until NotificationEntry.Next() = 0;
    end;

    procedure LoadRequesterInbox(
        var TempInbox: Record "SI Request Inbox Buffer" temporary)
    var
        RequestHeader: Record "SI Request Header";
    begin
        TempInbox.Reset();
        TempInbox.DeleteAll();

        RequestHeader.Reset();
        RequestHeader.SetRange(
            "Requester User ID",
            UserId());

        if RequestHeader.FindSet() then
            repeat
                AddRequestToRequesterInbox(
                    RequestHeader,
                    TempInbox);
            until RequestHeader.Next() = 0;
    end;

    procedure LoadRequesterNotificationInbox(
        var TempInbox: Record "SI Request Inbox Buffer" temporary)
    var
        NotificationEntry: Record "SI Notification Entry";
    begin
        TempInbox.Reset();
        TempInbox.DeleteAll();

        NotificationEntry.Reset();

        NotificationEntry.SetRange(
            "Recipient Security ID",
            UserSecurityId());

        NotificationEntry.SetRange(
            "Source Table ID",
            Database::"SI Request Header");

        NotificationEntry.SetFilter(
            "Event Code",
            '%1|%2|%3',
            RequestApprovedEventCodeLbl,
            RequestReturnedEventCodeLbl,
            RequestRejectedEventCodeLbl);

        NotificationEntry.SetCurrentKey(
            "Recipient Security ID",
            "Created At");

        NotificationEntry.Ascending(false);

        if NotificationEntry.FindSet() then
            repeat
                AddRequesterNotificationToInbox(
                    NotificationEntry,
                    TempInbox);
            until NotificationEntry.Next() = 0;
    end;

    local procedure AddRequesterNotificationToInbox(
        NotificationEntry: Record "SI Notification Entry";
        var TempInbox: Record "SI Request Inbox Buffer" temporary)
    var
        RequestHeader: Record "SI Request Header";
    begin
        TempInbox.Init();

        TempInbox."Notification Entry No." :=
            NotificationEntry."Entry No.";

        TempInbox."Event Code" :=
            NotificationEntry."Event Code";

        TempInbox.Message :=
            NotificationEntry.Title;

        TempInbox."Received At" :=
            NotificationEntry."Created At";

        TempInbox."Is Read" :=
            NotificationEntry."Read At" <> 0DT;

        TempInbox."Is Hidden" :=
            NotificationEntry."Dismissed At" <> 0DT;

        TempInbox."Source Table ID" :=
            NotificationEntry."Source Table ID";

        TempInbox."Source Record ID" :=
            NotificationEntry."Source Record ID";

        TempInbox."Target Page ID" :=
            NotificationEntry."Target Page ID";

        if GetRequestHeader(
            NotificationEntry,
            RequestHeader)
        then begin
            TempInbox."Request No." :=
                RequestHeader."No.";

            TempInbox."Request Status" :=
                RequestHeader.Status;

            TempInbox."Execution Date" :=
                RequestHeader."Execution Date";

            TempInbox."Requester Name" :=
                RequestHeader."Requester Employee Name";

            FillRequesterNotificationEventInfo(
                NotificationEntry,
                RequestHeader,
                TempInbox);
        end;

        TempInbox.Insert();
    end;

    local procedure FillRequesterNotificationEventInfo(
        NotificationEntry: Record "SI Notification Entry";
        RequestHeader: Record "SI Request Header";
        var TempInbox: Record "SI Request Inbox Buffer" temporary)
    begin
        Clear(TempInbox."Current Approver Name");
        Clear(TempInbox."Final Approver Name");

        case NotificationEntry."Event Code" of
            RequestApprovedEventCodeLbl:
                begin
                    TempInbox."Request Status" :=
                        TempInbox."Request Status"::Approved;

                    TempInbox."Final Approver Name" :=
                        GetEventDecisionApproverName(
                            RequestHeader,
                            TempInbox."Request Status",
                            NotificationEntry."Created At");
                end;

            RequestReturnedEventCodeLbl:
                begin
                    TempInbox."Request Status" :=
                        TempInbox."Request Status"::Returned;

                    TempInbox."Final Approver Name" :=
                        GetEventDecisionApproverName(
                            RequestHeader,
                            TempInbox."Request Status",
                            NotificationEntry."Created At");
                end;

            RequestRejectedEventCodeLbl:
                begin
                    TempInbox."Request Status" :=
                        TempInbox."Request Status"::Rejected;

                    TempInbox."Final Approver Name" :=
                        GetEventDecisionApproverName(
                            RequestHeader,
                            TempInbox."Request Status",
                            NotificationEntry."Created At");
                end;
        end;
    end;

    local procedure GetEventDecisionApproverName(
        RequestHeader: Record "SI Request Header";
        EventStatus: Enum "SI Request Status";
        EventDateTime: DateTime): Text[100]
    var
        StatusLog: Record "SI Req. Status Log";
    begin
        StatusLog.Reset();

        StatusLog.SetCurrentKey(
            "Request No.",
            "Date Time");

        StatusLog.SetRange(
            "Request No.",
            RequestHeader."No.");

        StatusLog.SetRange(
            "New Status",
            EventStatus);

        StatusLog.SetFilter(
            "Date Time",
            '..%1',
            EventDateTime);

        StatusLog.Ascending(false);

        if not StatusLog.FindFirst() then
            exit('');

        exit(
            GetEmployeeNameByUserId(
                StatusLog."User ID"));
    end;

    local procedure AddRequestToRequesterInbox(
        RequestHeader: Record "SI Request Header";
        var TempInbox: Record "SI Request Inbox Buffer" temporary)
    var
        BufferEntryNo: BigInteger;
    begin
        BufferEntryNo :=
            TempInbox.Count() + 1;

        TempInbox.Init();

        TempInbox."Notification Entry No." :=
            BufferEntryNo;

        TempInbox."Request No." :=
            RequestHeader."No.";

        TempInbox.Message :=
            StrSubstNo(
                RequestMessageLbl,
                RequestHeader."No.");

        TempInbox."Request Status" :=
            RequestHeader.Status;

        TempInbox."Execution Date" :=
            RequestHeader."Execution Date";

        TempInbox."Requester Name" :=
            RequestHeader."Requester Employee Name";

        FillRequesterApprovalInfo(
            RequestHeader,
            TempInbox);

        TempInbox."Source Table ID" :=
            Database::"SI Request Header";

        TempInbox."Source Record ID" :=
            RequestHeader.RecordId();

        TempInbox."Target Page ID" :=
            Page::"SI Request Card";

        TempInbox.Insert();
    end;

    local procedure FillRequesterApprovalInfo(
        RequestHeader: Record "SI Request Header";
        var TempInbox: Record "SI Request Inbox Buffer" temporary)
    begin
        Clear(TempInbox."Current Approver Name");
        Clear(TempInbox."Final Approver Name");

        case RequestHeader.Status of
            RequestHeader.Status::"Pending Approval":
                TempInbox."Current Approver Name" :=
                    GetCurrentApproverName(RequestHeader);

            RequestHeader.Status::Approved,
            RequestHeader.Status::Rejected,
            RequestHeader.Status::Returned,
            RequestHeader.Status::Cancelled:
                TempInbox."Final Approver Name" :=
                    GetFinalApproverName(RequestHeader);
        end;
    end;

    local procedure GetCurrentApproverName(
        RequestHeader: Record "SI Request Header"): Text[100]
    var
        CurrentApprovalEntry: Record "Approval Entry";
        RecipientHelper: Codeunit "SI Req. Recipient Helper";
    begin
        if not RecipientHelper.GetCurrentOpenApprovalEntry(
            RequestHeader,
            CurrentApprovalEntry)
        then
            exit('');

        exit(
            GetEmployeeNameByUserId(
                CurrentApprovalEntry."Approver ID"));
    end;

    local procedure GetFinalApproverName(
        RequestHeader: Record "SI Request Header"): Text[100]
    var
        StatusLog: Record "SI Req. Status Log";
    begin
        StatusLog.Reset();

        StatusLog.SetCurrentKey(
            "Request No.",
            "Date Time");

        StatusLog.SetRange(
            "Request No.",
            RequestHeader."No.");

        StatusLog.SetRange(
            "New Status",
            RequestHeader.Status);

        StatusLog.Ascending(false);

        if not StatusLog.FindFirst() then
            exit('');

        exit(
            GetEmployeeNameByUserId(
                StatusLog."User ID"));
    end;

    local procedure AddNotificationToInbox(
        NotificationEntry: Record "SI Notification Entry";
        var TempInbox: Record "SI Request Inbox Buffer" temporary)
    var
        RequestHeader: Record "SI Request Header";
    begin
        TempInbox.Init();

        TempInbox."Notification Entry No." :=
            NotificationEntry."Entry No.";

        TempInbox."Event Code" :=
            NotificationEntry."Event Code";

        TempInbox.Message :=
            NotificationEntry.Title;

        TempInbox."Received At" :=
            NotificationEntry."Created At";

        TempInbox."Is Read" :=
            NotificationEntry."Read At" <> 0DT;

        TempInbox."Is Hidden" :=
            NotificationEntry."Dismissed At" <> 0DT;

        TempInbox."Source Table ID" :=
            NotificationEntry."Source Table ID";

        TempInbox."Source Record ID" :=
            NotificationEntry."Source Record ID";

        TempInbox."Target Page ID" :=
            NotificationEntry."Target Page ID";

        if GetRequestHeader(
            NotificationEntry,
            RequestHeader)
        then begin
            TempInbox."Request No." :=
                RequestHeader."No.";

            TempInbox."Request Status" :=
                RequestHeader.Status;

            TempInbox."Execution Date" :=
                RequestHeader."Execution Date";

            TempInbox."Requester Name" :=
                RequestHeader."Requester Employee Name";
        end;

        TempInbox."Approver Name" :=
            GetEmployeeNameByUserId(
                NotificationEntry."Recipient User Name");

        FillApprovalEntryInfo(
            NotificationEntry,
            TempInbox);

        TempInbox.Insert();
    end;

    local procedure FillApprovalEntryInfo(
        NotificationEntry: Record "SI Notification Entry";
        var TempInbox: Record "SI Request Inbox Buffer" temporary)
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        if not FindApprovalEntryForNotification(
            NotificationEntry,
            ApprovalEntry)
        then
            exit;

        TempInbox."Approval Entry No." :=
            ApprovalEntry."Entry No.";

        TempInbox."Approval Due Date" :=
            ApprovalEntry."Due Date";

        if ApprovalEntry.Status =
        ApprovalEntry.Status::Approved
        then
            TempInbox."Approval Decision At" :=
                ApprovalEntry."Last Date-Time Modified";

        TempInbox."Approval Is Open" :=
            ApprovalEntry.Status =
                ApprovalEntry.Status::Open;
    end;

    local procedure FindApprovalEntryForNotification(
        NotificationEntry: Record "SI Notification Entry";
        var ApprovalEntry: Record "Approval Entry"): Boolean
    var
        RequestHeader: Record "SI Request Header";
    begin
        if not GetRequestHeader(
            NotificationEntry,
            RequestHeader)
        then
            exit(false);

        ApprovalEntry.Reset();

        ApprovalEntry.SetRange(
            "Table ID",
            Database::"SI Request Header");

        ApprovalEntry.SetRange(
            "Approver ID",
            NotificationEntry."Recipient User Name");

        ApprovalEntry.SetRange(
            "Document No.",
            RequestHeader."No.");

        ApprovalEntry.SetCurrentKey(
            "Entry No.");

        ApprovalEntry.Ascending(false);

        exit(ApprovalEntry.FindFirst());
    end;

    local procedure GetRequestHeader(
        NotificationEntry: Record "SI Notification Entry";
        var RequestHeader: Record "SI Request Header"): Boolean
    var
        SourceRecordRef: RecordRef;
    begin
        if NotificationEntry."Source Table ID" <>
           Database::"SI Request Header"
        then
            exit(false);

        if NotificationEntry."Source Record ID".TableNo <>
           Database::"SI Request Header"
        then
            exit(false);

        SourceRecordRef.Get(
            NotificationEntry."Source Record ID");

        SourceRecordRef.SetTable(
            RequestHeader);

        exit(true);
    end;

    local procedure GetEmployeeNameByUserId(
        UserIdValue: Code[50]): Text[100]
    var
        RequesterSetup: Record "SI Requester Setup";
        Employee: Record Employee;
    begin
        if UserIdValue = '' then
            exit('');

        if not RequesterSetup.Get(UserIdValue) then
            exit('');

        if RequesterSetup."Employee No." = '' then
            exit('');

        if not Employee.Get(
            RequesterSetup."Employee No.")
        then
            exit('');

        exit(
            CopyStr(
                Employee.FullName(),
                1,
                100));
    end;

    var
        RequestSubmittedEventCodeLbl:
            Label 'REQUEST_SUBMITTED',
            Locked = true;

        RequestApprovalRequiredEventCodeLbl:
            Label 'REQUEST_APPROVAL_REQUIRED',
            Locked = true;

        RequestMessageLbl:
            Label 'Заявка %1',
            Locked = false;

        RequestApprovedEventCodeLbl:
            Label 'REQUEST_APPROVED',
            Locked = true;

        RequestReturnedEventCodeLbl:
            Label 'REQUEST_RETURNED',
            Locked = true;

        RequestRejectedEventCodeLbl:
            Label 'REQUEST_REJECTED',
            Locked = true;
}