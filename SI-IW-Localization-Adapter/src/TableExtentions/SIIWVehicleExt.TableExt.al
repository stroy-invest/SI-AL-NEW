
tableextension 65000 "SI IW Vehicle Ext" extends IWSVehicle
{
    fields
    {
        field(65000; "SI Vehicle No."; Code[20])
        {
            Caption = 'SI Vehicle No.';
            DataClassification = CustomerContent;
            TableRelation = "SI Vehicle Profile"."No.";
            Editable = false;
        }
    }

    trigger OnBeforeRename()
    begin
        Error(
            'Changing the vehicle registration number ' +
            'in IW Foundation is prohibited.');
    end;
}
