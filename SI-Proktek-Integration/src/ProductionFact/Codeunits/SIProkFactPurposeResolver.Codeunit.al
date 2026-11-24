codeunit 57241 "SI Prok Fact Purpose Resolver"
{
    // Historical revision is the sole business classification source. Never use recete_kod.
    procedure Resolve(var Fact: Record "SI Prok Production Fact"): Boolean
    var
        Revision: Record "SI Concrete Recipe Revision";
        Recipe: Record "SI Concrete Recipe";
        Mapping: Record "SI Prok Entity Mapping";
    begin
        Fact."Fact Purpose" := Fact."Fact Purpose"::Unresolved;
        Clear(Fact."Purpose Diagnostics");
        if (Fact."Recipe No." = '') or (Fact."Recipe Revision No." = 0) then
            exit(Reject(Fact, 'Історичну редакцію рецептури не визначено.'));
        if not Revision.Get(Fact."Recipe No.", Fact."Recipe Revision No.") then
            exit(Reject(Fact, 'Історичну редакцію рецептури не знайдено.'));
        if not Recipe.Get(Revision."Recipe No.") then
            exit(Reject(Fact, 'Кореневу рецептуру не знайдено.'));
        if (Recipe."Production BOM No." = '') or (Revision."Production BOM Version Code" = '') then
            exit(Reject(Fact, 'У редакції немає нормативної BOM Version.'));
        if (Fact."Production BOM No." <> '') and
           (Fact."Production BOM No." <> Recipe."Production BOM No.") then
            exit(Reject(Fact, 'Конфлікт номера BOM між фактом та історичною редакцією.'));
        if (Fact."Production BOM Version Code" <> '') and
           (Fact."Production BOM Version Code" <> Revision."Production BOM Version Code") then
            exit(Reject(Fact, 'Конфлікт BOM Version між фактом та історичною редакцією.'));
        if (Fact."Formula ERP Code" <> '') and
           (Fact."Formula ERP Code" <> StrSubstNo('%1|%2', Recipe."Production BOM No.", Revision."Production BOM Version Code")) then
            exit(Reject(Fact, 'ERP Code факту не відповідає історичній BOM Version.'));
        if not IsNullGuid(Fact."Formula UUID") and (Fact."Connection Code" <> '') then begin
            Mapping.SetRange("Connection Code", Fact."Connection Code");
            Mapping.SetRange("Entity Type", Mapping."Entity Type"::Formula);
            Mapping.SetRange("Proktek UUID", Fact."Formula UUID");
            if Mapping.Count() <> 1 then
                exit(Reject(Fact, 'Formula UUID не має однозначного mapping.'));
            Mapping.FindFirst();
            if Mapping."BC SystemId" <> Revision.SystemId then
                exit(Reject(Fact, 'Formula UUID mapping суперечить історичній редакції.'));
        end;
        case Revision."Recipe Purpose" of
            Revision."Recipe Purpose"::Commercial:
                Fact."Fact Purpose" := Fact."Fact Purpose"::Commercial;
            Revision."Recipe Purpose"::Technological:
                Fact."Fact Purpose" := Fact."Fact Purpose"::Technological;
            else
                exit(Reject(Fact, 'Непідтримуване призначення редакції.'));
        end;
        Fact.Modify(true);
        exit(true);
    end;

    local procedure Reject(var Fact: Record "SI Prok Production Fact"; Reason: Text): Boolean
    begin
        Fact."Purpose Diagnostics" := CopyStr(Reason, 1, MaxStrLen(Fact."Purpose Diagnostics"));
        Fact.Modify(true);
        exit(false);
    end;
}
