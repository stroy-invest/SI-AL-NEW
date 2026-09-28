codeunit 50461 "SI EDS Secret Mgt."
{
    procedure SetSecret(ProviderCode: Code[50]; CredentialCode: Code[50]; SecretValue: SecretText)
    var
        StorageKey: Text;
    begin
        if SecretValue.IsEmpty() then
            Error('Секретне значення не може бути порожнім.');

        StorageKey := GetStorageKey(ProviderCode, CredentialCode);
        if not IsolatedStorage.SetEncrypted(StorageKey, SecretValue, DataScope::Module) then
            Error('Не вдалося безпечно зберегти облікові дані EDS.');
    end;

    [NonDebuggable]
    procedure SetSecretFromText(ProviderCode: Code[50]; CredentialCode: Code[50]; SecretValue: Text)
    var
        StorageKey: Text;
    begin
        if SecretValue = '' then
            Error('Секретне значення не може бути порожнім.');

        StorageKey := GetStorageKey(ProviderCode, CredentialCode);
        if not IsolatedStorage.SetEncrypted(StorageKey, SecretValue, DataScope::Module) then
            Error('Не вдалося безпечно зберегти облікові дані EDS.');
    end;

    procedure TryGetSecret(ProviderCode: Code[50]; CredentialCode: Code[50]; var SecretValue: SecretText): Boolean
    var
        StorageKey: Text;
    begin
        Clear(SecretValue);
        StorageKey := GetStorageKey(ProviderCode, CredentialCode);

        if not IsolatedStorage.Contains(StorageKey, DataScope::Module) then
            exit(false);

        exit(IsolatedStorage.Get(StorageKey, DataScope::Module, SecretValue));
    end;

    procedure GetSecret(ProviderCode: Code[50]; CredentialCode: Code[50]): SecretText
    var
        SecretValue: SecretText;
    begin
        if not TryGetSecret(ProviderCode, CredentialCode, SecretValue) then
            Error(
                'Для провайдера %1 не налаштовано секрет %2.',
                ProviderCode,
                CredentialCode);

        exit(SecretValue);
    end;

    procedure HasSecret(ProviderCode: Code[50]; CredentialCode: Code[50]): Boolean
    begin
        exit(IsolatedStorage.Contains(GetStorageKey(ProviderCode, CredentialCode), DataScope::Module));
    end;

    procedure DeleteSecret(ProviderCode: Code[50]; CredentialCode: Code[50])
    var
        StorageKey: Text;
    begin
        StorageKey := GetStorageKey(ProviderCode, CredentialCode);
        if IsolatedStorage.Contains(StorageKey, DataScope::Module) then
            IsolatedStorage.Delete(StorageKey, DataScope::Module);
    end;

    local procedure GetStorageKey(ProviderCode: Code[50]; CredentialCode: Code[50]): Text
    begin
        if ProviderCode = '' then
            Error('Не вказано код провайдера EDS.');
        if CredentialCode = '' then
            Error('Не вказано код облікових даних EDS.');

        exit(StrSubstNo('SI.EDS.%1.%2', ProviderCode, CredentialCode));
    end;
}
