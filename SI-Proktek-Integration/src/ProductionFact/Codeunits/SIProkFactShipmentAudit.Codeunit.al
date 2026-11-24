codeunit 57234 "SI Prok Fact Shipment Audit"
{
    // Read-only integrity audit. No writes, printing, inventory or accounting.
    procedure RunReadOnly()
    var
        Fact: Record "SI Prok Production Fact";
        Revision: Record "SI Concrete Recipe Revision";
        Shipment: Record "SI Prok Shipment";
        Site: Record "SI Construction Site";
        Guard: Codeunit "SI Prok Concrete Identity";
        Snapshot: Codeunit "SI Prok Shipment Snapshot";
        Reason: Text;
        Examples: Text;
        FactCount: Integer;
        Expected: Integer;
        Missing: Integer;
        IdentityErrors: Integer;
        SiteIssues: Integer;
        AddressIssues: Integer;
        ClosedIssues: Integer;
        ClosedHasIssue: Boolean;
        NonCommercial: Integer;
        Unresolved: Integer;
    begin
        if Fact.FindSet() then
            repeat
                FactCount += 1;
                if Fact."Produced Quantity M3" > 0 then begin
                    if not Revision.Get(Fact."Recipe No.", Fact."Recipe Revision No.") then
                        Unresolved += 1
                    else
                        if Revision."Recipe Purpose" = Revision."Recipe Purpose"::Technological then
                            NonCommercial += 1;
                    if Revision.Get(Fact."Recipe No.", Fact."Recipe Revision No.") then
                        if Revision."Recipe Purpose" = Revision."Recipe Purpose"::Commercial then begin
                    Expected += 1;
                    if not Guard.IsValidFact(Fact, Reason) then begin
                        IdentityErrors += 1;
                        AppendExample(Examples, Fact."Entry No.", Reason);
                    end;
                    Clear(ClosedHasIssue);
                    Shipment.Reset();
                    Shipment.SetRange("Production UUID", Fact."Production UUID");
                    if not Shipment.FindFirst() then begin
                        Missing += 1;
                        AppendExample(Examples, Fact."Entry No.", 'Відсутній Shipment');
                    end else begin
                        if (Shipment."Production Fact Entry No." <> Fact."Entry No.") or
                           (Shipment."Connection Code" <> Fact."Connection Code") or
                           (Shipment."Prod. Request Entry No." <> Fact."Prod. Request Entry No.") or
                           (Shipment."Quantity M3" <> Fact."Produced Quantity M3") then begin
                            IdentityErrors += 1;
                            AppendExample(Examples, Fact."Entry No.", 'Не збігаються джерело, заявка, профіль або кількість Shipment');
                            ClosedHasIssue := true;
                        end;
                        if Shipment."Prod. Request Entry No." <> 0 then begin
                            if not Snapshot.TryResolveShipmentSite(Shipment, Site, Reason) then begin
                                SiteIssues += 1;
                                AppendExample(Examples, Fact."Entry No.", Reason);
                                ClosedHasIssue := true;
                            end else begin
                                if (Shipment."Delivery Site Code" <> Site."Site Code") or
                                   (Shipment."Delivery Project No." <> Site."Project No.") then begin
                                    SiteIssues += 1;
                                    AppendExample(Examples, Fact."Entry No.", 'Майданчик у Shipment відсутній або відрізняється');
                                    ClosedHasIssue := true;
                                end;
                                if Shipment."Delivery Address" = '' then begin
                                    AddressIssues += 1;
                                    AppendExample(Examples, Fact."Entry No.", 'Адреса доставки порожня');
                                    ClosedHasIssue := true;
                                end;
                            end;
                        end;
                        if ClosedHasIssue and (Shipment.Status = Shipment.Status::Closed) then
                            ClosedIssues += 1;
                    end;
                    end;
                end;
            until Fact.Next() = 0;

        Message(
            'Аудит Proktek (лише читання)\Фактів: %1; із випуском > 0: %2; без Shipment: %3; помилок ідентичності/кількості: %4; проблем майданчика: %5; порожніх адрес: %6; проблем у закритих документах: %7; технологічних без вимоги Shipment: %8; невизначених (потребують окремого розбору): %9.\Приклади:\%10',
            FactCount, Expected, Missing, IdentityErrors, SiteIssues, AddressIssues, ClosedIssues, NonCommercial, Unresolved, Examples);
    end;

    local procedure AppendExample(var Examples: Text; FactEntryNo: Integer; Reason: Text)
    begin
        if StrLen(Examples) > 1200 then
            exit;
        Examples += CopyStr(StrSubstNo('Факт №%1: %2\', FactEntryNo, Reason), 1, 180);
    end;
}
