page 50187 "SI New Item Cat. Attrs"
{
    PageType = ListPart;
    SourceTable = "Item Attribute Value Selection";
    SourceTableTemporary = true;
    ApplicationArea = All;
    Caption = 'Успадковані атрибути';
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
                    Caption = 'Атрибут';
                    ToolTip = 'Показує атрибут, успадкований від батьківської категорії.';
                }

                field(Value; Rec.Value)
                {
                    ApplicationArea = All;
                    Caption = 'Default Value';
                    ToolTip = 'Показує успадковане значення атрибута.';
                }

                field("Unit of Measure"; Rec."Unit of Measure")
                {
                    ApplicationArea = All;
                    Caption = 'Unit of Measure';
                }

                field("Inherited From"; Rec."Inherited-From Key Value")
                {
                    ApplicationArea = All;
                    Caption = 'Inherited From';
                }
            }
        }
    }

    procedure InitializeForParent(ParentCategoryCode: Code[20])
    begin
        Rec.Reset();
        Rec.DeleteAll();
        LoadEffectiveInheritedAttributes(ParentCategoryCode);
        Rec.Reset();
        CurrPage.Update(false);
    end;

    local procedure LoadEffectiveInheritedAttributes(ParentCategoryCode: Code[20])
    var
        CurrentCategory: Record "Item Category";
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        SeenAttributeIds: Dictionary of [Integer, Boolean];
        CurrentCategoryCode: Code[20];
        InheritanceLevel: Integer;
    begin
        CurrentCategoryCode := ParentCategoryCode;
        InheritanceLevel := 1;

        while CurrentCategoryCode <> '' do begin
            ItemAttributeValueMapping.Reset();
            ItemAttributeValueMapping.SetRange("Table ID", Database::"Item Category");
            ItemAttributeValueMapping.SetRange("No.", CurrentCategoryCode);

            if ItemAttributeValueMapping.FindSet() then
                repeat
                    if not SeenAttributeIds.ContainsKey(ItemAttributeValueMapping."Item Attribute ID") then begin
                        ItemAttribute.Get(ItemAttributeValueMapping."Item Attribute ID");
                        ItemAttributeValue.Get(
                            ItemAttributeValueMapping."Item Attribute ID",
                            ItemAttributeValueMapping."Item Attribute Value ID");

                        Rec.Init();
                        Rec."Attribute Name" := ItemAttributeValue.GetAttributeNameInCurrentLanguage();
                        Rec.Value := ItemAttributeValue.GetValueInCurrentLanguage();
                        Rec."Attribute ID" := ItemAttributeValueMapping."Item Attribute ID";
                        Rec."Unit of Measure" := ItemAttribute."Unit of Measure";
                        Rec.Blocked := ItemAttribute.Blocked or ItemAttributeValue.Blocked;
                        Rec."Attribute Type" := ItemAttribute.Type;
                        Rec."Inherited-From Table ID" := Database::"Item Category";
                        Rec."Inherited-From Key Value" := CurrentCategoryCode;
                        Rec."Inheritance Level" := InheritanceLevel;
                        Rec.Insert();

                        SeenAttributeIds.Add(ItemAttributeValueMapping."Item Attribute ID", true);
                    end;
                until ItemAttributeValueMapping.Next() = 0;

            if not CurrentCategory.Get(CurrentCategoryCode) then
                exit;

            CurrentCategoryCode := CurrentCategory."Parent Category";
            InheritanceLevel += 1;
        end;
    end;
}
