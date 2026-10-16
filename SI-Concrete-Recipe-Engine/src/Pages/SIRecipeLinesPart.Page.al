namespace STROYINVEST.ConcreteRecipeEngine;

using Microsoft.Inventory.Item.Attribute;

page 62104 "SI Recipe Lines Part"
{
    PageType = ListPart;
    SourceTable = "SI Concrete Recipe Line";
    Caption = 'Рядки рецептури';
    ApplicationArea = All;
    AutoSplitKey = true;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Material Type"; MaterialTypeDisplay)
                {
                    ApplicationArea = All;
                    Caption = 'Тип матеріалу';
                    trigger OnLookup(var Text: Text): Boolean
                    var
                        MaterialMgt: Codeunit "SI Recipe Material Type Mgt.";
                        ValueId: Integer;
                    begin
                        ValueId := Rec."Material Type Value ID";
                        if MaterialMgt.LookupMaterialType(ValueId) then begin
                            Rec.Validate("Material Type Value ID", ValueId);
                            RefreshMaterialTypeDisplay();
                            Text := MaterialTypeDisplay;
                        end;
                        exit(true);
                    end;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = All;
                    trigger OnLookup(var Text: Text): Boolean
                    var
                        MaterialMgt: Codeunit "SI Recipe Material Type Mgt.";
                        SelectedNo: Code[20];
                    begin
                        SelectedNo := Rec."Item No.";
                        if MaterialMgt.LookupItem(Rec."Material Type Value ID", SelectedNo) then begin
                            Rec.Validate("Item No.", SelectedNo);
                            Text := Rec."Item No.";
                        end;
                        exit(true);
                    end;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = All;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        RefreshMaterialTypeDisplay();
    end;

    local procedure RefreshMaterialTypeDisplay()
    var
        MaterialMgt: Codeunit "SI Recipe Material Type Mgt.";
        AttributeValue: Record Microsoft.Inventory.Item.Attribute."Item Attribute Value";
    begin
        MaterialTypeDisplay := '';
        if Rec."Material Type Value ID" = 0 then
            exit;
        if AttributeValue.Get(MaterialMgt.GetAttributeId(), Rec."Material Type Value ID") then
            MaterialTypeDisplay := AttributeValue.Value;
    end;

    var
        MaterialTypeDisplay: Text[250];
}
