table 50185 "SI Category Attribute Buffer"
{
    Caption = 'Буфер атрибутів категорії';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Номер запису';
        }
        field(10; "Attribute ID"; Integer)
        {
            Caption = 'ID атрибута';
        }
        field(20; "Attribute Name"; Text[250])
        {
            Caption = 'Назва';
        }
        field(30; "Display Value"; Text[250])
        {
            Caption = 'Значення';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Attribute; "Attribute ID")
        {
        }
    }
}
