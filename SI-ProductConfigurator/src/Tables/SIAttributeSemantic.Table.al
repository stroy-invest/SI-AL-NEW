table 53012 "SI Attribute Semantic"
{
    Caption = 'SI Attribute Semantic';
    DataClassification = CustomerContent;
    LookupPageId = "SI Attribute Semantics";
    DrillDownPageId = "SI Attribute Semantics";

    fields
    {
        field(1; Code; Code[50])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Name; Text[150])
        {
            Caption = 'Name';
        }
    }

    keys
    {
        key(PK; Code)
        {
            Clustered = true;
        }
    }

    trigger OnDelete()
    var
        ItemAttribute: Record "Item Attribute";
        ProductParameter: Record "SI Product Parameter";
    begin
        ItemAttribute.SetRange("SI Semantic Code", Code);
        if not ItemAttribute.IsEmpty() then
            Error(SemanticUsedByAttributeErr, Code);

        ProductParameter.SetRange("SI Semantic Code", Code);
        if not ProductParameter.IsEmpty() then
            Error(SemanticUsedByParameterErr, Code);
    end;

    var
        SemanticUsedByAttributeErr: Label 'Семантику %1 не можна видалити, оскільки її призначено атрибуту товару.';
        SemanticUsedByParameterErr: Label 'Семантику %1 не можна видалити, оскільки її призначено параметру продукту.';
}
