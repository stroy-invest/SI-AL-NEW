codeunit 53042 "SI Parameter Value Resolver"
{
    procedure TryResolve(ParameterCode: Code[30]; ValueCode: Code[30]; var DisplayValue: Text; var HasNumericValue: Boolean; var NumericValue: Decimal; var NumericUoMCode: Code[10]; var SemanticCode: Code[50]): Boolean
    var
        P: Record "SI Product Parameter";
        V: Record "SI Parameter Value";
        M: Record "SI Nominal Size Mapping";
        Source: Codeunit "SI Dynamic Value Source";
    begin
        Clear(DisplayValue);
        Clear(HasNumericValue);
        Clear(NumericValue);
        Clear(NumericUoMCode);
        Clear(SemanticCode);
        if ValueCode = '' then exit(false);
        if not P.Get(ParameterCode) then exit(false);
        if P.Blocked or (P."Value Type" <> P."Value Type"::"Controlled Value") then exit(false);
        case P."Value Source" of
            P."Value Source"::Static:
                begin
                    if not V.Get(ParameterCode, ValueCode) then exit(false);
                    if V.Blocked then exit(false);
                    DisplayValue := V."Display Value";
                    if DisplayValue = '' then DisplayValue := V.Code;
                    NumericValue := V."Numeric Value";
                    NumericUoMCode := V."Numeric UoM Code";
                    if NumericUoMCode = '' then NumericUoMCode := P."Unit of Measure Code";
                    // Legacy numeric values have no explicit presence flag.
                    HasNumericValue := (NumericUoMCode <> '') or (NumericValue <> 0);
                end;
            P."Value Source"::NominalSize:
                begin
                    if not Source.TryGetMapping(ParameterCode, ValueCode, M) then exit(false);
                    DisplayValue := P."Value Prefix" + ValueCode + P."Value Suffix";
                    if P."Nominal Value Field" = P."Nominal Value Field"::DN then begin
                        HasNumericValue := true;
                        NumericValue := M.DN;
                        NumericUoMCode := P."Unit of Measure Code";
                    end;
                end;
        end;
        SemanticCode := P."SI Semantic Code";
        exit(true);
    end;

    procedure ValidateCode(ParameterCode: Code[30]; ValueCode: Code[30]): Text
    var
        DisplayValue: Text;
        HasNumericValue: Boolean;
        NumericValue: Decimal;
        NumericUoMCode: Code[10];
        SemanticCode: Code[50];
    begin
        if not TryResolve(ParameterCode, ValueCode, DisplayValue, HasNumericValue, NumericValue, NumericUoMCode, SemanticCode) then
            Error('Значення %1 недоступне для параметра %2.', ValueCode, ParameterCode);
        exit(DisplayValue);
    end;

    procedure GetAttributes(ParameterCode: Code[30]; ValueCode: Code[30]; var Attr: Record "SI Parameter Value Attr."): Boolean
    var
        P: Record "SI Product Parameter";
        Resolver: Codeunit "SI Value Attr. Resolver";
    begin
        Attr.Reset();
        if not P.Get(ParameterCode) then exit(false);
        if P."Value Source" <> P."Value Source"::Static then exit(false);
        exit(Resolver.GetAttributes(ParameterCode, ValueCode, Attr));
    end;
}
