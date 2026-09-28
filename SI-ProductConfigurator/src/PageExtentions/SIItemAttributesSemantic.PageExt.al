pageextension 53027 "SI Item Attributes Semantic" extends "Item Attributes"
{
    layout
    {
        addlast(Control1)
        {
            field("SI Semantic Code"; Rec."SI Semantic Code")
            {
                ApplicationArea = All;
                Caption = 'Семантика атрибута';
                ToolTip = 'Визначає стабільну бізнес-семантику атрибута, яку прикладна логіка використовує замість назви атрибута.';
            }
        }
    }

    actions
    {
        addlast(Processing)
        {
            action(SIAttributeSemantics)
            {
                ApplicationArea = All;
                Caption = 'Семантики атрибутів';
                Image = Setup;
                RunObject = page "SI Attribute Semantics";
                ToolTip = 'Відкриває довідник семантик атрибутів.';
            }
        }
    }
}
