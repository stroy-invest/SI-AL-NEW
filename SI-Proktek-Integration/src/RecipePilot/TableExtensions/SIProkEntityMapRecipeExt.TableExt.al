tableextension 57090 "SI Prok Entity Map Rec Ext" extends "SI Prok Entity Mapping"
{
    fields
    {
        field(57090; "SI Recipe No."; Code[50])
        {
            Caption = 'Код рецептури BC';
            DataClassification = CustomerContent;
        }
        field(57091; "SI Recipe Revision No."; Integer)
        {
            Caption = '№ ревізії BC';
            DataClassification = CustomerContent;
        }
        field(57092; "SI Formula Proj. Status"; Enum "SI Prok Formula Proj Status")
        {
            Caption = 'Статус проєкції Formula';
            DataClassification = CustomerContent;
        }
        field(57093; "SI Proktek Active"; Boolean)
        {
            Caption = 'Активна в Proktek';
            DataClassification = CustomerContent;
        }
        field(57094; "SI Last Sync By"; Guid)
        {
            Caption = 'Остання синхронізація користувачем';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(57095; "SI Last Error"; Text[2048])
        {
            Caption = 'Остання помилка';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(SIRecipeRevision; "Connection Code", "Entity Type", "SI Recipe No.", "SI Recipe Revision No.") { }
    }
}
