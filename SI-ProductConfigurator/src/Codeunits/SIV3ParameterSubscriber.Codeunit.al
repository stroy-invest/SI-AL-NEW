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
                    end;
                until ConfigValue.Next() = 0;
        end;
        Section.Add('rows', Rows);
        Sections.Add(Section);
    end;
}
