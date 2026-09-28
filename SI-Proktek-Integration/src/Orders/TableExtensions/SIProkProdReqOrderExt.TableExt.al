tableextension 57029 "SI Prok Prod Req Order Ext" extends "SI Concrete Prod Request"
{
    fields
    {
        field(57000; "Proktek Order ID"; BigInteger)
        {
            Caption = 'Proktek Order ID';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(57001; "Proktek Order UUID"; Guid)
        {
            Caption = 'Proktek Order UUID';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(57002; "Proktek Order Synced At"; DateTime)
        {
            Caption = 'Передано до Proktek';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(57003; "Proktek Last Message"; Text[250])
        {
            Caption = 'Остання відповідь Proktek';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}
