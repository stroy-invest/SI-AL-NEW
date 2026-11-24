page 53040 "SI Parameter Value Attrs"
{
    PageType = List;
    SourceTable = "SI Parameter Value Attr.";
    ApplicationArea = All;
    Caption = 'Додаткові характеристики';
    DelayedInsert = true;
    PopulateAllFields = true;
    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Parameter Code"; Rec."Parameter Code") { ApplicationArea = All; }
                field("Value Code"; Rec."Value Code") { ApplicationArea = All; }
                field("Attribute Code"; Rec."Attribute Code") { ApplicationArea = All; trigger OnValidate() begin RefreshType(); end; }
                field("Decimal Value"; Rec."Decimal Value") { ApplicationArea = All; Editable = HasDefinition and (AttrType = AttrType::Decimal); }
                field("Integer Value"; Rec."Integer Value") { ApplicationArea = All; Editable = HasDefinition and (AttrType = AttrType::Integer); }
                field("Text Value"; Rec."Text Value") { ApplicationArea = All; Editable = HasDefinition and (AttrType = AttrType::Text); }
                field("Boolean Value"; Rec."Boolean Value") { ApplicationArea = All; Editable = HasDefinition and (AttrType = AttrType::Boolean); }
                field("Has Minimum"; Rec."Has Minimum") { ApplicationArea = All; Editable = HasDefinition and (AttrType = AttrType::Range); }
                field("Minimum"; Rec."Minimum") { ApplicationArea = All; Editable = HasDefinition and (AttrType = AttrType::Range); }
                field("Has Maximum"; Rec."Has Maximum") { ApplicationArea = All; Editable = HasDefinition and (AttrType = AttrType::Range); }
                field("Maximum"; Rec."Maximum") { ApplicationArea = All; Editable = HasDefinition and (AttrType = AttrType::Range); }
            }
        }
    }
    trigger OnAfterGetCurrRecord()
    begin
        RefreshType();
    end;
    local procedure RefreshType()
    var
        Def: Record "SI Value Attr. Definition";
    begin
        HasDefinition := Def.Get(Rec."Parameter Code", Rec."Attribute Code");
        if HasDefinition then
            AttrType := Def."Value Type";
    end;
    var
        HasDefinition: Boolean;
        AttrType: Enum "SI Value Attr. Type";
}
