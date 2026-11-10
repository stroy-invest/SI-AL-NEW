codeunit 57117 "SI Prok Prod Order Status Sync"
{
    // PF-02.2A.2: standard-first reconciliation. No guessed prefixes or sequence numbers.
    procedure ResolvePlanOrder(var Plan: Record "SI Prok Production Plan"; var ProdOrder: Record "Production Order"; var Issue: Text): Boolean
    var
        Candidate: Record "Production Order";
        Transition: Record "SI Prok Prod Order Transition";
        CountMatches: Integer;
    begin
        Clear(Issue);
        if Plan."BC Prod. Order No." = '' then begin
            Issue := 'Production Plan не містить номера BC Production Order.';
            exit(false);
        end;
        if ProdOrder.Get(Plan."BC Prod. Order Status", Plan."BC Prod. Order No.") then
            exit(ValidateIdentity(Plan, ProdOrder, Issue));

        // First use exact, append-only transition records captured by BC standard event.
        Transition.SetRange("From Status", Plan."BC Prod. Order Status");
        Transition.SetRange("From Order No.", Plan."BC Prod. Order No.");
        Transition.SetRange("Prod. Request Entry No.", Plan."Prod. Request Entry No.");
        if Transition.FindSet() then
            repeat
                if Candidate.Get(Transition."To Status", Transition."To Order No.") then
                    if ValidateIdentity(Plan, Candidate, Issue) then begin
                        CountMatches += 1;
                        ProdOrder := Candidate;
                    end;
            until Transition.Next() = 0;
        if CountMatches > 1 then begin
            Issue := 'Знайдено кілька актуальних замовлень за історією переходів; автоматична прив’язка заборонена.';
            exit(false);
        end;
        if CountMatches = 1 then begin
            UpdatePlan(Plan, ProdOrder);
            Clear(Issue);
            exit(true);
        end;

        // Recovery of transitions that occurred before subscriber installation.
        // Standard BC writes the exact predecessor number to the Released order.
        Clear(Issue);
        if Plan."BC Prod. Order Status" <> Plan."BC Prod. Order Status"::"Firm Planned" then begin
            Issue := 'Не знайдено поточного замовлення або достовірного запису переходу.';
            exit(false);
        end;
        Candidate.Reset();
        Candidate.SetRange(Status, Candidate.Status::Released);
        Candidate.SetRange("Firm Planned Order No.", Plan."BC Prod. Order No.");
        if Candidate.FindSet() then
            repeat
                if ValidateIdentity(Plan, Candidate, Issue) then begin
                    CountMatches += 1;
                    ProdOrder := Candidate;
                end;
            until Candidate.Next() = 0;
        if CountMatches <> 1 then begin
            Issue := StrSubstNo('За стандартним Firm Planned Order No. = %1 знайдено %2 відповідних Released замовлень; автоматичне відновлення заборонено.', Plan."BC Prod. Order No.", CountMatches);
            exit(false);
        end;
        RegisterTransition(Plan."Prod. Request Entry No.", Plan."BC Prod. Order Status", Plan."BC Prod. Order No.", ProdOrder.Status, ProdOrder."No.", true);
        UpdatePlan(Plan, ProdOrder);
        Clear(Issue);
        exit(true);
    end;

    procedure RegisterTransition(RequestEntryNo: Integer; FromStatus: Enum "Production Order Status"; FromNo: Code[20]; ToStatus: Enum "Production Order Status"; ToNo: Code[20]; Recovered: Boolean)
    var
        Transition: Record "SI Prok Prod Order Transition";
    begin
        Transition.SetRange("Prod. Request Entry No.", RequestEntryNo);
        Transition.SetRange("From Status", FromStatus);
        Transition.SetRange("From Order No.", FromNo);
        Transition.SetRange("To Status", ToStatus);
        Transition.SetRange("To Order No.", ToNo);
        if not Transition.IsEmpty() then
            exit;
        Transition.Init();
        Transition."Prod. Request Entry No." := RequestEntryNo;
        Transition."From Status" := FromStatus;
        Transition."From Order No." := FromNo;
        Transition."To Status" := ToStatus;
        Transition."To Order No." := ToNo;
        Transition.Recovered := Recovered;
        Transition."Recorded At" := CurrentDateTime();
        Transition.Insert(true);
    end;

    procedure UpdatePlan(var Plan: Record "SI Prok Production Plan"; Order: Record "Production Order")
    begin
        if (Plan."BC Prod. Order Status" = Order.Status) and (Plan."BC Prod. Order No." = Order."No.") then
            exit;
        Plan."BC Prod. Order Status" := Order.Status;
        Plan."BC Prod. Order No." := Order."No.";
        Plan.Modify(false);
    end;

    procedure ValidateIdentity(Plan: Record "SI Prok Production Plan"; ProdOrder: Record "Production Order"; var Issue: Text): Boolean
    var
        Line: Record "Prod. Order Line";
    begin
        Line.SetRange(Status, ProdOrder.Status);
        Line.SetRange("Prod. Order No.", ProdOrder."No.");
        if Line.Count() <> 1 then begin
            Issue := 'Пов’язане BC Production Order повинно містити рівно один виробничий рядок.';
            exit(false);
        end;
        Line.FindFirst();
        if (Line."Item No." <> Plan."Item No.") or
           (Line."Variant Code" <> Plan."Variant Code") or
           (Line."Unit of Measure Code" <> Plan."Unit of Measure Code") or
           (Line.Quantity <> Plan."Planned Quantity") then begin
            Issue := 'Ідентичність BC Production Order не підтверджена: товар, варіант, ОВ або кількість відрізняються від Production Plan.';
            exit(false);
        end;
        exit(true);
    end;
}
