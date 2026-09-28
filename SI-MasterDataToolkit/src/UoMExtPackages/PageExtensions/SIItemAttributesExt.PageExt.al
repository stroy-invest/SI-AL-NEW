pageextension 58001 "SI Item Attributes Ext." extends "Item Attributes"
{
    layout
    {
        addafter(Type)
        {
            field("SI UoM Code"; Rec."SI UoM Code")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the controlled unit of measure for a numeric item attribute.';
            }
        }
    }
}