codeunit 52036 "SI Req. Recipient Helper"
{
    Permissions =
        tabledata "SI Request Header" = R,
        tabledata "Approval Entry" = R,
        tabledata "User Setup" = R,
        tabledata User = R;

    procedure GetRequestHeader(
        BusinessEventEntry: Record "SI Business Event Entry";
        var RequestHeader: Record "SI Request Header")
    var
        SourceRecordRef: RecordRef;
    begin
        if BusinessEventEntry."Source Table ID" <>
           Database::"SI Request Header"
        then
            Error(
                InvalidSourceTableErr,
                BusinessEventEntry."Event Code",
                BusinessEventEntry."Source Table ID",
                Database::"SI Request Header");

        if BusinessEventEntry."Source Record ID".TableNo() <>
           Database::"SI Request Header"
        then
            Error(
                InvalidSourceRecordErr,
                BusinessEventEntry."Event Code");

        SourceRecordRef.Get(
            BusinessEventEntry."Source Record ID");

        SourceRecordRef.SetTable(RequestHeader);
    end;

    procedure GetCurrentOpenApprovalEntry(
        RequestHeader: Record "SI Request Header";
        var CurrentApprovalEntry: Record "Approval Entry"): Boolean
    var
        ApprovalEntry: Record "Approval Entry";
        EntryFound: Boolean;
    begin
        ApprovalEntry.SetRange(
            "Record ID to Approve",
            RequestHeader.RecordId());

        ApprovalEntry.SetRange(
            Status,
            ApprovalEntry.Status::Open);

        if not ApprovalEntry.FindSet() then
            exit(false);

        repeat
            if
                (not EntryFound) or
                (ApprovalEntry."Sequence No." <
                 CurrentApprovalEntry."Sequence No.")
            then begin
                CurrentApprovalEntry := ApprovalEntry;
                EntryFound := true;
            end;
        until ApprovalEntry.Next() = 0;

        exit(EntryFound);
    end;

    procedure GetNextApproverId(
        RequestHeader: Record "SI Request Header";
        var NextApproverId: Code[50]): Boolean
    var
        CurrentApprovalEntry: Record "Approval Entry";
        ApproverUserSetup: Record "User Setup";
    begin
        Clear(NextApproverId);

        if not GetCurrentOpenApprovalEntry(
            RequestHeader,
            CurrentApprovalEntry)
        then
            exit(false);

        if not ApproverUserSetup.Get(
            CurrentApprovalEntry."Approver ID")
        then
            exit(false);

        if ApproverUserSetup."Approver ID" = '' then
            exit(false);

        NextApproverId :=
            ApproverUserSetup."Approver ID";

        exit(true);
    end;

    procedure AddUserRecipient(
        BusinessEventEntry: Record "SI Business Event Entry";
        RecipientGroup: Record "SI Recipient Group";
        UserName: Code[50];
        ResolutionDescription: Text;
        var TempRecipientBuffer: Record "SI Notif. Recipient Buffer" temporary)
    var
        UserRecord: Record User;
    begin
        if UserName = '' then
            Error(
                RecipientUserEmptyErr,
                RecipientGroup.Code);

        UserRecord.SetRange(
            "User Name",
            UserName);

        if not UserRecord.FindFirst() then
            Error(
                RecipientUserNotFoundErr,
                UserName,
                RecipientGroup.Code);

        TempRecipientBuffer.Init();

        TempRecipientBuffer."Entry No." :=
            GetNextEntryNo(TempRecipientBuffer);

        TempRecipientBuffer."Security ID" :=
            UserRecord."User Security ID";

        TempRecipientBuffer."User Name" :=
            CopyStr(
                UserRecord."User Name",
                1,
                MaxStrLen(
                    TempRecipientBuffer."User Name"));

        TempRecipientBuffer."Display Name" :=
            CopyStr(
                UserRecord."Full Name",
                1,
                MaxStrLen(
                    TempRecipientBuffer."Display Name"));

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
                    Format(RecipientGroup."Resolver Type"),
                    UserRecord."User Name",
                    UserRecord."User Security ID",
                    BusinessEventEntry."Entry No.",
                    ResolutionDescription),
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
        InvalidSourceTableErr:
            Label 'Бізнес-подія %1 має таблицю-джерело %2. Очікувалася таблиця %3 «Заявка на постачання».';

        InvalidSourceRecordErr:
            Label 'Запис-джерело бізнес-події %1 не є заявкою на постачання.';

        RecipientUserEmptyErr:
            Label 'Для групи отримувачів %1 не визначено користувача.';

        RecipientUserNotFoundErr:
            Label 'Користувача %1, визначеного для групи отримувачів %2, не знайдено.';

        ResolutionTraceTxt:
            Label 'Група: %1; тип: %2; користувач: %3; Security ID: %4; бізнес-подія: %5; джерело визначення: %6.';
}