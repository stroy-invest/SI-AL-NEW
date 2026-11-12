tableextension 57146 "SI Prok Employee Driver Ext" extends Employee
{
    fields
    {
        field(57146; "SI Is Driver"; Boolean)
        {
            Caption = 'Водій Proktek';
            DataClassification = CustomerContent;
        }
        field(57147; "SI Driver Tax ID"; Code[20])
        {
            Caption = 'ІПН водія для Proktek';
            DataClassification = EndUserIdentifiableInformation;
        }
    }
}
