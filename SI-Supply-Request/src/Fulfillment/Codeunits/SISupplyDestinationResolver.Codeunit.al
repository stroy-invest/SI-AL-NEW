codeunit 61060 "SI Supply Destination Resolver"
{
    // Project Location is the authoritative destination for every supply method.
    // The Decision and Allocation fields are persisted projections of this value.
    // Resolve strictly within the requested decision context; never search another decision.
    procedure ResolveProjectDestination(DecisionNo: Code[20]): Code[10]
    var
        DecisionHeader: Record "SI Supply Decision Header";
    begin
        if not DecisionHeader.Get(DecisionNo) then
            Error('Не знайдено рішення %1.', DecisionNo);
        exit(ResolveProjectDestinationForRequest(DecisionNo, DecisionHeader."Request No."));
    end;

    procedure ResolveProjectDestinationForRequest(DecisionNo: Code[20]; ExpectedRequestNo: Code[20]): Code[10]
    var
        DecisionHeader: Record "SI Supply Decision Header";
        RequestHeader: Record "SI Supply Req Header";
        Location: Record Location;
        LocationSetup: Record "SI Location Setup";
        DestinationCode: Code[10];
    begin
        if DecisionNo = '' then
            Error('Не задано номер рішення для визначення складу призначення.');
        if ExpectedRequestNo = '' then
            Error('Для рішення %1 не задано номер пов’язаної заявки.', DecisionNo);
        if not DecisionHeader.Get(DecisionNo) then
            Error('Не знайдено рішення %1 (очікувана заявка %2).', DecisionNo, ExpectedRequestNo);
        if DecisionHeader."Request No." <> ExpectedRequestNo then
            Error('Невідповідність зв’язку: рішення %1 посилається на заявку %2, очікується %3.',
                DecisionNo, DecisionHeader."Request No.", ExpectedRequestNo);
        // A persisted decision carries its own project/destination snapshot.
        // Do not require the original request to exist for allocation operations:
        // legacy/orphan decisions may still be present in the database.
        // When the request exists, verify that the snapshots are consistent.
        if RequestHeader.Get(ExpectedRequestNo) then begin
            RequestHeader.TestField("Project No.");
            RequestHeader.TestField("Project Location Code");
            if (DecisionHeader."Project No." <> '') and
               (DecisionHeader."Project No." <> RequestHeader."Project No.") then
                Error('Проєкт рішення %1 не відповідає проєкту заявки %2.', DecisionNo, ExpectedRequestNo);
            if (DecisionHeader."Project Location Code" <> '') and
               (DecisionHeader."Project Location Code" <> RequestHeader."Project Location Code") then
                Error('Склад проєкту в рішенні %1 (%2) відрізняється від складу заявки %3 (%4).',
                    DecisionNo, DecisionHeader."Project Location Code", ExpectedRequestNo, RequestHeader."Project Location Code");
        end;

        // Prefer the decision's persisted project location. Only a decision
        // without that snapshot may fall back to its existing request.
        DestinationCode := DecisionHeader."Project Location Code";
        if DestinationCode = '' then begin
            if not RequestHeader.Get(ExpectedRequestNo) then
                Error('Рішення %1 не має складу проєкту, а заявка %2 відсутня. Потрібне відновлення даних.',
                    DecisionNo, ExpectedRequestNo);
            RequestHeader.TestField("Project Location Code");
            DestinationCode := RequestHeader."Project Location Code";
        end;
        if not Location.Get(DestinationCode) then
            Error('Не знайдено склад проєкту %1 для заявки %2.', DestinationCode, ExpectedRequestNo);
        if LocationSetup.Get('') then
            if LocationSetup."Project Location Type" <> '' then
                if Location."SI Location Type Code" <> LocationSetup."Project Location Type" then
                    Error('Склад %1 не має налаштованого типу складу проєкту %2.',
                        Location.Code, LocationSetup."Project Location Type");
        exit(DestinationCode);
    end;

    procedure EnsureAllocationDestination(var Allocation: Record "SI Supply Allocation")
    var
        DecisionLine: Record "SI Supply Decision Line";
        DestinationCode: Code[10];
        StoredAllocation: Record "SI Supply Allocation";
    begin
        DestinationCode := ResolveProjectDestination(Allocation."Decision No.");
        if not DecisionLine.Get(Allocation."Decision No.", Allocation."Decision Line No.") then
            Error('Не знайдено рядок рішення %1/%2.', Allocation."Decision No.", Allocation."Decision Line No.");

        if not IsNullGuid(Allocation."Execution System ID") then begin
            if (Allocation."Target Location Code" <> DestinationCode) or
               (DecisionLine."Target Location Code" <> DestinationCode) then
                Error('Розподіл %1/%2/%3 має документ виконання та інший склад призначення. Автоматична зміна заборонена.',
                    Allocation."Decision No.", Allocation."Decision Line No.", Allocation."Line No.");
            exit;
        end;

        if DecisionLine."Target Location Code" <> DestinationCode then begin
            DecisionLine."Target Location Code" := DestinationCode;
            DecisionLine.Modify(true);
        end;
        if Allocation."Target Location Code" <> DestinationCode then begin
            Allocation."Target Location Code" := DestinationCode;
            // Existing records are repaired without recursively invoking OnModify.
            // For new records the caller's subsequent Insert(true) persists the value.
            if StoredAllocation.Get(Allocation."Decision No.", Allocation."Decision Line No.", Allocation."Line No.") then begin
                StoredAllocation."Target Location Code" := DestinationCode;
                StoredAllocation.Modify(false);
            end;
        end;
    end;

    procedure AssertDestination(Allocation: Record "SI Supply Allocation")
    var
        DecisionLine: Record "SI Supply Decision Line";
        DestinationCode: Code[10];
    begin
        DestinationCode := ResolveProjectDestination(Allocation."Decision No.");
        if not DecisionLine.Get(Allocation."Decision No.", Allocation."Decision Line No.") then
            Error('Не знайдено рядок рішення %1/%2.', Allocation."Decision No.", Allocation."Decision Line No.");
        if DecisionLine."Target Location Code" <> DestinationCode then
            Error('Склад призначення рядка рішення %1/%2 не відповідає складу проєкту %3.',
                Allocation."Decision No.", Allocation."Decision Line No.", DestinationCode);
        if Allocation."Target Location Code" <> DestinationCode then
            Error('Склад призначення розподілу %1/%2/%3 не відповідає складу проєкту %4.',
                Allocation."Decision No.", Allocation."Decision Line No.", Allocation."Line No.", DestinationCode);
    end;
}
