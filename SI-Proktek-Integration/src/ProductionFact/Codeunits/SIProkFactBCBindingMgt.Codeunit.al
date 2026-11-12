codeunit 57106 "SI Prok Fact BC Binding Mgt."
{
    // PF-02.1. No Proktek HTTP, no journals, no posting.
    procedure BindFact(var Fact: Record "SI Prok Production Fact")
    var
        Req: Record "SI Concrete Prod Request";
        Plan: Record "SI Prok Production Plan";
        Order: Record "Production Order";
        StatusSync: Codeunit "SI Prok Prod Order Status Sync";
        ProdLine: Record "Prod. Order Line";
        OtherLine: Record "Prod. Order Line";
        OtherFact: Record "SI Prok Production Fact";
        Issue: Text;
        Total: Decimal;
        WarningText: Text;
    begin
        Fact.Get(Fact."Entry No.");
        if IsNullGuid(Fact."Production UUID") then begin
            Block(Fact, 'Production UUID порожній.');
            exit;
        end;
        if not ResolveProductionRequest(Fact, Req, Issue) then begin
            Block(Fact, Issue);
            exit;
        end;
        if IsNullGuid(Fact."Order UUID") or
           (Fact."Order UUID" <> Req."Proktek Order UUID") then begin
            Block(Fact, 'Proktek Order UUID факту не відповідає виробничій заявці.');
            exit;
        end;
        if (Fact."Order ID" <> 0) and (Req."Proktek Order ID" <> 0) and
           (Fact."Order ID" <> Req."Proktek Order ID") then begin
            Block(Fact, 'Proktek Order ID факту не відповідає виробничій заявці.');
            exit;
        end;
        if not Plan.Get(Req."Entry No.") then begin
            Block(Fact, 'Нормативний SI Production Plan не знайдено.');
            exit;
        end;
        if Plan."BC Prod. Order No." = '' then begin
            Block(Fact, 'Production Plan не пов’язаний із замовленням BC.');
            exit;
        end;
        if not StatusSync.ResolvePlanOrder(Plan, Order, Issue) then begin
            Block(Fact, Issue);
            exit;
        end;
        if (Fact."BC Prod. Order No." <> '') and
           (Fact."BC Prod. Order No." <> Order."No.") then begin
            // A renumbered BC order is accepted only if the standard predecessor field
            // or our exact transition history proves the link.
            if not IsVerifiedTransition(Fact, Order) then begin
                Block(Fact, 'Номер BC Production Order змінився без підтвердженого стандартного переходу.');
                exit;
            end;
        end;
        if (Fact."BC Prod. Order No." <> '') and
           (Fact."BC Prod. Order Status" <> Order.Status) and
           not IsVerifiedTransition(Fact, Order) then begin
            Block(Fact, 'Неочікувана зміна статусу BC Production Order. Автоматична заміна заборонена.');
            exit;
        end;
        if not (Order.Status in [Order.Status::"Firm Planned", Order.Status::Released]) then begin
            Block(Fact, 'Статус виробничого замовлення BC не допускається для PF-02.');
            exit;
        end;
        ProdLine.SetRange(Status, Order.Status);
        ProdLine.SetRange("Prod. Order No.", Order."No.");
        if not ProdLine.FindFirst() then begin
            Block(Fact, 'У виробничому замовленні BC немає рядків.');
            exit;
        end;
        OtherLine.CopyFilters(ProdLine);
        if OtherLine.Count() <> 1 then begin
            Block(Fact, 'Виробниче замовлення BC повинно містити рівно один рядок.');
            exit;
        end;
        if (Fact."BC Prod. Order Line No." <> 0) and
           (Fact."BC Prod. Order Line No." <> ProdLine."Line No.") then begin
            Block(Fact, 'Збережений номер рядка BC відрізняється. Автоматична заміна заборонена.');
            exit;
        end;
        if (ProdLine."Item No." <> Plan."Item No.") or
           (ProdLine."Variant Code" <> Plan."Variant Code") then begin
            Block(Fact, 'Товар або варіант рядка BC не відповідає нормативному плану.');
            exit;
        end;
        if (Fact."Item No." <> Plan."Item No.") or
           (Fact."Variant Code" <> Plan."Variant Code") then begin
            Block(Fact, 'Товар або варіант факту не відповідає нормативному плану.');
            exit;
        end;
        if ProdLine."Unit of Measure Code" <> Plan."Unit of Measure Code" then begin
            Block(Fact, 'Одиниця виміру виробничого рядка не відповідає плану.');
            exit;
        end;
        if Fact."Produced Quantity M3" <= 0 then begin
            Block(Fact, 'Фактичний випуск повинен бути більшим за нуль.');
            exit;
        end;
        if Fact."Verification Status" <> Fact."Verification Status"::Verified then
            AppendWarning(WarningText, 'Обсяг факту не підтверджено.');
        if Fact."Technical Validation" <> Fact."Technical Validation"::Complete then
            AppendWarning(WarningText, 'Технічна перевірка потребує уваги.');
        Total := Fact.GetConfirmedOrderTotal();
        if Total > Plan."Planned Quantity" then
            AppendWarning(WarningText, StrSubstNo('Підтверджено %1 м³ при плані %2 м³.', Total, Plan."Planned Quantity"));
        Fact."BC Prod. Order Status" := Order.Status;
        Fact."BC Prod. Order No." := Order."No.";
        Fact."BC Prod. Order Line No." := ProdLine."Line No.";
        if Fact."BC Bound At" = 0DT then
            Fact."BC Bound At" := CurrentDateTime();
        if WarningText <> '' then begin
            Fact."BC Binding Status" := Fact."BC Binding Status"::Warning;
            Fact."BC Binding Diagnostics" := CopyStr(WarningText, 1, MaxStrLen(Fact."BC Binding Diagnostics"));
        end else begin
            Fact."BC Binding Status" := Fact."BC Binding Status"::Bound;
            Clear(Fact."BC Binding Diagnostics");
        end;
        Fact.Modify(true);
    end;

    local procedure IsVerifiedTransition(Fact: Record "SI Prok Production Fact"; Order: Record "Production Order"): Boolean
    var
        Transition: Record "SI Prok Prod Order Transition";
    begin
        if (Fact."BC Prod. Order Status" = Fact."BC Prod. Order Status"::"Firm Planned") and
           (Order.Status = Order.Status::Released) and
           (Order."Firm Planned Order No." = Fact."BC Prod. Order No.") then
            exit(true);
        Transition.SetRange("Prod. Request Entry No.", Fact."Prod. Request Entry No.");
        Transition.SetRange("From Status", Fact."BC Prod. Order Status");
        Transition.SetRange("From Order No.", Fact."BC Prod. Order No.");
        Transition.SetRange("To Status", Order.Status);
        Transition.SetRange("To Order No.", Order."No.");
        exit(not Transition.IsEmpty());
    end;

    procedure RevalidateBinding(var Fact: Record "SI Prok Production Fact")
    begin
        BindFact(Fact);
    end;

    procedure AssertBoundForPosting(Fact: Record "SI Prok Production Fact")
    var
        CurrentFact: Record "SI Prok Production Fact";
    begin
        CurrentFact.Get(Fact."Entry No.");
        if CurrentFact."BC Binding Status" <> CurrentFact."BC Binding Status"::Bound then
            Error('Факт %1 не готовий: BC Binding Status = %2. %3',
                CurrentFact."Production UUID", CurrentFact."BC Binding Status", CurrentFact."BC Binding Diagnostics");
        CurrentFact.AssertAllowedForPosting();
    end;

    local procedure ResolveProductionRequest(
        var Fact: Record "SI Prok Production Fact";
        var Req: Record "SI Concrete Prod Request";
        var Issue: Text): Boolean
    var
        Candidate: Record "SI Concrete Prod Request";
    begin
        if IsNullGuid(Fact."Order UUID") then begin
            Issue := 'Proktek Order UUID факту порожній.';
            exit(false);
        end;

        // Never replace an existing explicit link with a different request.
        if Fact."Prod. Request Entry No." <> 0 then begin
            if not Req.Get(Fact."Prod. Request Entry No.") then begin
                Issue := 'Збережену виробничу заявку не знайдено. Автоматична заміна заборонена.';
                exit(false);
            end;
            if Req."Proktek Order UUID" <> Fact."Order UUID" then begin
                Issue := 'Збережена виробнича заявка має інший Proktek Order UUID.';
                exit(false);
            end;
            exit(true);
        end;

        Candidate.SetRange("Proktek Order UUID", Fact."Order UUID");
        if not Candidate.FindFirst() then begin
            Issue := 'Виробничу заявку за Proktek Order UUID не знайдено.';
            exit(false);
        end;
        Req := Candidate;
        if Candidate.Next() <> 0 then begin
            Issue := 'Знайдено кілька виробничих заявок з однаковим Proktek Order UUID.';
            exit(false);
        end;

        // Persist only after all identity checks; the caller performs the remaining validation.
        Fact."Prod. Request Entry No." := Req."Entry No.";
        Fact."Supply Decision No." := Req."Supply Decision No.";
        Fact."Supply Decision Line No." := Req."Supply Decision Line No.";
        Fact."Supply Allocation Line No." := Req."Supply Allocation Line No.";
        Fact."Project No." := Req."Project No.";
        exit(true);
    end;

    local procedure Block(var Fact: Record "SI Prok Production Fact"; Reason: Text)
    begin
        Fact."BC Binding Status" := Fact."BC Binding Status"::Blocked;
        Fact."BC Binding Diagnostics" := CopyStr(Reason, 1, MaxStrLen(Fact."BC Binding Diagnostics"));
        Fact.Modify(true);
    end;

    local procedure AppendWarning(var Existing: Text; NewWarning: Text)
    begin
        if Existing <> '' then
            Existing += ' ';
        Existing += NewWarning;
    end;
}
