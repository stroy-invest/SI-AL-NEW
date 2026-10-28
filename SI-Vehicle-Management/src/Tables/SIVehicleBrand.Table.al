table 63204 "SI Vehicle Brand"
{
    Caption = 'Бренд транспорту';
    DataClassification = CustomerContent;
    LookupPageId = "SI Vehicle Brands";
    DrillDownPageId = "SI Vehicle Brands";
    fields
    {
        field(1; Code; Code[20]) { Caption = 'Код'; NotBlank = true; }
        field(2; Name; Text[100]) { Caption = 'Назва'; NotBlank = true; }
        field(3; "Manufacturer Code"; Code[20])
        {
            Caption = 'Виробник';
            TableRelation = "SI Manufacturer".Code where("Is Vehicle Producer" = const(true), Blocked = const(false));
            trigger OnValidate()
            var Manufacturer: Record "SI Manufacturer";
            begin
                if "Manufacturer Code" = '' then exit;
                Manufacturer.Get("Manufacturer Code");
                Manufacturer.TestField(Blocked, false);
                Manufacturer.TestField("Is Vehicle Producer", true);
            end;
        }
        field(4; Blocked; Boolean) { Caption = 'Заблоковано'; }
    }
    keys { key(PK; Code) { Clustered = true; } key(Manufacturer; "Manufacturer Code") { } }
    fieldgroups { fieldgroup(DropDown; Code, Name, "Manufacturer Code") { } }
    trigger OnDelete()
    var Model: Record "SI Vehicle Model"; Vehicle: Record "SI Vehicle Profile";
    begin
        Model.SetRange("Brand Code", Code);
        if not Model.IsEmpty() then Error('Бренд %1 використовується в довіднику моделей.', Code);
        Vehicle.SetRange("Brand Code", Code);
        if not Vehicle.IsEmpty() then Error('Бренд %1 використовується транспортними засобами.', Code);
    end;
}
