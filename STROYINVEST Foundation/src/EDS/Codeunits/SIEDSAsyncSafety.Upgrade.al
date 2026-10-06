codeunit 50470 "SI EDS Async Safety Upgrade"
{
    Subtype = Upgrade;

    trigger OnUpgradePerCompany()
    begin
        ConfigureKnownSafeOperations();
    end;

    local procedure ConfigureKnownSafeOperations()
    var
        Operation: Record "SI EDS Operation";
    begin
        // GET-USR is a provider contract where repeating the same request after HTTP 202
        // polls the already-started refresh for the same contractor identifier.
        if Operation.Get('UA-REGISTRY', 'GET-USR') then begin
            Operation."Async Retry Mode" := Operation."Async Retry Mode"::"Repeat Same Operation";
            Operation."Async Max Attempts" := 10;
            Operation.Modify();
        end;

        // All other operations intentionally keep the safe default: None.
        // In particular, GET-INDIVIDUAL-BY-CODE is a start operation that returns
        // a resultId and MUST NOT be repeated by the generic worker.
    end;
}
