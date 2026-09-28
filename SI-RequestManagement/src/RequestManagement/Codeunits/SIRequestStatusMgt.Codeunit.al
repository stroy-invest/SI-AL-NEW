codeunit 52009 "SI Request Status Mgt."
{
    Permissions =
        tabledata "Approval Entry" = RIMD,
        tabledata "User Setup" = R,
        tabledata "SI Request Header" = RM,
        tabledata "SI Request Line" = R,
        tabledata "SI Req. Status Log" = RI;

    procedure LogCreate(RequestHeader: Record "SI Request Header")
    begin
        WriteStatusLog(
            RequestHeader."No.",
            RequestHeader.Status::Draft,
            RequestHeader.Status::Draft,
            'CREATE',
            '');
    end;

    procedure Submit(var RequestHeader: Record "SI Request Header")
    var
        UserSetup: Record "User Setup";
        RequestNotificationMgt: Codeunit "SI Req. Notification Mgt.";
    begin
        TestCanSubmit(RequestHeader);

        if not UserSetup.Get(UserId()) then
            Error(ApprovalUserSetupMissingErr, UserId());

        UserSetup.TestField("Approver ID");

        CheckNoOpenApprovalEntry(RequestHeader);

        CreateApprovalEntryForApprover(
            RequestHeader,
            UserSetup."Approver ID",
            1);

        RequestHeader."Submitted At" :=
            CurrentDateTime();

        RequestHeader."Submitted By" :=
            CopyStr(
                UserId(),
                1,
                MaxStrLen(RequestHeader."Submitted By"));

        SetStatus(
            RequestHeader,
            RequestHeader.Status::"Pending Approval",
            'SUBMIT',
            '');

        RequestNotificationMgt.PublishSubmitted(
            RequestHeader);
    end;

    procedure ReturnForRevision(
        var RequestHeader: Record "SI Request Header";
        ResolutionReason: Text[250])
    var
        ApprovalEntry: Record "Approval Entry";
        RequestNotificationMgt: Codeunit "SI Req. Notification Mgt.";
    begin
        TestCanReturnForRevision(
            RequestHeader,
            ResolutionReason);

        GetCurrentOpenApprovalEntry(
            RequestHeader,
            ApprovalEntry);

        CancelApprovalEntry(ApprovalEntry);

        SetStatus(
            RequestHeader,
            RequestHeader.Status::Returned,
            'RETURN',
            ResolutionReason);

        RequestNotificationMgt.PublishReturned(
            RequestHeader);
    end;

    local procedure TestCanReturnForRevision(
        RequestHeader: Record "SI Request Header";
        ResolutionReason: Text[250])
    begin
        if RequestHeader.Status <>
           RequestHeader.Status::"Pending Approval"
        then
            Error(
                ReturnNotAllowedErr,
                RequestHeader."No.",
                Format(RequestHeader.Status));

        if DelChr(ResolutionReason, '<>', ' ') = '' then
            Error(ReturnReasonRequiredErr);
    end;

    local procedure GetCurrentOpenApprovalEntry(
        RequestHeader: Record "SI Request Header";
        var ApprovalEntry: Record "Approval Entry")
    begin
        ApprovalEntry.Reset();

        ApprovalEntry.SetRange(
            "Record ID to Approve",
            RequestHeader.RecordId());

        ApprovalEntry.SetRange(
            Status,
            ApprovalEntry.Status::Open);

        ApprovalEntry.SetRange(
            "Approver ID",
            UserId());

        if not ApprovalEntry.FindFirst() then
            Error(
                OpenApprovalEntryNotFoundErr,
                RequestHeader."No.",
                UserId());
    end;

    local procedure CancelApprovalEntry(
        var ApprovalEntry: Record "Approval Entry")
    begin
        ApprovalEntry.Validate(
            Status,
            ApprovalEntry.Status::Canceled);

        ApprovalEntry."Last Date-Time Modified" :=
            CurrentDateTime();

        ApprovalEntry."Last Modified By User ID" :=
            CopyStr(
                UserId(),
                1,
                MaxStrLen(
                    ApprovalEntry."Last Modified By User ID"));

        ApprovalEntry.Modify(true);
    end;

    local procedure CheckNoOpenApprovalEntry(
        RequestHeader: Record "SI Request Header")
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        ApprovalEntry.SetRange(
            "Record ID to Approve",
            RequestHeader.RecordId());

        ApprovalEntry.SetRange(
            Status,
            ApprovalEntry.Status::Open);

        if not ApprovalEntry.IsEmpty() then
            Error(
                OpenApprovalEntryAlreadyExistsErr,
                RequestHeader."No.");
    end;

    local procedure CreateApprovalEntryForApprover(
        RequestHeader: Record "SI Request Header";
        ApproverId: Code[50];
        SequenceNo: Integer)
    var
        ApprovalEntry: Record "Approval Entry";
        LastApprovalEntry: Record "Approval Entry";
        EntryNo: Integer;
    begin
        LastApprovalEntry.LockTable();

        if LastApprovalEntry.FindLast() then
            EntryNo :=
                LastApprovalEntry."Entry No." + 1
        else
            EntryNo := 1;

        ApprovalEntry.Init();

        ApprovalEntry."Entry No." :=
            EntryNo;

        ApprovalEntry."Table ID" :=
            Database::"SI Request Header";

        ApprovalEntry."Document No." :=
            RequestHeader."No.";

        ApprovalEntry."Record ID to Approve" :=
            RequestHeader.RecordId();

        ApprovalEntry."Sender ID" :=
            CopyStr(
                UserId(),
                1,
                MaxStrLen(ApprovalEntry."Sender ID"));

        ApprovalEntry."Approver ID" :=
            ApproverId;

        ApprovalEntry.Status :=
            ApprovalEntry.Status::Open;

        ApprovalEntry."Sequence No." :=
            SequenceNo;

        ApprovalEntry."Due Date" :=
            RequestHeader."Execution Date";

        ApprovalEntry."Date-Time Sent for Approval" :=
            CurrentDateTime();

        ApprovalEntry."Last Date-Time Modified" :=
            CurrentDateTime();

        ApprovalEntry."Last Modified By User ID" :=
            CopyStr(
                UserId(),
                1,
                MaxStrLen(
                    ApprovalEntry."Last Modified By User ID"));

        ApprovalEntry.Insert(true);
    end;

    local procedure TestCanSubmit(
        RequestHeader: Record "SI Request Header")
    begin
        if not (
            RequestHeader.Status in
            [
                RequestHeader.Status::Draft,
                RequestHeader.Status::Returned
            ])
        then
            Error(
                SubmitNotAllowedErr,
                RequestHeader."No.",
                Format(RequestHeader.Status));

        RequestHeader.TestField("Execution Date");
        RequestHeader.TestField("Construction Object No.");

        TestRequestLines(RequestHeader);
    end;

    local procedure TestRequestLines(
        RequestHeader: Record "SI Request Header")
    var
        RequestLine: Record "SI Request Line";
    begin
        RequestLine.SetRange(
            "Request No.",
            RequestHeader."No.");

        if RequestLine.IsEmpty() then
            Error(
                RequestLinesRequiredErr,
                RequestHeader."No.");

        if RequestLine.FindSet() then
            repeat
                RequestLine.TestField("Item No.");

                if RequestLine.Quantity <= 0 then
                    Error(
                        QuantityMustBePositiveErr,
                        RequestLine."Request No.",
                        RequestLine."Line No.");

                RequestLine.TestField(
                    "Unit of Measure Code");
            until RequestLine.Next() = 0;
    end;

    local procedure SetStatus(
        var RequestHeader: Record "SI Request Header";
        NewStatus: Enum "SI Request Status";
        ActionCode: Code[30];
        Comment: Text[250])
    var
        OldStatus: Enum "SI Request Status";
    begin
        OldStatus := RequestHeader.Status;

        if OldStatus = NewStatus then
            exit;

        RequestHeader.Status :=
            NewStatus;

        if NewStatus =
           RequestHeader.Status::Approved
        then begin
            RequestHeader."Approved At" :=
                CurrentDateTime();

            RequestHeader."Approved By" :=
                CopyStr(
                    UserId(),
                    1,
                    MaxStrLen(RequestHeader."Approved By"));
        end;

        RequestHeader.Modify(true);

        WriteStatusLog(
            RequestHeader."No.",
            OldStatus,
            NewStatus,
            ActionCode,
            Comment);
    end;

    local procedure WriteStatusLog(
        RequestNo: Code[20];
        OldStatus: Enum "SI Request Status";
        NewStatus: Enum "SI Request Status";
        ActionCode: Code[30];
        Comment: Text[250])
    var
        StatusLog: Record "SI Req. Status Log";
    begin
        StatusLog.Init();

        StatusLog."Request No." :=
            RequestNo;

        StatusLog."Old Status" :=
            OldStatus;

        StatusLog."New Status" :=
            NewStatus;

        StatusLog."Action Code" :=
            ActionCode;

        StatusLog."User ID" :=
            CopyStr(
                UserId(),
                1,
                MaxStrLen(StatusLog."User ID"));

        StatusLog."Date Time" :=
            CurrentDateTime();

        StatusLog.Comment :=
            Comment;

        StatusLog.Insert(true);
    end;

    [EventSubscriber(
        ObjectType::Table,
        Database::"Approval Entry",
        'OnAfterValidateEvent',
        'Status',
        false,
        false)]
    local procedure OnAfterValidateApprovalEntryStatus(
        var Rec: Record "Approval Entry";
        var xRec: Record "Approval Entry";
        CurrFieldNo: Integer)
    var
        RequestHeader: Record "SI Request Header";
        RequestNotificationMgt: Codeunit "SI Req. Notification Mgt.";
    begin
        if Rec."Table ID" <>
           Database::"SI Request Header"
        then
            exit;

        if Rec.Status = xRec.Status then
            exit;

        if not RequestHeader.Get(
            Rec."Document No.")
        then
            exit;

        case Rec.Status of
            Rec.Status::Approved:
                HandleApprovedApprovalEntry(
                    Rec,
                    RequestHeader);

            Rec.Status::Rejected:
                begin
                    SetStatus(
                        RequestHeader,
                        RequestHeader.Status::Rejected,
                        'REJECT',
                        '');

                    RequestNotificationMgt.PublishRejected(
                        RequestHeader);
                end;
        end;
    end;

    local procedure HandleApprovedApprovalEntry(
        ApprovalEntry: Record "Approval Entry";
        var RequestHeader: Record "SI Request Header")
    var
        UserSetup: Record "User Setup";
        RequestNotificationMgt: Codeunit "SI Req. Notification Mgt.";
        NextSequenceNo: Integer;
    begin
        if UserSetup.Get(
            ApprovalEntry."Approver ID")
        then
            if UserSetup."Approver ID" <> '' then begin
                NextSequenceNo :=
                    ApprovalEntry."Sequence No." + 1;

                CreateApprovalEntryForApprover(
                    RequestHeader,
                    UserSetup."Approver ID",
                    NextSequenceNo);

                WriteStatusLog(
                    RequestHeader."No.",
                    RequestHeader.Status,
                    RequestHeader.Status,
                    'NEXT_APPROVER',
                    StrSubstNo(
                        NextApproverMsg,
                        UserSetup."Approver ID"));

                RequestNotificationMgt.PublishApprovalRequired(
                    RequestHeader,
                    UserSetup."Approver ID");

                exit;
            end;

        SetStatus(
            RequestHeader,
            RequestHeader.Status::Approved,
            'APPROVE',
            '');

        RequestNotificationMgt.PublishApproved(
            RequestHeader);
    end;

    var
        ApprovalUserSetupMissingErr:
            Label 'Для користувача %1 не налаштовано Approval User Setup.';

        OpenApprovalEntryAlreadyExistsErr:
            Label 'Для заявки %1 вже існує відкритий запит на погодження.';

        SubmitNotAllowedErr:
            Label 'Заявку %1 не можна подати на погодження зі статусу %2.';

        RequestLinesRequiredErr:
            Label 'Заявка %1 повинна містити хоча б один рядок.';

        QuantityMustBePositiveErr:
            Label 'Кількість повинна бути більшою за нуль у заявці %1, рядок %2.';

        ReturnNotAllowedErr:
            Label 'Заявку %1 не можна повернути на доопрацювання зі статусу %2.';

        ReturnReasonRequiredErr:
            Label 'Необхідно вказати причину повернення заявки на доопрацювання.';

        OpenApprovalEntryNotFoundErr:
            Label 'Для заявки %1 не знайдено відкритого погодження користувача %2.';

        NextApproverMsg:
            Label 'Наступний погоджувач: %1';
}