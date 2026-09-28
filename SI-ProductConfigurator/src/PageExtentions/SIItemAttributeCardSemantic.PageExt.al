pageextension 53028 "SI Item Attr Card Semantic" extends "Item Attribute"
{
    layout
    {
        addafter(Type)
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
