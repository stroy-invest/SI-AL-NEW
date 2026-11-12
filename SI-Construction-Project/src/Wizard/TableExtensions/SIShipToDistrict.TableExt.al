tableextension 60027 "SI Ship-to District Ext" extends "Ship-to Address"
{
    fields
    {
        field(60014; "SI District"; Text[100])
        {
            Caption = 'Район';
            DataClassification = CustomerContent;
        }
    }
}
