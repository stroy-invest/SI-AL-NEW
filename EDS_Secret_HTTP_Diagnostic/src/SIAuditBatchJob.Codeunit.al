codeunit 70055 "SI Audit Batch Job"
{
    TableNo = "Job Queue Entry";
    // Set Job Queue Entry Parameter String to the audit batch number (e.g. AUDIT-001).
    trigger OnRun()
    var
        Worker: Codeunit "SI Audit Batch Worker";
        BatchNo: Code[20];
    begin
        BatchNo := CopyStr(Rec."Parameter String", 1, MaxStrLen(BatchNo));
        if BatchNo = '' then
            Error('У Job Queue Entry Parameter String вкажіть номер пакета (наприклад AUDIT-001).');
        Worker.RunSlice(BatchNo);
    end;
}
