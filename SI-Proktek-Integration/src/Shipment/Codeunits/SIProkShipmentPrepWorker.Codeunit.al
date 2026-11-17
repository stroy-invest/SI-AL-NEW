codeunit 57150 "SI Prok Shipment Prep Worker"
{
    TableNo = "SI Prok Shipment";

    trigger OnRun()
    var
        Fact: Record "SI Prok Production Fact";
        Attempt: Record "SI Prok Posting Attempt";
        Prep: Codeunit "SI Prok Process Journal Prep";
        Control: Codeunit "SI Prok Process Control";
    begin
        Rec.Get(Rec."Entry No.");
        if Rec.Status <> Rec.Status::Closed then
            Error('SI Process: відвантаження не зафіксовано.');
        Fact.Get(Rec."Production Fact Entry No.");
        if Fact."Production UUID" <> Rec."Production UUID" then
            Error('SI Process: UUID Shipment і факту не збігаються.');
        if Attempt.Get(Fact."Production UUID") then
            Error('SI Process: для факту вже є спроба проведення (%1).', Attempt.Status);
        if Fact."Accounting Document No." = '' then
            Prep.Prepare(Fact);
        Control.AssertPrepared(Fact);
    end;
}
