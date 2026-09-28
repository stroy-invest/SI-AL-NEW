tableextension 55013 "SI Prod Config Mfr Name" extends "SI Product Config."
{
    fields
    {
        field(55000; "SI Show Manufacturer in Name"; Boolean)
        {
            Caption = 'Виводити назву виробника';
            DataClassification = CustomerContent;
            InitValue = false;
        }
    }
}
