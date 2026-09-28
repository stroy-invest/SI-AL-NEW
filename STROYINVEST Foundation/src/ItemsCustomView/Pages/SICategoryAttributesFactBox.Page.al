page 50188 "SI Category Attributes FactBox"
{
    PageType = ListPart;
    SourceTable = "SI Category Attribute Buffer";
    SourceTableTemporary = true;
    Caption = 'Атрибути категорії';
    ApplicationArea = All;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Attributes)
            {
                field("Attribute Name"; Rec."Attribute Name")
                {
                    ApplicationArea = All;
                    Caption = 'Назва';
                    ToolTip = 'Визначає назву effective-атрибута вибраної категорії.';
                }
                field("Display Value"; Rec."Display Value")
                {
                    ApplicationArea = All;
                    Caption = 'Значення';
                    ToolTip = 'Відображає значення атрибута разом з одиницею виміру, якщо вона визначена.';
                }
            }
        }
    }

    procedure LoadAttributes(ItemCategoryCode: Code[20])
    var
        ItemCategory: Record "Item Category";
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        SeenAttributeIds: Dictionary of [Integer, Boolean];
        CurrentCategoryCode: Code[20];
        EntryNo: Integer;
        SafetyCounter: Integer;
        DisplayValue: Text[250];
    begin
        Rec.Reset();
        Rec.DeleteAll();

        CurrentCategoryCode := ItemCategoryCode;
        EntryNo := 0;

        // Traverse from the selected category upwards. The first occurrence of an
        // Attribute ID wins, therefore a local value overrides an inherited one.
        while CurrentCategoryCode <> '' do begin
            ItemAttributeValueMapping.Reset();
            ItemAttributeValueMapping.SetRange("Table ID", Database::"Item Category");
            ItemAttributeValueMapping.SetRange("No.", CurrentCategoryCode);

            if ItemAttributeValueMapping.FindSet() then
                repeat
                    if not SeenAttributeIds.ContainsKey(ItemAttributeValueMapping."Item Attribute ID") then begin
                        SeenAttributeIds.Add(ItemAttributeValueMapping."Item Attribute ID", true);

                        if ItemAttribute.Get(ItemAttributeValueMapping."Item Attribute ID") and
                           ItemAttributeValue.Get(
                               ItemAttributeValueMapping."Item Attribute ID",
                               ItemAttributeValueMapping."Item Attribute Value ID")
                        then begin
                            DisplayValue := CopyStr(ItemAttributeValue.Value, 1, MaxStrLen(DisplayValue));
                            if (DisplayValue <> '') and (ItemAttribute."Unit of Measure" <> '') then
                                DisplayValue := CopyStr(
                                    StrSubstNo('%1 %2', DisplayValue, ItemAttribute."Unit of Measure"),
                                    1,
                                    MaxStrLen(DisplayValue));

                            EntryNo += 1;
                            Rec.Init();
                            Rec."Entry No." := EntryNo;
                            Rec."Attribute ID" := ItemAttribute.ID;
                            Rec."Attribute Name" := CopyStr(ItemAttribute.Name, 1, MaxStrLen(Rec."Attribute Name"));
                            Rec."Display Value" := DisplayValue;
                            Rec.Insert();
                        end;
                    end;
                until ItemAttributeValueMapping.Next() = 0;

            if not ItemCategory.Get(CurrentCategoryCode) then
                break;

            CurrentCategoryCode := ItemCategory."Parent Category";
            SafetyCounter += 1;
            if SafetyCounter > 100 then
                break;
        end;

        Rec.Reset();
        Rec.SetCurrentKey("Entry No.");
        if Rec.FindFirst() then;
        CurrPage.Update(false);
    end;

    procedure ClearAttributes()
    begin
        Rec.Reset();
        Rec.DeleteAll();
        CurrPage.Update(false);
    end;
}
