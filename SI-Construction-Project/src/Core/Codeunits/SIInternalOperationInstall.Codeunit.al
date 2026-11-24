codeunit 60042 "SI Internal Operation Install"
{
    Subtype = Install;
    trigger OnInstallAppPerCompany()
    var
        Seed: Codeunit "SI Internal Operation Seed";
    begin
        Seed.Initialize();
    end;
}
