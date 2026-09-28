table 61042 "SI VSC Manufacturer"
{
    Caption = 'Виробник каналу постачання';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Capability Code"; Code[20])
        {
            Caption = 'Код каналу постачання';
            TableRelation = "SI Vendor Supply Capability".Code;
            NotBlank = true;
        }
        field(2; "Manufacturer Code"; Code[20])
        {
            Caption = 'Код виробника';
            TableRelation = "SI Manufacturer".Code where(Blocked = const(false));
            NotBlank = true;
        }
        field(10; "Manufacturer Name"; Text[100])
        {
            Caption = 'Виробник';
            FieldClass = FlowField;
            CalcFormula = lookup("SI Manufacturer".Name where(Code = field("Manufacturer Code")));
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Capability Code", "Manufacturer Code") { Clustered = true; }
        key(Manufacturer; "Manufacturer Code", "Capability Code") { }
    }
}
