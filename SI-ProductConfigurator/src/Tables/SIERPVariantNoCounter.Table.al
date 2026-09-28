table 53009 "SI ERP Variant No. Counter"
{
    Caption = 'Лічильник номерів ERP-варіантів';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Item No."; Code[20])
        {
            Caption = 'Номер товару';
            DataClassification = CustomerContent;
            NotBlank = true;
            TableRelation = Item."No.";
        }

        field(10; "Last No."; BigInteger)
        {
            Caption = 'Останній номер';
            DataClassification = SystemMetadata;
            MinValue = 0;
        }
    }

    keys
    {
        key(PK; "Item No.")
        {
            Clustered = true;
        }
    }
}
