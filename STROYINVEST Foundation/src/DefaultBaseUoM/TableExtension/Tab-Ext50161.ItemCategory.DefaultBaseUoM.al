tableextension 50161 "SI Item Category Default UoM" extends "Item Category"
{
    fields
    {
        field(50101; "SI Default Base UoM Code"; Code[10])
        {
            Caption = 'Базова одиниця виміру';
            TableRelation = "Unit of Measure".Code;
            DataClassification = CustomerContent;
        }
    }
}