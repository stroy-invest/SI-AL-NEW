codeunit 57050 "SI Prok Auth Mgt."
{
    procedure Login(
        var Connection: Record "SI Prok Connection";
        var Session: Record "SI Prok Session")
    var
        RuntimeParam: Record "SI EDS Runtime Param" temporary;
        ResponseBuffer: Record "SI EDS Response Buffer" temporary;
        EDSOrchestrator: Codeunit "SI EDS Orchestrator";
        CredentialMgt: Codeunit "SI EDS Credential Mgt.";
        LoginBuilder: Codeunit "SI Prok Login Builder";
        LoginResolver: Codeunit "SI Prok Login Resolver";
        Password: Text;
        RequestBody: Text;
    begin
        Connection.TestField(Code);
        Connection.TestField("EDS Service Code");
        Connection.TestField("EDS Provider Code");
        Connection.TestField("EDS Login Operation");
        Connection.TestField("Password Credential Code");
        Connection.TestField("Company Code");
        Connection.TestField(Username);

        Password :=
            CredentialMgt.GetSecretText(
                Connection."EDS Provider Code",
                Connection."Password Credential Code");

        RequestBody :=
            LoginBuilder.Build(
                Connection."Company Code",
                Connection.Username,
                Password);

        // Пароль як окреме значення більше не потрібний.
        Clear(Password);

        EDSOrchestrator.ExecuteProviderBody(
            Connection."EDS Service Code",
            Connection."EDS Login Operation",
            Connection."EDS Provider Code",
            RuntimeParam,
            RequestBody,
            'application/json-patch+json',
            'text/plain',
            ResponseBuffer);

        Clear(RequestBody);

        LoginResolver.Apply(
            ResponseBuffer,
            Connection.Code,
            Session);

        Connection."Last Test At" :=
            CurrentDateTime;

        Connection."Last Test Result" :=
            CopyStr(
                'Авторизація успішна',
                1,
                MaxStrLen(
                    Connection."Last Test Result"));

        Connection.Modify(false);
    end;

    procedure EnsureSession(
        var Connection: Record "SI Prok Connection";
        var Session: Record "SI Prok Session")
    begin
        Connection.TestField(Code);

        if Session.Get(
            Connection.Code)
        then
            if Session.IsUsable() then
                exit;

        Login(
            Connection,
            Session);
    end;

    procedure RefreshSession(
        var Connection: Record "SI Prok Connection";
        var Session: Record "SI Prok Session")
    begin
        Connection.TestField(Code);

        if Session.Get(Connection.Code) then
            Session.ClearSession();

        Login(
            Connection,
            Session);
    end;

    procedure GetSessionGuid(
        var Connection: Record "SI Prok Connection"): Guid
    var
        Session: Record "SI Prok Session";
    begin
        EnsureSession(
            Connection,
            Session);

        exit(
            Session."Session GUID");
    end;
}