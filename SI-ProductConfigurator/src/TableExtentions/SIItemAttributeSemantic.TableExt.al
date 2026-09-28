tableextension 53003 "SI Item Attribute Semantic" extends "Item Attribute"
{
    fields
    {
        field(53000; "SI Semantic Code"; Code[50])
        {
            Caption = 'Семантика атрибута';
            DataClassification = CustomerContent;
            TableRelation = "SI Attribute Semantic".Code;

            trigger OnValidate()
            var
                ItemAttribute: Record "Item Attribute";
            begin
                if "SI Semantic Code" = '' then
                    exit;

                ItemAttribute.SetRange("SI Semantic Code", "SI Semantic Code");
                ItemAttribute.SetFilter(ID, '<>%1', ID);
                if ItemAttribute.FindFirst() then
                    Error(SemanticAlreadyAssignedErr, "SI Semantic Code", ItemAttribute.Name);
            end;
        }
    }

    var
        SemanticAlreadyAssignedErr: Label 'Семантику %1 вже призначено атрибуту товару "%2". Одна семантика може бути призначена лише одному атрибуту.';
}
