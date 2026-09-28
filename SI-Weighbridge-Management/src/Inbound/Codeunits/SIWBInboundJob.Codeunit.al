codeunit 59052 "SI WB Inbound Job"
{
    trigger OnRun()
    var
        Processor: Codeunit "SI WB Inbound Processor";
    begin
        Processor.ProcessAllAcceptedEvents(
            DefaultBatchSize());
    end;

    local procedure DefaultBatchSize(): Integer
    begin
        // Phase I baseline.
        //
        // A single Job Queue execution processes up to 100
        // completed weighings. With normal weighbridge load
        // the actual batch will usually contain only a few events.
        exit(100);
    end;
}