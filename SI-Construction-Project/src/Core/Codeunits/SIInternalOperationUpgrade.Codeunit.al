codeunit 60041 "SI Internal Operation Upgrade"
{
    Subtype = Upgrade;
    trigger OnUpgradePerCompany()
    var
        Seed: Codeunit "SI Internal Operation Seed";
    begin
        Seed.Initialize();
    end;
}
