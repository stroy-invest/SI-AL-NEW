tableextension 50100 "SI Item Category Ext." extends "Item Category"
{
    fields
    {
        field(50100; "SI Item No. Series Code"; Code[20])
        {
            Caption = 'Серія номерів товарів';
            TableRelation = "No. Series".Code;
            DataClassification = CustomerContent;
        }
		
		field(50170; "SI Category Kind"; Enum "SI Category Kind")
		{
			Caption = 'Тип категорії';
			DataClassification = CustomerContent;
		}

		field(50171; "SI Finished Type"; Enum "SI Finished Type")
		{
			Caption = 'Тип готової продукції';
			DataClassification = CustomerContent;
		}		
    }
}