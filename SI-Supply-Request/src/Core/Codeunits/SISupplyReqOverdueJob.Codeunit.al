codeunit 61066 "SI Supply Req Overdue Job"
{
    // Configure a Job Queue Entry with Object Type to Run = Codeunit and Object ID = 61066.
    // This job only synchronizes the stored flag and writes transition audit events.
    // It does not perform workflow actions or change request lifecycle statuses.
    trigger OnRun()
    var
        Request: Record "SI Supply Req Header";
        OverdueMgt: Codeunit "SI Supply Req Overdue Mgt";
    begin
        // Use a snapshot of candidate keys; SynchronizeOne locks and reloads each record.
        // Avoid modifying the same record variable while traversing the result set.
        Request.SetFilter(Status, '<>%1&<>%2', Request.Status::Fulfilled, Request.Status::Cancelled);
        Request.SetFilter("Required on Site At", '<>%1', 0DT);
        if Request.FindSet() then
            repeat
                OverdueMgt.SynchronizeOne(Request."No.");
            until Request.Next() = 0;
    end;
}
