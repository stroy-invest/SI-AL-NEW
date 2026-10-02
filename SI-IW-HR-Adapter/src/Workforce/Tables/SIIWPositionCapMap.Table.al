table 51001 "SI IW Position Cap. Map"
{
    Caption = 'Відповідність посад IW компетенціям SI';
    DataClassification = CustomerContent;
    LookupPageId = "SI IW Position Cap. Maps";
    DrillDownPageId = "SI IW Position Cap. Maps";

    fields
    {
        field(1; "IW Position Code"; Code[20])
        {
            Caption = 'Посада IW';
            DataClassification = CustomerContent;
            TableRelation = "IWSP Position".Code;
        }
        field(2; "Capability Code"; Code[20])
        {
            Caption = 'Компетенція SI';
            DataClassification = CustomerContent;
            TableRelation = "SI Workforce Capability".Code where(Active = const(true));
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
        key(PK; "IW Position Code", "Capability Code") { Clustered = true; }
        key(Capability; "Capability Code", Active) { }
    }
}
