codeunit 50520 "SI Nominal Size Resolver"
{
 procedure TryResolveDN(SetCode: Code[30]; NPSCode: Code[20]; var DNValue: Integer): Boolean
 var M: Record "SI Nominal Size Mapping";
 begin
 Clear(DNValue);
 if not M.Get(SetCode, NPSCode) then exit(false);
 if not M.Active then exit(false);
 DNValue := M.DN; exit(true);
 end;
 procedure TryResolveNPS(SetCode: Code[30]; DNValue: Integer; var NPSCode: Code[20]): Boolean
 var M: Record "SI Nominal Size Mapping";
 begin
 Clear(NPSCode);
 M.SetRange("Mapping Set Code", SetCode); M.SetRange(DN, DNValue); M.SetRange(Active, true);
 if not M.FindFirst() then exit(false);
 NPSCode := M."NPS Code"; exit(true);
 end;
}
