codeunit 50462 "SI EDS Credential Mgt."
{
    // Canonical storage: SI.EDS.<Provider>.<Credential> via Secret Mgt.
    // Text is accepted only at the existing credential-entry boundary.
    [NonDebuggable]
    procedure SetSecretText(ProviderCode: Code[50]; CredentialCode: Code[50]; Value: Text)
    var
        SecretMgt: Codeunit "SI EDS Secret Mgt.";
    begin
        ValidateCodes(ProviderCode, CredentialCode);
        SecretMgt.SetSecretFromText(ProviderCode, CredentialCode, Value);
    end;

    procedure GetCredentialSecret(ProviderCode: Code[50]; CredentialCode: Code[50]): SecretText
    var
        SecretMgt: Codeunit "SI EDS Secret Mgt.";
    begin
        ValidateCredential(ProviderCode, CredentialCode);
        exit(SecretMgt.GetSecret(ProviderCode, CredentialCode));
    end;

    // COMPATIBILITY ONLY: legacy Text-returning API for previously deployed dependents.
    // Do not call from new integrations; remove only after all consumers migrate.
    [NonDebuggable]
    procedure GetSecretText(ProviderCode: Code[50]; CredentialCode: Code[50]): Text
    var
        StorageKey: Text;
        Value: Text;
    begin
        ValidateCredential(ProviderCode, CredentialCode);
        StorageKey := GetTextStorageKey(ProviderCode, CredentialCode);
        if not IsolatedStorage.Get(StorageKey, DataScope::Module, Value) then
            Error('EDS legacy credential недоступний. Потрібна міграція P1/P2.');
        exit(Value);
    end;

    procedure HasSecretText(ProviderCode: Code[50]; CredentialCode: Code[50]): Boolean
    begin
        exit(HasSecret(ProviderCode, CredentialCode));
    end;

    procedure HasSecret(ProviderCode: Code[50]; CredentialCode: Code[50]): Boolean
    var
        SecretMgt: Codeunit "SI EDS Secret Mgt.";
    begin
        if (ProviderCode = '') or (CredentialCode = '') then
            exit(false);
        exit(SecretMgt.HasSecret(ProviderCode, CredentialCode));
    end;

    // Deletes both namespaces only on explicit user action.
    procedure DeleteSecretText(ProviderCode: Code[50]; CredentialCode: Code[50])
    var
        SecretMgt: Codeunit "SI EDS Secret Mgt.";
        LegacyKey: Text;
    begin
        if (ProviderCode = '') or (CredentialCode = '') then
            exit;
        SecretMgt.DeleteSecret(ProviderCode, CredentialCode);
        LegacyKey := GetTextStorageKey(ProviderCode, CredentialCode);
        if IsolatedStorage.Contains(LegacyKey, DataScope::Module) then
            IsolatedStorage.Delete(LegacyKey, DataScope::Module);
    end;

    // Explicit migration: do not erase the old key until canonical write is verified.
    // Run only after reviewing the provider/credential scope and taking a backup.
    [NonDebuggable]
    procedure MigrateLegacyCredential(ProviderCode: Code[50]; CredentialCode: Code[50]): Boolean
    var
        SecretMgt: Codeunit "SI EDS Secret Mgt.";
        LegacyKey: Text;
        LegacyValue: Text;
    begin
        // Migration includes disabled credentials; enabled state controls usage,
        // not whether a stored secret can be migrated.
        ValidateCodes(ProviderCode, CredentialCode);
        if SecretMgt.HasSecret(ProviderCode, CredentialCode) then
            exit(false);
        LegacyKey := GetTextStorageKey(ProviderCode, CredentialCode);
        if not IsolatedStorage.Contains(LegacyKey, DataScope::Module) then
            Error('EDS legacy credential відсутній для %1 / %2.', ProviderCode, CredentialCode);
        if not IsolatedStorage.Get(LegacyKey, DataScope::Module, LegacyValue) then
            Error('EDS legacy credential не вдалося прочитати.');
        SecretMgt.SetSecretFromText(ProviderCode, CredentialCode, LegacyValue);
        Clear(LegacyValue);
        if not SecretMgt.HasSecret(ProviderCode, CredentialCode) then
            Error('EDS canonical credential не підтверджено після міграції.');
        // Do not delete the legacy key here; cleanup is a separate approved step.
        exit(true);
    end;

    procedure HasLegacySecret(ProviderCode: Code[50]; CredentialCode: Code[50]): Boolean
    begin
        if (ProviderCode = '') or (CredentialCode = '') then
            exit(false);
        exit(IsolatedStorage.Contains(
            GetTextStorageKey(ProviderCode, CredentialCode), DataScope::Module));
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