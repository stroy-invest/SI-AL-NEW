codeunit 57099 "SI Prok Login Secret Adapter"
{
    // Contract: Proktek password is restricted to ASCII A-Z, a-z, 0-9.
    // The AL SecretText API cannot inspect characters or JSON-escape a secret.
    // This adapter is valid ONLY for passwords conforming to that contract.
    // Credential provisioning must enforce the contract before PROD release.
    [NonDebuggable]
    procedure BuildBody(CompanyCode: Text; Username: Text; Password: SecretText): SecretText
    var
        CompanyValue: JsonValue;
        UsernameValue: JsonValue;
        CompanyJson: Text;
        UsernameJson: Text;
    begin
        if CompanyCode = '' then
            Error('Не вказано код компанії Proktek.');
        if Username = '' then
            Error('Не вказано користувача Proktek.');
        if Password.IsEmpty() then
            Error('Не налаштовано пароль Proktek.');

        // JsonValue serializes the non-secret strings with correct escaping.
        CompanyValue.SetValue(CompanyCode);
        CompanyValue.WriteTo(CompanyJson);
        UsernameValue.SetValue(Username);
        UsernameValue.WriteTo(UsernameJson);

        // Password is never materialized as Text. Safe JSON only under
        // the documented ASCII-alphanumeric password contract.
        exit(SecretStrSubstNo(
            '{"companyCode":%1,"username":%2,"password":"%3"}',
            CompanyJson, UsernameJson, Password));
    end;
}
