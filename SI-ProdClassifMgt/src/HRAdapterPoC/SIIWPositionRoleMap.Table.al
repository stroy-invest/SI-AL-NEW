table 56204 "SI IW Position Role Map"
{
    Caption = 'Відповідність посад IW ролям SI';
    DataClassification = CustomerContent;
    LookupPageId = "SI IW Position Role Maps";
    DrillDownPageId = "SI IW Position Role Maps";

    fields
    {
        field(1; "IW Position Code"; Code[20])
        {
            Caption = 'Посада IW';
            DataClassification = CustomerContent;
        }
        field(2; "SI Project Role Code"; Code[20])
        {
            Caption = 'Роль у будівельному проєкті';
            DataClassification = CustomerContent;
            TableRelation = "SI Project Role".Code where(Active = const(true));
        }
        field(3; Active; Boolean)
        {
            Caption = 'Активна';
            DataClassification = CustomerContent;
            InitValue = true;
        }
    }

    keys
    {
        key(PK; "IW Position Code", "SI Project Role Code") { Clustered = true; }
        key(Role; "SI Project Role Code", Active) { }
    }
}
