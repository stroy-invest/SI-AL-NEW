codeunit 57990 "SI Prok Concrete M3 UoM"
{
    // Sandbox uses Latin M3; Production may use Cyrillic М3.
    // Resolve the actual Item UoM code; do not substitute a non-existent code.
    procedure TryResolve(ItemNo: Code[20]; var UoMCode: Code[10]): Boolean
    var
        ItemUoM: Record "Item Unit of Measure";
    begin
        Clear(UoMCode);
        if ItemUoM.Get(ItemNo, 'M3') then
            if ItemUoM."Qty. per Unit of Measure" > 0 then begin
                UoMCode := ItemUoM.Code;
                exit(true);
            end;
        if ItemUoM.Get(ItemNo, 'М3') then
            if ItemUoM."Qty. per Unit of Measure" > 0 then begin
                UoMCode := ItemUoM.Code;
                exit(true);
            end;
        exit(false);
    end;

    procedure Resolve(ItemNo: Code[20]): Code[10]
    var
        UoMCode: Code[10];
    begin
        if not TryResolve(ItemNo, UoMCode) then
            Error('Для товару %1 немає одиниці M3 або М3 з додатним коефіцієнтом.', ItemNo);
        exit(UoMCode);
    end;
}
