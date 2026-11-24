codeunit 50508 "SI Location Resolver"
{
    // Foundation-LC-01: central read-only semantic Location resolution.
    // Role is a configured SI Location Type code, not a physical Location.Code.
    // PreferredLocationCode is an explicit plant/project context supplied by caller.
    procedure TryResolve(LocationTypeCode: Code[20]; SpecializationCode: Code[20]; PreferredLocationCode: Code[10]; var ResolvedLocationCode: Code[10]; var Reason: Text): Boolean
    var
        Location: Record Location;
        LocationType: Record "SI Location Type";
        Specialization: Record "SI Location Specialization";
        CandidateCount: Integer;
    begin
        Clear(ResolvedLocationCode);
        Clear(Reason);

        if (LocationTypeCode = '') or not LocationType.Get(LocationTypeCode) or not LocationType.Active then begin
            Reason := StrSubstNo('Тип складу %1 не налаштовано або він неактивний.', LocationTypeCode);
            exit(false);
        end;
        if SpecializationCode <> '' then
            if not Specialization.Get(SpecializationCode) or not Specialization.Active then begin
                Reason := StrSubstNo('Спеціалізація складу %1 не існує або неактивна.', SpecializationCode);
                exit(false);
            end;

        Location.SetRange("SI Location Type Code", LocationTypeCode);
        if PreferredLocationCode <> '' then begin
            if not Location.Get(PreferredLocationCode) then begin
                Reason := StrSubstNo('Склад %1 не знайдено.', PreferredLocationCode);
                exit(false);
            end;
            if Location."SI Location Type Code" <> LocationTypeCode then begin
                Reason := StrSubstNo('Склад %1 не відповідає типу %2.', PreferredLocationCode, LocationTypeCode);
                exit(false);
            end;
            if (SpecializationCode <> '') and (Location."SI Location Spec. Code" <> '') and
               (Location."SI Location Spec. Code" <> SpecializationCode) then begin
                Reason := StrSubstNo('Склад %1 має несумісну спеціалізацію %2.', PreferredLocationCode, Location."SI Location Spec. Code");
                exit(false);
            end;
            ResolvedLocationCode := Location.Code;
            exit(true);
        end;

        CandidateCount := Location.Count();
        if CandidateCount = 0 then begin
            Reason := StrSubstNo('Немає складів типу %1.', LocationTypeCode);
            exit(false);
        end;

        // Approved rule: one eligible FG Location needs no mandatory specialization.
        if CandidateCount = 1 then begin
            Location.FindFirst();
            if (SpecializationCode <> '') and (Location."SI Location Spec. Code" <> '') and
               (Location."SI Location Spec. Code" <> SpecializationCode) then begin
                Reason := StrSubstNo('Єдиний склад %1 має несумісну спеціалізацію.', Location.Code);
                exit(false);
            end;
            ResolvedLocationCode := Location.Code;
            exit(true);
        end;

        if SpecializationCode = '' then begin
            Reason := StrSubstNo('Для типу %1 знайдено %2 складів. Потрібна спеціалізація або контекст заводу.', LocationTypeCode, CandidateCount);
            exit(false);
        end;

        Location.SetRange("SI Location Spec. Code", SpecializationCode);
        CandidateCount := Location.Count();
        if CandidateCount = 1 then begin
            Location.FindFirst();
            ResolvedLocationCode := Location.Code;
            exit(true);
        end;
        if CandidateCount = 0 then
            Reason := StrSubstNo('Немає складів типу %1 зі спеціалізацією %2.', LocationTypeCode, SpecializationCode)
        else
            Reason := StrSubstNo('Знайдено %1 складів типу %2 зі спеціалізацією %3. Потрібен контекст заводу.', CandidateCount, LocationTypeCode, SpecializationCode);
        exit(false);
    end;

    procedure AssertResolve(LocationTypeCode: Code[20]; SpecializationCode: Code[20]; PreferredLocationCode: Code[10]): Code[10]
    var
        ResolvedLocationCode: Code[10];
        Reason: Text;
    begin
        if not TryResolve(LocationTypeCode, SpecializationCode, PreferredLocationCode, ResolvedLocationCode, Reason) then
            Error('%1', Reason);
        exit(ResolvedLocationCode);
    end;

    procedure TryResolveFinishedGoods(SpecializationCode: Code[20]; PreferredLocationCode: Code[10]; var ResolvedLocationCode: Code[10]; var Reason: Text): Boolean
    var
        Setup: Record "SI Location Setup";
    begin
        if not Setup.Get() then begin
            Reason := 'Не знайдено налаштування типів складів.';
            Clear(ResolvedLocationCode);
            exit(false);
        end;
        exit(TryResolve(Setup."Finished Goods Type", SpecializationCode, PreferredLocationCode, ResolvedLocationCode, Reason));
    end;
}
