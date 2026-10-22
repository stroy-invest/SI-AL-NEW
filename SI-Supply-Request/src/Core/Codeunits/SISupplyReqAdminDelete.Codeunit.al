codeunit 61090 "SI Supply Req Admin Delete"
{
    Permissions = tabledata "Access Control" = r;
    procedure CheckSuperPermission()
    var
        Access: Record "Access Control";
    begin
        Access.SetRange("User Security ID", UserSecurityId());
        Access.SetRange("Role ID", 'SUPER');
        if Access.FindSet() then
            repeat
                if (Access."Company Name" = '') or (Access."Company Name" = CompanyName()) then
                    exit;
            until Access.Next() = 0;
        Error('Примусове видалення заявки доступне лише користувачу з набором дозволів SUPER.');
    end;

    procedure CheckDependencies(Request: Record "SI Supply Req Header")
    var
        Decision: Record "SI Supply Decision Header";
        Demand: Record "SI Planning Demand";
    begin
        Decision.SetRange("Request No.", Request."No.");
        if not Decision.IsEmpty() then
            Error('Неможливо видалити заявку %1: існує рішення щодо забезпечення. Спочатку видаліть рішення.', Request."No.");
        Demand.SetRange("Request No.", Request."No.");
        if not Demand.IsEmpty() then
            Error('Неможливо видалити заявку %1: існують пов’язані записи планування.', Request."No.");
    end;

    procedure WriteAudit(Request: Record "SI Supply Req Header")
    var
        Audit: Record "SI Supply Req Delete Audit";
    begin
        Audit.Init();
        Audit."Request No." := Request."No.";
        Audit."Deleted At" := CurrentDateTime();
        Audit."Deleted By" := CopyStr(UserId(), 1, MaxStrLen(Audit."Deleted By"));
        Audit."Request Status" := Format(Request.Status);
        Audit.Insert(true);
    end;
}
