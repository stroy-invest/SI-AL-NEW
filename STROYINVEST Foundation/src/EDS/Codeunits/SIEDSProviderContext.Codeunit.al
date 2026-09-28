codeunit 50463 "SI EDS Provider Context"
{
    SingleInstance = true;

    procedure BeginScope(ServiceCode: Code[50]; ProviderCode: Code[50]; var ScopeToken: Guid)
    var
        EDSService: Record "SI EDS Service";
        EDSProvider: Record "SI EDS Provider";
        ServiceKey: Text;
        TokenKey: Text;
        PreviousProvider: Text;
        HadPrevious: Boolean;
    begin
        if ServiceCode = '' then
            Error('Не вказано код сервісу EDS для provider scope.');
        if ProviderCode = '' then
            Error('Не вказано код провайдера EDS для provider scope.');

        if not EDSService.Get(ServiceCode) then
            Error('Сервіс EDS %1 не налаштований.', ServiceCode);
        if not EDSProvider.Get(ProviderCode) then
            Error('Провайдер EDS %1 не налаштований.', ProviderCode);
        if not EDSProvider.Enabled then
            Error('Провайдер EDS %1 вимкнений.', ProviderCode);

        ScopeToken := CreateGuid();
        ServiceKey := NormalizeKey(ServiceCode);
        TokenKey := Format(ScopeToken, 0, 4);

        HadPrevious := ProviderOverrideByService.Get(ServiceKey, PreviousProvider);

        ScopeServiceByToken.Add(TokenKey, ServiceKey);
        ScopeHadPreviousByToken.Add(TokenKey, HadPrevious);
        if HadPrevious then
            ScopePreviousProviderByToken.Add(TokenKey, PreviousProvider);

        SetOverride(ServiceKey, ProviderCode);
    end;

    procedure EndScope(ScopeToken: Guid)
    var
        ServiceKey: Text;
        TokenKey: Text;
        PreviousProvider: Text;
        HadPrevious: Boolean;
    begin
        if IsNullGuid(ScopeToken) then
            exit;

        TokenKey := Format(ScopeToken, 0, 4);
        if not ScopeServiceByToken.Get(TokenKey, ServiceKey) then
            exit;

        ScopeHadPreviousByToken.Get(TokenKey, HadPrevious);
        if HadPrevious then begin
            ScopePreviousProviderByToken.Get(TokenKey, PreviousProvider);
            SetOverride(ServiceKey, PreviousProvider);
        end else
            ProviderOverrideByService.Remove(ServiceKey);

        ScopeServiceByToken.Remove(TokenKey);
        ScopeHadPreviousByToken.Remove(TokenKey);
        ScopePreviousProviderByToken.Remove(TokenKey);
    end;

    procedure TryGetProviderOverride(ServiceCode: Code[50]; var ProviderCode: Code[50]): Boolean
    var
        ProviderText: Text;
    begin
        Clear(ProviderCode);
        if ServiceCode = '' then
            exit(false);

        if not ProviderOverrideByService.Get(NormalizeKey(ServiceCode), ProviderText) then
            exit(false);

        ProviderCode := CopyStr(ProviderText, 1, MaxStrLen(ProviderCode));
        exit(ProviderCode <> '');
    end;

    procedure HasProviderOverride(ServiceCode: Code[50]; ProviderCode: Code[50]): Boolean
    var
        CurrentProviderCode: Code[50];
    begin
        if not TryGetProviderOverride(ServiceCode, CurrentProviderCode) then
            exit(false);

        exit(CurrentProviderCode = ProviderCode);
    end;

    local procedure SetOverride(ServiceKey: Text; ProviderCode: Code[50])
    begin
        if ProviderOverrideByService.ContainsKey(ServiceKey) then
            ProviderOverrideByService.Set(ServiceKey, ProviderCode)
        else
            ProviderOverrideByService.Add(ServiceKey, ProviderCode);
    end;

    local procedure NormalizeKey(ServiceCode: Code[50]): Text
    begin
        exit(UpperCase(Format(ServiceCode)));
    end;

    var
        ProviderOverrideByService: Dictionary of [Text, Text];
        ScopeServiceByToken: Dictionary of [Text, Text];
        ScopePreviousProviderByToken: Dictionary of [Text, Text];
        ScopeHadPreviousByToken: Dictionary of [Text, Boolean];
}
