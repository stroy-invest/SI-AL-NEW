codeunit 53041 "SI Dynamic Value Source"
{
    procedure IsDynamic(ParameterCode: Code[30]): Boolean
    var P: Record "SI Product Parameter";
    begin
        if not P.Get(ParameterCode) then exit(false);
        exit(P."Value Source" <> P."Value Source"::Static);
    end;

    procedure Lookup(ParameterCode: Code[30]; var ValueCode: Code[30]): Boolean
    var
        P: Record "SI Product Parameter";
        M: Record "SI Nominal Size Mapping";
        V: Record "SI Parameter Value";
        LookupPage: Page "SI Nominal Value Lookup";
        StaticPage: Page "SI Parameter Values";
    begin
        P.Get(ParameterCode);
        if P."Value Source" = P."Value Source"::Static then begin
            V.SetRange("Parameter Code", ParameterCode);
            V.SetRange(Blocked, false);
            StaticPage.SetTableView(V);
            StaticPage.LookupMode(true);
            if StaticPage.RunModal() <> Action::LookupOK then exit(false);
            StaticPage.GetRecord(V);
            ValueCode := V.Code;
            exit(true);
        end;
        P.TestField("Mapping Set Code");
        M.SetRange("Mapping Set Code", P."Mapping Set Code");
        M.SetRange(Active, true);
        LookupPage.SetTableView(M);
        LookupPage.LookupMode(true);
        if LookupPage.RunModal() <> Action::LookupOK then exit(false);
        LookupPage.GetRecord(M);
        if P."Nominal Value Field" = P."Nominal Value Field"::DN then
            ValueCode := CopyStr(Format(M.DN, 0, 9), 1, MaxStrLen(ValueCode))
        else
            ValueCode := M."NPS Code";
        exit(true);
    end;

    procedure TryGetMapping(ParameterCode: Code[30]; ValueCode: Code[30]; var M: Record "SI Nominal Size Mapping"): Boolean
    var
        P: Record "SI Product Parameter";
        DNValue: Integer;
    begin
        M.Reset();
        if not P.Get(ParameterCode) then exit(false);
        if (P."Value Source" <> P."Value Source"::NominalSize) or (P."Mapping Set Code" = '') then exit(false);
        M.SetRange("Mapping Set Code", P."Mapping Set Code");
        M.SetRange(Active, true);
        if P."Nominal Value Field" = P."Nominal Value Field"::DN then begin
            if not Evaluate(DNValue, ValueCode) then exit(false);
            if ValueCode <> Format(DNValue, 0, 9) then exit(false);
            M.SetRange(DN, DNValue);
        end else
            M.SetRange("NPS Code", ValueCode);
        exit(M.FindFirst());
    end;

    procedure ValidateCode(ParameterCode: Code[30]; ValueCode: Code[30]): Text
    var
        P: Record "SI Product Parameter";
        M: Record "SI Nominal Size Mapping";
    begin
        P.Get(ParameterCode);
        P.TestField("Mapping Set Code");
        if not TryGetMapping(ParameterCode, ValueCode, M) then
            Error('Значення %1 недоступне для параметра %2.', ValueCode, ParameterCode);
        exit(P."Value Prefix" + ValueCode + P."Value Suffix");
    end;
}
