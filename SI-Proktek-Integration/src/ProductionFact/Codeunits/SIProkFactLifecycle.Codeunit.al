codeunit 57233 "SI Prok Fact Lifecycle"
{
    // Canonical post-intake pipeline. No journals, printing, inventory or G/L.
    procedure AfterImported(FactEntryNo: Integer)
    begin
        RouteFact(FactEntryNo, true);
    end;

    procedure AfterExisting(FactEntryNo: Integer)
    begin
        RouteFact(FactEntryNo, false);
    end;

    local procedure RouteFact(FactEntryNo: Integer; IsNew: Boolean)
    var
        Fact: Record "SI Prok Production Fact";
        Revision: Record "SI Concrete Recipe Revision";
        Binding: Codeunit "SI Prok Fact BC Binding Mgt.";
        ShipmentMgt: Codeunit "SI Prok Shipment Mgt.";
        Completion: Codeunit "SI Prok Plan Completion Mgt.";
        InternalResolver: Codeunit "SI Prok Internal Cust Resolver";
        CustomerNo: Code[20];
    begin
        Fact.Get(FactEntryNo);
        if not Revision.Get(Fact."Recipe No.", Fact."Recipe Revision No.") then
            exit; // No historical revision: preserve fact, do not create documents.
        case Revision."Recipe Purpose" of
            Revision."Recipe Purpose"::Technological:
                begin
                    CustomerNo := InternalResolver.ResolveTechnological();
                    AssignInternalCustomer(Fact, CustomerNo);
                    exit; // No Production Order binding or Shipment.
                end;
            Revision."Recipe Purpose"::Commercial:
                begin
                    // Only an explicitly absent Proktek order is treated as no-order production.
                    // A present but unmatched Order UUID must follow the existing Binding diagnostics.
                    if IsNullGuid(Fact."Order UUID") and (Fact."Order ID" = 0) and
                       (Fact."Prod. Request Entry No." = 0) and
                       (Fact."BC Prod. Order No." = '') and
                       (Fact."BC Bound At" = 0DT) then begin
                        CustomerNo := InternalResolver.ResolveNoOrder();
                        AssignInternalCustomer(Fact, CustomerNo);
                        exit; // No fabricated Production Order or Shipment.
                    end;
                    // This field is reserved for Internal Operations (TECH-RECIPE / NO-ORDER-PROD),
                    // not for Internal Project Customers resolved by the existing BC Binding.
                    if Fact."Internal Customer No." <> '' then
                        Error('Факт %1 має Operations Customer %2, але містить контекст замовлення. Потрібна ручна перевірка.',
                            Fact."Entry No.", Fact."Internal Customer No.");
                    Binding.BindFact(Fact);
                    ShipmentMgt.EnsureForFact(FactEntryNo);
                    Completion.UpdateForFact(FactEntryNo);
                end;
        end;
    end;

    local procedure AssignInternalCustomer(var Fact: Record "SI Prok Production Fact"; CustomerNo: Code[20])
    begin
        // Preserve the original association on replay; do not silently remap history.
        if Fact."Internal Customer No." <> '' then begin
            ValidateOperationsCustomer(Fact."Internal Customer No.");
            if Fact."Internal Customer No." <> CustomerNo then
                Error('Факт %1 вже пов’язаний із внутрішнім Customer %2. Поточне налаштування повертає %3.',
                    Fact."Entry No.", Fact."Internal Customer No.", CustomerNo);
            exit;
        end;
        // Guard the meaning of field 341: it must never hold an Internal Project Customer.
        ValidateOperationsCustomer(CustomerNo);
        Fact."Internal Customer No." := CustomerNo;
        Fact.Modify(true);
    end;

    local procedure ValidateOperationsCustomer(CustomerNo: Code[20])
    var
        Customer: Record Customer;
    begin
        if not Customer.Get(CustomerNo) then
            Error('Operations Customer %1 не знайдено.', CustomerNo);
        if Customer."SI Customer Type" <> Customer."SI Customer Type"::"Internal Operations" then
            Error('Customer %1 не має типу Internal Operations.', CustomerNo);
    end;
}
