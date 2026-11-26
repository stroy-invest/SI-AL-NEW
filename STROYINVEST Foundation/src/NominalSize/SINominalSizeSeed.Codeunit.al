codeunit 50521 "SI Nominal Size Seed"
{
 procedure SeedPipeMapping()
 var M: Record "SI Nominal Size Mapping";
 begin
 M.LockTable();
 EnsureRow('1/8', 6, 10);
 EnsureRow('1/4', 8, 20);
 EnsureRow('3/8', 10, 30);
 EnsureRow('1/2', 15, 40);
 EnsureRow('3/4', 20, 50);
 EnsureRow('1', 25, 60);
 EnsureRow('1 1/4', 32, 70);
 EnsureRow('1 1/2', 40, 80);
 EnsureRow('2', 50, 90);
 EnsureRow('2 1/2', 65, 100);
 EnsureRow('3', 80, 110);
 EnsureRow('3 1/2', 90, 120);
 EnsureRow('4', 100, 130);
 EnsureRow('5', 125, 140);
 EnsureRow('6', 150, 150);
 EnsureRow('8', 200, 160);
 EnsureRow('10', 250, 170);
 end;
 local procedure EnsureRow(NPSCode: Code[20]; DNValue: Integer; SortOrder: Integer)
 var M: Record "SI Nominal Size Mapping";
 begin
 if M.Get('PIPE-NPS-DN', NPSCode) then exit;
 M.SetRange("Mapping Set Code", 'PIPE-NPS-DN'); M.SetRange(DN, DNValue);
 if not M.IsEmpty() then exit;
 M.Reset(); M.Init(); M."Mapping Set Code" := 'PIPE-NPS-DN'; M."NPS Code" := NPSCode;
 M.DN := DNValue; M.Active := true; M."Sort Order" := SortOrder; M.Insert(true);
 end;
}
