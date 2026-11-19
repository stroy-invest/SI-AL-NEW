codeunit 57225 "SI Prok PF Link Resolver"
{
    // Read-only identity resolution for the hierarchy and quantitative report.
    // Never infer a verified BC request from a similar-looking Proktek Order No.
    procedure Resolve(Fact: Record "SI Prok Production Fact"; var Request: Record "SI Concrete Prod Request"): Enum "SI Prok PF Link State"
    var
        Candidate: Record "SI Concrete Prod Request";
    begin
        Clear(Request);
        if Fact."Prod. Request Entry No." <> 0 then begin
            if not Request.Get(Fact."Prod. Request Entry No.") then
                exit(Enum::"SI Prok PF Link State"::Broken);
            if not IsNullGuid(Fact."Order UUID") and not IsNullGuid(Request."Proktek Order UUID") and
                (Fact."Order UUID" <> Request."Proktek Order UUID") then
                exit(Enum::"SI Prok PF Link State"::Broken);
            exit(Enum::"SI Prok PF Link State"::Linked);
        end;

        if not IsNullGuid(Fact."Order UUID") then begin
            Candidate.SetRange("Proktek Order UUID", Fact."Order UUID");
            if Candidate.FindFirst() then begin
                Request := Candidate;
                if Candidate.Next() <> 0 then begin
                    Clear(Request);
                    exit(Enum::"SI Prok PF Link State"::Broken);
                end;
                exit(Enum::"SI Prok PF Link State"::Linked);
            end;
        end;

        // Business-facing "Без замовлення" is defined by absent Order No.
        // Proktek may still supply an internal Order ID/UUID for a manual fact.
        // A unique verified UUID-to-BC match was already checked above.
        if (Fact."Order No." = '') or (UpperCase(DelChr(Fact."Order No.", '<>')) = 'БЕЗ ЗАМОВЛЕННЯ') then
            exit(Enum::"SI Prok PF Link State"::WithoutOrder);
        exit(Enum::"SI Prok PF Link State"::Unmatched);
    end;

    procedure MatchesRequest(Fact: Record "SI Prok Production Fact"; RequestEntryNo: Integer): Boolean
    var
        Resolved: Record "SI Concrete Prod Request";
    begin
        exit((Resolve(Fact, Resolved) = Enum::"SI Prok PF Link State"::Linked) and
            (Resolved."Entry No." = RequestEntryNo));
    end;

    local procedure IsNullGuid(Value: Guid): Boolean
    begin
        exit(Value = '00000000-0000-0000-0000-000000000000');
    end;
}
