codeunit 50233 "SI Notif. Fingerprint Mgt."
{
    Permissions =
        tabledata "SI Notification Entry" = R;

    procedure BuildFingerprint(
        BusinessEventEntry: Record "SI Business Event Entry";
        RecipientGroupCode: Code[50];
        RecipientSecurityId: Guid;
        NotificationTitle: Text;
        NotificationMessage: Text): Text[250]
    var
        CryptographyManagement: Codeunit "Cryptography Management";
        HashAlgorithmType: Option MD5,SHA1,SHA256,SHA384,SHA512;
        FingerprintSource: Text;
        HashValue: Text;
    begin
        FingerprintSource :=
            BuildFingerprintSource(
                BusinessEventEntry,
                RecipientGroupCode,
                RecipientSecurityId,
                NotificationTitle,
                NotificationMessage);

        HashValue :=
            CryptographyManagement.GenerateHashAsBase64String(
                FingerprintSource,
                HashAlgorithmType::SHA256);

        exit(CopyStr(HashValue, 1, 250));
    end;

    procedure IsThrottled(
        Fingerprint: Text[250];
        ThrottleMinutes: Integer;
        AllowDuplicate: Boolean): Boolean
    var
        NotificationEntry: Record "SI Notification Entry";
        ThrottleFromDateTime: DateTime;
    begin
        if AllowDuplicate then
            exit(false);

        if ThrottleMinutes <= 0 then
            exit(false);

        if Fingerprint = '' then
            exit(false);

        ThrottleFromDateTime :=
            CurrentDateTime() -
            (ThrottleMinutes * 60 * 1000);

        NotificationEntry.SetCurrentKey(
            Fingerprint,
            "Created At");

        NotificationEntry.SetRange(
            Fingerprint,
            Fingerprint);

        NotificationEntry.SetFilter(
            "Created At",
            '>=%1',
            ThrottleFromDateTime);

        exit(not NotificationEntry.IsEmpty());
    end;

    local procedure BuildFingerprintSource(
        BusinessEventEntry: Record "SI Business Event Entry";
        RecipientGroupCode: Code[50];
        RecipientSecurityId: Guid;
        NotificationTitle: Text;
        NotificationMessage: Text): Text
    begin
        exit(
            StrSubstNo(
                '%1|%2|%3|%4|%5|%6|%7',
                BusinessEventEntry."Event Code",
                Format(BusinessEventEntry."Source Record ID"),
                Format(BusinessEventEntry."Source System ID"),
                RecipientGroupCode,
                Format(RecipientSecurityId),
                NotificationTitle,
                NotificationMessage));
    end;
}
/*
    Тут використовуємо стандартний Cryptography Management.GenerateHashAsBase64String() із SHA256, 
    що підтримується системним application codeunit

    Fingerprint складається з таких частин:
        Event Code
        + Source Record ID
        + Source System ID
        + Recipient Group
        + Recipient Security ID
        + Title
        + Message

    Таким чином, однакова подія для різних отримувачів матиме різний fingerprint, 
    а повторне однакове повідомлення тому самому користувачеві може бути приглушене в межах Throttle Minutes.

    Важлива поведінка
    if AllowDuplicate then
        exit(false);

    Тобто:
    Allow Duplicate = true — throttling повністю вимкнений
    Throttle Minutes = 0 — throttling також вимкнений
    - інакше шукаємо вже створене повідомлення з таким fingerprint у заданому часовому вікні  
*/
