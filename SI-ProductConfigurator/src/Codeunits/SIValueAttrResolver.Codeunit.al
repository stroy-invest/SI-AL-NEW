codeunit 53040 "SI Value Attr. Resolver"
{
    procedure GetAttributes(ParameterCode: Code[30]; ValueCode: Code[30]; var Attr: Record "SI Parameter Value Attr."): Boolean
    var
        Parent: Record "SI Parameter Value";
        Param: Record "SI Product Parameter";
    begin
        Attr.Reset();
        Attr.SetRange("Parameter Code", ParameterCode);
        Attr.SetRange("Value Code", ValueCode);
        if not Param.Get(ParameterCode) then
            exit(false);
        if Param.Blocked then
            exit(false);
        if not Parent.Get(ParameterCode, ValueCode) then
            exit(false);
        if Parent.Blocked then
            exit(false);
        exit(Attr.FindSet());
    end;

    procedure FormatAttribute(Attr: Record "SI Parameter Value Attr."; AttrType: Enum "SI Value Attr. Type"): Text
    begin
        case AttrType of
            AttrType::Decimal:
                exit(Format(Attr."Decimal Value"));
            AttrType::Integer:
                exit(Format(Attr."Integer Value"));
            AttrType::Text:
                exit(Attr."Text Value");
            AttrType::Boolean:
                if Attr."Boolean Value" then
                    exit('Так')
                else
                    exit('Ні');
            AttrType::Range:
                begin
                    if Attr."Has Minimum" and Attr."Has Maximum" then
                        exit(Format(Attr.Minimum) + '–' + Format(Attr.Maximum));
                    if Attr."Has Minimum" then
                        exit('≥' + Format(Attr.Minimum));
                    if Attr."Has Maximum" then
                        exit('≤' + Format(Attr.Maximum));
                end;
        end;
        exit('');
    end;
}
