codeunit 50296 "SI V3 Category Parameters"
{
    procedure AppendCategorySection(CategoryCode: Code[20]; var Sections: JsonArray)
    var
        ItemCategory: Record "Item Category";
        Attribute: Record "Item Attribute";
        AttributeValue: Record "Item Attribute Value";
        Mapping: Record "Item Attribute Value Mapping";
        Seen: Dictionary of [Integer, Boolean];
        Section: JsonObject;
        Rows: JsonArray;
        Row: JsonObject;
        CurrentCode: Code[20];
        SafetyCounter: Integer;
        ValueText: Text;
    begin
        Section.Add('code', 'CATEGORY');
        Section.Add('caption', 'Атрибути категорії');
        CurrentCode := CategoryCode;
        while CurrentCode <> '' do begin
            Mapping.Reset();
            Mapping.SetRange("Table ID", Database::"Item Category");
            Mapping.SetRange("No.", CurrentCode);
            if Mapping.FindSet() then
                repeat
                    if not Seen.ContainsKey(Mapping."Item Attribute ID") then begin
                        Seen.Add(Mapping."Item Attribute ID", true);
                        if Attribute.Get(Mapping."Item Attribute ID") and
                           AttributeValue.Get(Mapping."Item Attribute ID", Mapping."Item Attribute Value ID") then begin
                            ValueText := AttributeValue.Value;
                            if (ValueText <> '') and (Attribute."Unit of Measure" <> '') then
                                ValueText := StrSubstNo('%1 %2', ValueText, Attribute."Unit of Measure");
                            Clear(Row);
                            Row.Add('code', Format(Attribute.ID));
                            Row.Add('caption', Attribute.Name);
                            Row.Add('displayValue', ValueText);
                            Row.Add('unit', '');
                            Row.Add('source', 'Category');
                            Rows.Add(Row);
                        end;
                    end;
                until Mapping.Next() = 0;
            if not ItemCategory.Get(CurrentCode) then
                break;
            CurrentCode := ItemCategory."Parent Category";
            SafetyCounter += 1;
            if SafetyCounter > 100 then
                break;
        end;
        Section.Add('rows', Rows);
        Sections.Add(Section);
    end;
}
