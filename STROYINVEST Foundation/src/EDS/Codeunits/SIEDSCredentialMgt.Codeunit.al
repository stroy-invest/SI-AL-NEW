codeunit 50462 "SI EDS Credential Mgt."
{
    procedure SetSecretText(
        ProviderCode: Code[50];
        CredentialCode: Code[50];
        Value: Text)
    var
        StorageKey: Text;
    begin
        ValidateCodes(
            ProviderCode,
            CredentialCode);

        if Value = '' then
            Error(
                'Значення облікових даних не може бути порожнім.');

        StorageKey :=
            GetTextStorageKey(
                ProviderCode,
                CredentialCode);

        if not IsolatedStorage.SetEncrypted(
            StorageKey,
            Value,
            DataScope::Module)
        then
            Error(
                'Не вдалося зберегти захищені облікові дані %1 / %2.',
                ProviderCode,
                CredentialCode);
    end;

    procedure GetSecretText(
        ProviderCode: Code[50];
        CredentialCode: Code[50]): Text
    var
        StorageKey: Text;
        Value: Text;
    begin
        ValidateCredential(
            ProviderCode,
            CredentialCode);

        StorageKey :=
            GetTextStorageKey(
                ProviderCode,
                CredentialCode);

        if not IsolatedStorage.Contains(
            StorageKey,
            DataScope::Module)
        then
            Error(
                'Для провайдера %1 не налаштовано Text-compatible credential %2.',
                ProviderCode,
                CredentialCode);

        if not IsolatedStorage.Get(
            StorageKey,
            DataScope::Module,
            Value)
        then
            Error(
                'Не вдалося прочитати захищені облікові дані %1 / %2.',
                ProviderCode,
                CredentialCode);

        exit(Value);
    end;

    procedure HasSecretText(
        ProviderCode: Code[50];
        CredentialCode: Code[50]): Boolean
    var
        StorageKey: Text;
    begin
        if (ProviderCode = '') or
           (CredentialCode = '')
        then
            exit(false);

        StorageKey :=
            GetTextStorageKey(
                ProviderCode,
                CredentialCode);

        exit(
            IsolatedStorage.Contains(
                StorageKey,
                DataScope::Module));
    end;

    procedure DeleteSecretText(
        ProviderCode: Code[50];
        CredentialCode: Code[50])
    var
        StorageKey: Text;
    begin
        if (ProviderCode = '') or
           (CredentialCode = '')
        then
            exit;

        StorageKey :=
            GetTextStorageKey(
                ProviderCode,
                CredentialCode);

        if IsolatedStorage.Contains(
            StorageKey,
            DataScope::Module)
        then
            IsolatedStorage.Delete(
                StorageKey,
                DataScope::Module);
    end;

    procedure HasSecret(
        ProviderCode: Code[50];
        CredentialCode: Code[50]): Boolean
    begin
        // Для нового runtime вважаємо credential налаштованим,
        // якщо існує Text-compatible encrypted value.
        exit(
            HasSecretText(
                ProviderCode,
                CredentialCode));
    end;

    local procedure ValidateCredential(
        ProviderCode: Code[50];
        CredentialCode: Code[50])
    var
        Credential: Record "SI EDS Credential";
    begin
        ValidateCodes(
            ProviderCode,
            CredentialCode);

        if not Credential.Get(
            ProviderCode,
            CredentialCode)
        then
            Error(
                'Облікові дані EDS %1 / %2 не налаштовані.',
                ProviderCode,
                CredentialCode);

        if not Credential.Enabled then
            Error(
                'Облікові дані EDS %1 / %2 вимкнені.',
                ProviderCode,
                CredentialCode);
    end;

    local procedure ValidateCodes(
        ProviderCode: Code[50];
        CredentialCode: Code[50])
    begin
        if ProviderCode = '' then
            Error(
                'Не вказано код провайдера EDS.');

        if CredentialCode = '' then
            Error(
                'Не вказано код облікових даних EDS.');
    end;

    local procedure GetTextStorageKey(
        ProviderCode: Code[50];
        CredentialCode: Code[50]): Text
    begin
        exit(
            StrSubstNo(
                'SI-EDS-TEXT|%1|%2',
                ProviderCode,
                CredentialCode));
    end;
}