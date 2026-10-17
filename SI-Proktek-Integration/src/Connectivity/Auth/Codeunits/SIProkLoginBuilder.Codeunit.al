codeunit 57051 "SI Prok Login Builder"
{
    procedure Build(CompanyCode: Text; Username: Text; Password: SecretText): SecretText
    var
        Adapter: Codeunit "SI Prok Login Secret Adapter";
    begin
        exit(Adapter.BuildBody(CompanyCode, Username, Password));
    end;
}
