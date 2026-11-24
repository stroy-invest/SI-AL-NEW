codeunit 60040 "SI Internal Operation Seed"
{
    Permissions = tabledata "SI Internal Operation" = RI,
                  tabledata "SI Internal Operation Purpose" = R;
    procedure Initialize()
    var
        Setup: Record "SI Internal Operation Purpose";
    begin
        if Setup.FindSet() then
            repeat
                EnsureOperation(Setup.Code, Setup.Description);
            until Setup.Next() = 0;
        EnsureOperation('NO-ORDER-PROD', 'Виробництво без замовлення');
        EnsureOperation('INTERNAL-TRANSFER', 'Внутрішнє переміщення');
        EnsureOperation('LAB-PRODUCTION', 'Лабораторне виробництво');
        EnsureOperation('TEST-PRODUCTION', 'Тестове виробництво');
        EnsureOperation('INTERNAL-CONSUMPTION', 'Внутрішнє споживання');
    end;
    local procedure EnsureOperation(OperationCode: Code[30]; OperationDescription: Text[100])
    var
        Operation: Record "SI Internal Operation";
    begin
        if Operation.Get(OperationCode) then
            exit;
        Operation.Init();
        Operation.Code := OperationCode;
        Operation.Description := OperationDescription;
        Operation.Insert(true);
    end;
}
