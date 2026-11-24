codeunit 53093 "SI V3 Parameter Subscriber"
{
    [EventSubscriber(ObjectType::Page, Page::"SI Item Hierarchy V3 Test", 'OnCollectParameterSections', '', false, false)]
    local procedure CollectParameters(NodeType: Text; ItemNo: Code[20]; VariantCode: Code[10]; var Sections: JsonArray)
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ItemConfigNo: Code[20];
        VariantConfigNo: Code[20];
    begin
        if (NodeType <> 'Item') and (NodeType <> 'Variant') then
            exit;
        if not Item.Get(ItemNo) then
            exit;
        Item.CalcFields("SI Configuration No.");
        ItemConfigNo := Item."SI Configuration No.";
        AppendSection('ITEM', 'Параметри товару', ItemConfigNo, true, Sections);
        if NodeType = 'Variant' then begin
            if ItemVariant.Get(ItemNo, VariantCode) then begin
                ItemVariant.CalcFields("SI Configuration No.");
                VariantConfigNo := ItemVariant."SI Configuration No.";
            end;
            AppendSection('VARIANT', 'Параметри варіанта', VariantConfigNo, false, Sections);
        end;
    end;

    local procedure AppendSection(SectionCode: Text; SectionCaption: Text; ConfigurationNo: Code[20]; IsItem: Boolean; var Sections: JsonArray)
    var
        ConfigValue: Record "SI Product Config. Value";
        Parameter: Record "SI Product Parameter";
        ParameterValue: Record "SI Parameter Value";
        FamilyParameter: Record "SI Family Parameter";
        ProductConfig: Record "SI Product Config.";
        Section: JsonObject;
        Rows: JsonArray;
        Row: JsonObject;
        ParameterCaption: Text;
        UnitCode: Code[10];
        IncludeValue: Boolean;
    begin
        Section.Add('code', SectionCode);
        Section.Add('caption', SectionCaption);
        if ConfigurationNo <> '' then begin
            ConfigValue.SetRange("Configuration No.", ConfigurationNo);
            ConfigValue.SetCurrentKey("Configuration No.", "Parameter Order", "Parameter Code");
            if ConfigValue.FindSet() then
                repeat
                    IncludeValue := true;
                    // Match the existing Semantic Parameters FactBoxes role filters.
                    // The role is defined at family-parameter level, not on the value.
                    if ProductConfig.Get(ConfigurationNo) then begin
                        FamilyParameter.Reset();
                        FamilyParameter.SetRange("Family Code", ProductConfig."Family Code");
                        FamilyParameter.SetRange("Parameter Code", ConfigValue."Parameter Code");
                        if FamilyParameter.FindFirst() then
                            if IsItem then
                                IncludeValue := FamilyParameter."ERP Projection Role" <> FamilyParameter."ERP Projection Role"::"Variant Identity"
                            else
                                IncludeValue := FamilyParameter."ERP Projection Role" <> FamilyParameter."ERP Projection Role"::"Item Identity";
                    end;
                    if IncludeValue and (ConfigValue."Value Type" = ConfigValue."Value Type"::"Controlled Value") then
                        if ParameterValue.Get(ConfigValue."Parameter Code", ConfigValue."Parameter Value Code") then
                            IncludeValue := not ParameterValue.Blocked;
                    if IncludeValue then begin
                        ParameterCaption := ConfigValue."Parameter Code";
                        UnitCode := '';
                        if Parameter.Get(ConfigValue."Parameter Code") then begin
                            if Parameter.Description <> '' then
                                ParameterCaption := Parameter.Description;
                            UnitCode := Parameter."Unit of Measure Code";
                        end;
                        Clear(Row);
                        Row.Add('code', ConfigValue."Parameter Code");
                        Row.Add('caption', ParameterCaption);
                        Row.Add('displayValue', ConfigValue."Display Value");
                        Row.Add('unit', UnitCode);
                        Row.Add('source', SectionCode);
                        Rows.Add(Row);
                        if ConfigValue."Value Type" = ConfigValue."Value Type"::"Controlled Value" then
                            AppendAttributes(ConfigValue."Parameter Code", ConfigValue."Parameter Value Code", SectionCode, Rows);
                    end;
                until ConfigValue.Next() = 0;
        end;
        Section.Add('rows', Rows);
        Sections.Add(Section);
    end;
    local procedure AppendAttributes(ParameterCode: Code[30]; ValueCode: Code[30]; SectionCode: Text; var Rows: JsonArray)
    var
        Attr: Record "SI Parameter Value Attr.";
        Def: Record "SI Value Attr. Definition";
        Resolver: Codeunit "SI Value Attr. Resolver";
        Row: JsonObject;
    begin
        if not Resolver.GetAttributes(ParameterCode, ValueCode, Attr) then
            exit;
        Def.SetRange("Parameter Code", ParameterCode);
        Def.SetCurrentKey("Parameter Code", "Sort Order", Code);
        if Def.FindSet() then
            repeat
                if Attr.Get(ParameterCode, ValueCode, Def.Code) then begin
                    Clear(Row);
                    Row.Add('code', ParameterCode + ':' + Def.Code);
                    Row.Add('caption', '↳ ' + Def.Description);
                    Row.Add('displayValue', FormatAttribute(Attr, Def."Value Type"));
                    Row.Add('unit', Def."UoM Code");
                    Row.Add('source', SectionCode);
                    Rows.Add(Row);
                end;
            until Def.Next() = 0;
    end;

    local procedure FormatAttribute(Attr: Record "SI Parameter Value Attr."; AttrType: Enum "SI Value Attr. Type"): Text
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
