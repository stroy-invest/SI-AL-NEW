codeunit 57051 "SI Prok Login Builder"
{
    procedure Build(
        CompanyCode: Text;
        Username: Text;
        Password: Text): Text
    var
        LoginJson: JsonObject;
        RequestBody: Text;
    begin
        if CompanyCode = '' then
            Error(
                'Не вказано код компанії Proktek.');

        if Username = '' then
            Error(
                'Не вказано користувача Proktek.');

        if Password = '' then
            Error(
                'Не налаштовано пароль Proktek.');

        LoginJson.Add(
            'companyCode',
            CompanyCode);

        LoginJson.Add(
            'username',
            Username);

        LoginJson.Add(
            'password',
            Password);

        LoginJson.WriteTo(
            RequestBody);

        exit(RequestBody);
    end;
}