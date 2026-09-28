tableextension 58001 "SI Item Attribute Ext." extends "Item Attribute"
{
    fields
    {
        field(58000; "SI UoM Code"; Code[10])
        {
            Caption = 'SI Unit of Measure Code';
            DataClassification = CustomerContent;
            TableRelation = "Unit of Measure".Code where("SI Blocked" = const(false));

            trigger OnValidate()
            var
                SIUoMMgt: Codeunit "SI UoM Mgt.";
            begin
                SIUoMMgt.ValidateItemAttributeUoM(Rec);
            end;
        }
    }
}
