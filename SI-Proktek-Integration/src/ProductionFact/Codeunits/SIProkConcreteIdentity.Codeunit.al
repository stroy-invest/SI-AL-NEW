codeunit 57152 "SI Prok Concrete Identity"
{
    // One rule for intake, shipments and accounting: the finished concrete
    // must resolve to a real Inventory Item with a non-empty display name.
    // This never manufactures an Item from the formula description.

    procedure AssertFact(Fact: Record "SI Prok Production Fact")
    var
        Reason: Text;
    begin
        if not IsValidFact(Fact, Reason) then
            Error('Факт Proktek %1 відхилено: бетон не ідентифіковано. %2',
                Fact."Production UUID", Reason);
    end;

    procedure IsValidFact(Fact: Record "SI Prok Production Fact"; var Reason: Text): Boolean
    var
        FinishedItem: Record Item;
        FinishedVariant: Record "Item Variant";
        ItemUoM: Record "Item Unit of Measure";
        ConcreteName: Text;
        M3Code: Code[10];
        M3Resolver: Codeunit "SI Prok Concrete M3 UoM";
    begin
        Clear(Reason);
        if Fact."Item No." = '' then begin
            Reason := 'Не визначено Item No. готового бетону за рецептурою.';
            exit(false);
        end;
        if not FinishedItem.Get(Fact."Item No.") then begin
            Reason := StrSubstNo('Item %1 відсутній у BC.', Fact."Item No.");
            exit(false);
        end;
        if FinishedItem.Type <> FinishedItem.Type::Inventory then begin
            Reason := StrSubstNo('Item %1 не є складським товаром.', Fact."Item No.");
            exit(false);
        end;
        ConcreteName := FinishedItem.Description;
        if Fact."Variant Code" <> '' then begin
            if not FinishedVariant.Get(Fact."Item No.", Fact."Variant Code") then begin
                Reason := StrSubstNo('Варіант %1 товару %2 відсутній у BC.', Fact."Variant Code", Fact."Item No.");
                exit(false);
            end;
            if FinishedVariant.Description <> '' then
                ConcreteName := FinishedVariant.Description;
        end;
        if DelChr(ConcreteName, '=', ' ') = '' then begin
            Reason := StrSubstNo('Item %1 не має назви бетону (Description).', Fact."Item No.");
            exit(false);
        end;
        if not M3Resolver.TryResolve(Fact."Item No.", M3Code) then begin
            Reason := StrSubstNo('Для бетону %1 немає одиниці виміру M3 або М3 з додатним коефіцієнтом.', Fact."Item No.");
            exit(false);
        end;
        exit(true);
    end;

    procedure AssertShipment(Shipment: Record "SI Prok Shipment"; Fact: Record "SI Prok Production Fact")
    begin
        AssertFact(Fact);
        if (Shipment."Item No." <> Fact."Item No.") or
           (Shipment."Variant Code" <> Fact."Variant Code") then
            Error('Shipment %1: Item/Variant відрізняється від виробничого факту %2.',
                Shipment."Entry No.", Fact."Entry No.");
        if DelChr(Shipment."Concrete Description", '=', ' ') = '' then
            Error('Shipment %1: поле «Бетон» порожнє. Відвантаження/облік заблоковано; потрібен розбір реквізитів.',
                Shipment."Entry No.");
    end;

    // Read-only check of historical records. Posted snapshots are not repaired.
    procedure AuditExisting()
    var
        Fact: Record "SI Prok Production Fact";
        Shipment: Record "SI Prok Shipment";
        Attempt: Record "SI Prok Posting Attempt";
        Ledger: Record "Item Ledger Entry";
        Reason: Text;
        Details: Text;
        HasProblem: Boolean;
        BrokenFacts: Integer;
        BlankShipments: Integer;
        PostedWithProblem: Integer;
    begin
        if Fact.FindSet() then
            repeat
                HasProblem := not IsValidFact(Fact, Reason);
                Shipment.Reset();
                Shipment.SetRange("Production UUID", Fact."Production UUID");
                if Shipment.FindFirst() then begin
                    if (Shipment."Item No." <> Fact."Item No.") or
                       (Shipment."Variant Code" <> Fact."Variant Code") or
                       (DelChr(Shipment."Concrete Description", '=', ' ') = '') then begin
                        BlankShipments += 1;
                        HasProblem := true;
                        if Reason = '' then
                            Reason := 'Не збігається Item/Variant або відсутня назва у Shipment.';
                    end;
                end;
                if HasProblem then begin
                    BrokenFacts += 1;
                    if Fact."Accounting Document No." <> '' then begin
                        Ledger.Reset();
                        Ledger.SetRange("Document No.", Fact."Accounting Document No.");
                        if not Ledger.IsEmpty() then
                            PostedWithProblem += 1
                        else
                            if Attempt.Get(Fact."Production UUID") then
                                if Attempt.Status = Attempt.Status::Completed then
                                    PostedWithProblem += 1;
                    end;
                    if StrLen(Details) < 1300 then
                        Details += StrSubstNo('Факт %1: %2\', Fact."Entry No.", Reason);
                end;
            until Fact.Next() = 0;
        Message('Аудит (тільки читання): проблемних фактів/документів: %1; Shipment з порожнім або невідповідним «Бетоном»: %2; із завершеним проведенням: %3.\Приклади:\%4',
            BrokenFacts, BlankShipments, PostedWithProblem, Details);
    end;
}
