codeunit 57053 "SI Prok Connection Mgt."
{
    procedure SetActive(var Connection: Record "SI Prok Connection")
    var
        OtherConnection: Record "SI Prok Connection";
    begin
        ValidateConnection(Connection);

        if Connection.Environment = Connection.Environment::Production then
            if not Confirm(
                'Ви активуєте ПРОДУКТИВНЕ підключення Proktek %1. Усі наступні інтеграційні запити використовуватимуть цей профіль. Продовжити?',
                false,
                Connection.Code)
            then
                exit;

        OtherConnection.SetRange(Active, true);
        OtherConnection.SetFilter(Code, '<>%1', Connection.Code);
        if OtherConnection.FindSet(true) then
            repeat
                OtherConnection.Active := false;
                OtherConnection.Modify(false);
            until OtherConnection.Next() = 0;

        Connection.Active := true;
        Connection.Modify(false);
    end;

    procedure GetActive(var Connection: Record "SI Prok Connection")
    begin
        if not TryGetActive(Connection) then
            Error('Не визначено активний профіль підключення Proktek.');
    end;

    procedure TryGetActive(var Connection: Record "SI Prok Connection"): Boolean
    var
        Candidate: Record "SI Prok Connection";
        ProviderContext: Codeunit "SI EDS Provider Context";
        OverrideProviderCode: Code[50];
        FoundOverrideConnection: Boolean;
    begin
        Connection.Reset();

        // A Foundation EDS provider scope is session-local and temporarily overrides
        // the persistent Proktek Active flag. This allows operations such as export
        // to run against an explicitly selected profile without changing global state.
        Candidate.Reset();
        if Candidate.FindSet() then
            repeat
                if (Candidate."EDS Service Code" <> '') and
                   ProviderContext.TryGetProviderOverride(Candidate."EDS Service Code", OverrideProviderCode) and
                   (OverrideProviderCode = Candidate."EDS Provider Code")
                then begin
                    if FoundOverrideConnection then
                        Error(
                            'Для тимчасового EDS provider context знайдено більше одного профілю Proktek (%1).',
                            OverrideProviderCode);

                    Connection := Candidate;
                    FoundOverrideConnection := true;
                end;
            until Candidate.Next() = 0;

        if FoundOverrideConnection then
            exit(true);

        Connection.Reset();
        Connection.SetRange(Active, true);
        if not Connection.FindFirst() then begin
            Connection.Reset();
            exit(false);
        end;

        if Connection.Next() <> 0 then
            Error('Налаштовано більше одного активного профілю Proktek.');

        Connection.Reset();
        Connection.SetRange(Active, true);
        Connection.FindFirst();
        exit(true);
    end;

    local procedure ValidateConnection(var Connection: Record "SI Prok Connection")
    begin
        Connection.TestField(Code);
        Connection.TestField("EDS Service Code");
        Connection.TestField("EDS Provider Code");
        Connection.TestField("EDS Login Operation");
        Connection.TestField("Company Code");
        Connection.TestField(Username);
        Connection.TestField("Password Credential Code");
    end;
}
