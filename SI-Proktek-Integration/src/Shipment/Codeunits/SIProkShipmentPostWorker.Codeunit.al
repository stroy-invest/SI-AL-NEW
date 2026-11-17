codeunit 57148 "SI Prok Shipment Post Worker"
{
    TableNo = "SI Prok Shipment";

    trigger OnRun()
    var
        Fact: Record "SI Prok Production Fact";
        Attempt: Record "SI Prok Posting Attempt";
        Connection: Record "SI Prok Connection";
        Env: Codeunit "Environment Information";
        Prep: Codeunit "SI Prok Process Journal Prep";
        Control: Codeunit "SI Prok Process Control";
        Posting: Codeunit "SI Prok Process Posting";
        Posted: Integer;
        Missing: Integer;
    begin
        Rec.Get(Rec."Entry No.");
        if Rec.Status <> Rec.Status::Closed then
            Error('SI Process: спочатку потрібно зафіксувати відвантаження.');
        if not Fact.Get(Rec."Production Fact Entry No.") then
            Error('SI Process: факт виробництва для Shipment %1 не знайдено.', Rec."Entry No.");
        if Fact."Production UUID" <> Rec."Production UUID" then
            Error('SI Process: UUID факту і Shipment не збігаються.');
        Connection.Get(Rec."Connection Code");
        if (not Env.IsSandbox()) and (Connection.Environment <> Connection.Environment::Production) then
            Error('SI Process: DEMO/інший профіль не можна проводити в продуктивному BC.');
        if Attempt.Get(Fact."Production UUID") then
            Error('SI Process: спроба %1 вже існує (%2). Повтор заборонено; використайте аудит/Recovery.',
                Fact."Production UUID", Attempt.Status);
        if Fact."Accounting Document No." = '' then
            Prep.Prepare(Fact)
        else begin
            Control.AssertPrepared(Fact);
            if Control.LedgerStatus(Fact, Posted, Missing) <> 0 then
                Error('SI Process: знайдено проведені записи; автоматичне повторення заборонено.');
        end;
        Posting.Post(Fact);
    end;
}
