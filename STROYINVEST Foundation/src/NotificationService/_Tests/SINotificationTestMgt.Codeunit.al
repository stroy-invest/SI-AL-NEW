codeunit 50235 "SI Notification Test Mgt."
{
    procedure PublishTestEvent(
        BusinessEventDefinition: Record "SI Business Event Definition")
    var
        UserRecord: Record User;
        BusinessEventService: Codeunit "SI Business Event Service";
        Payload: JsonObject;
        EventEntryNo: BigInteger;
    begin
        BusinessEventDefinition.TestField(Code);
        BusinessEventDefinition.TestField(Active, true);
        BusinessEventDefinition.TestField("Recipient Group Code");

        GetCurrentUser(UserRecord);

        Payload.Add('test', true);
        Payload.Add('publishedBy', UserId());
        Payload.Add(
            'publishedAt',
            Format(CurrentDateTime(), 0, 9));
        Payload.Add(
            'eventCode',
            BusinessEventDefinition.Code);

        EventEntryNo :=
            BusinessEventService.Publish(
                BusinessEventDefinition.Code,
                UserRecord.RecordId(),
                Payload);

        Message(
            TestPublishedMsg,
            EventEntryNo);
    end;

    local procedure GetCurrentUser(
        var UserRecord: Record User)
    begin
        UserRecord.SetRange(
            "User Security ID",
            UserSecurityId());

        if not UserRecord.FindFirst() then
            Error(CurrentUserNotFoundErr);
    end;

    var
        TestPublishedMsg:
            Label 'Тестову бізнес-подію опубліковано. Номер запису: %1.';

        CurrentUserNotFoundErr:
            Label 'Не вдалося знайти поточного користувача в таблиці користувачів.';
}