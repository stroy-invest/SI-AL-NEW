codeunit 50468 "SI EDS Rate Limit Mgt."
{
    Permissions =
        tabledata "SI EDS Provider Rate Limit" = RIMD,
        tabledata "SI EDS Rate Limit Usage" = RIMD;

    procedure WaitForSlot(ProviderCode: Code[50])
    var
        WaitMs: Integer;
    begin
        EnsureDefaultProfile();
        repeat
            WaitMs := GetRequiredWaitMs(ProviderCode);
            if WaitMs > 0 then
                Sleep(WaitMs);
        until WaitMs = 0;
        RegisterRequest(ProviderCode);
    end;

    procedure UsesDefaultProfile(ProviderCode: Code[50]): Boolean
    var
        RateLimit: Record "SI EDS Provider Rate Limit";
    begin
        RateLimit.SetRange("Provider Code", ProviderCode);
        RateLimit.SetRange(Enabled, true);
        exit(RateLimit.IsEmpty());
    end;

    local procedure GetRequiredWaitMs(ProviderCode: Code[50]): Integer
    var
        RateLimit: Record "SI EDS Provider Rate Limit";
        EffectiveProviderCode: Code[50];
        WaitMs: Integer;
        RuleWaitMs: Integer;
    begin
        EffectiveProviderCode := GetEffectiveProfileCode(ProviderCode);
        RateLimit.SetRange("Provider Code", EffectiveProviderCode);
        RateLimit.SetRange(Enabled, true);
        if RateLimit.FindSet() then
            repeat
                RuleWaitMs := GetRuleWaitMs(ProviderCode, RateLimit);
                if RuleWaitMs > WaitMs then
                    WaitMs := RuleWaitMs;
            until RateLimit.Next() = 0;
        exit(WaitMs);
    end;

    local procedure GetRuleWaitMs(ProviderCode: Code[50]; RateLimit: Record "SI EDS Provider Rate Limit"): Integer
    var
        Usage: Record "SI EDS Rate Limit Usage";
        ThresholdAt: DateTime;
        OldestAt: DateTime;
        CountInWindow: Integer;
        EffectiveMax: Integer;
        Remaining: Duration;
    begin
        EffectiveMax := RateLimit.EffectiveMaxRequests();
        ThresholdAt := CurrentDateTime - (RateLimit."Window Seconds" * 1000);

        Usage.SetCurrentKey("Provider Code", "Requested At");
        Usage.SetRange("Provider Code", ProviderCode);
        Usage.SetFilter("Requested At", '>%1', ThresholdAt);
        CountInWindow := Usage.Count();
        if CountInWindow < EffectiveMax then
            exit(0);

        if Usage.FindFirst() then begin
            OldestAt := Usage."Requested At";
            Remaining := (OldestAt + (RateLimit."Window Seconds" * 1000)) - CurrentDateTime;
            if Remaining > 0 then
                exit(Round(Remaining, 1, '>') + 50);
        end;
        exit(50);
    end;

    local procedure RegisterRequest(ProviderCode: Code[50])
    var
        Usage: Record "SI EDS Rate Limit Usage";
    begin
        Usage.LockTable();
        Usage.Init();
        Usage."Provider Code" := ProviderCode;
        Usage."Requested At" := CurrentDateTime;
        Usage.Insert(true);
        CleanupOldUsage();
    end;

    local procedure GetEffectiveProfileCode(ProviderCode: Code[50]): Code[50]
    var
        RateLimit: Record "SI EDS Provider Rate Limit";
    begin
        RateLimit.SetRange("Provider Code", ProviderCode);
        RateLimit.SetRange(Enabled, true);
        if not RateLimit.IsEmpty() then
            exit(ProviderCode);
        exit('OTHER-PROVIDER');
    end;

    local procedure EnsureDefaultProfile()
    var
        RateLimit: Record "SI EDS Provider Rate Limit";
    begin
        if RateLimit.Get('OTHER-PROVIDER', 10) then
            exit;

        RateLimit.Init();
        RateLimit."Provider Code" := 'OTHER-PROVIDER';
        RateLimit.Sequence := 10;
        RateLimit."Window Seconds" := 60;
        RateLimit."Max Requests" := 60;
        RateLimit."Safety Margin %" := 80;
        RateLimit.Enabled := true;
        RateLimit.Description := 'Типовий профіль для провайдерів без власних правил';
        RateLimit.Insert();
    end;

    local procedure CleanupOldUsage()
    var
        Usage: Record "SI EDS Rate Limit Usage";
    begin
        Usage.SetFilter("Requested At", '<%1', CurrentDateTime - 172800000);
        if not Usage.IsEmpty() then
            Usage.DeleteAll();
    end;
}
