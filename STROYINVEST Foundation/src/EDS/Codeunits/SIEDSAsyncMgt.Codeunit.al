codeunit 50466 "SI EDS Async Mgt."
{
    Permissions =
        tabledata "SI EDS Async Request" = RIMD,
        tabledata "SI EDS Async Param" = RIMD;

    procedure Enqueue(
        ServiceCode: Code[50];
        OperationCode: Code[50];
        BusinessKey: Text;
        StartedAt: DateTime;
        var RuntimeParam: Record "SI EDS Runtime Param" temporary): Integer
    var
        AsyncRequest: Record "SI EDS Async Request";
        AsyncParam: Record "SI EDS Async Param";
        LineNo: Integer;
    begin
        AsyncRequest.SetRange("Service Code", ServiceCode);
        AsyncRequest.SetRange("Operation Code", OperationCode);
        AsyncRequest.SetRange("Business Key", CopyStr(BusinessKey, 1, MaxStrLen(AsyncRequest."Business Key")));
        AsyncRequest.SetRange(Status, AsyncRequest.Status::Pending);
        if AsyncRequest.FindFirst() then
            exit(AsyncRequest."Entry No.");

        AsyncRequest.Init();
        AsyncRequest."Service Code" := ServiceCode;
        AsyncRequest."Operation Code" := OperationCode;
        AsyncRequest."Business Key" := CopyStr(BusinessKey, 1, MaxStrLen(AsyncRequest."Business Key"));
        AsyncRequest.Status := AsyncRequest.Status::Pending;
        AsyncRequest."Started At" := StartedAt;
        AsyncRequest."Next Attempt At" := CurrentDateTime + 30000;
        AsyncRequest."Expires At" := StartedAt + 3600000;
        AsyncRequest.Insert(true);

        RuntimeParam.Reset();
        if RuntimeParam.FindSet() then
            repeat
                LineNo += 10000;
                AsyncParam.Init();
                AsyncParam."Request Entry No." := AsyncRequest."Entry No.";
                AsyncParam."Line No." := LineNo;
                AsyncParam.Code := RuntimeParam.Code;
                AsyncParam.Value := RuntimeParam.Value;
                AsyncParam.Insert();
            until RuntimeParam.Next() = 0;

        exit(AsyncRequest."Entry No.");
    end;
}
