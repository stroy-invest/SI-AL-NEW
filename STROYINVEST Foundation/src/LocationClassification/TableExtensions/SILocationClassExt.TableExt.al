tableextension 50502 "SI Location Class. Ext." extends Location
{
    fields
    {
        field(50500; "SI Location Type Code"; Code[20])
        {
            Caption = 'Тип складу';
            DataClassification = CustomerContent;
            TableRelation = "SI Location Type".Code where(Active = const(true));
        }
    }
}
