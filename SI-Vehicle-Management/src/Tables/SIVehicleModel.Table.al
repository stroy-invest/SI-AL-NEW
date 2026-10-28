table 63205 "SI Vehicle Model"
{
    Caption = 'Модель транспорту';
    DataClassification = CustomerContent;
    LookupPageId = "SI Vehicle Models";
    DrillDownPageId = "SI Vehicle Models";
    fields
    {
        field(1; "Brand Code"; Code[20])
        {
            Caption = 'Бренд';
            TableRelation = "SI Vehicle Brand".Code;
            trigger OnValidate()
            var Brand: Record "SI Vehicle Brand";
            begin
                if "Brand Code" = '' then exit;
                Brand.Get("Brand Code");
                Brand.TestField(Blocked, false);
            end;
        }
        field(2; Code; Code[20]) { Caption = 'Код моделі'; NotBlank = true; }
        field(3; Name; Text[100]) { Caption = 'Назва'; NotBlank = true; }
        field(4; "Vehicle Type Code"; Code[20])
        {
            Caption = 'Рекомендований тип транспорту';
            TableRelation = "SI Vehicle Type".Code;
        }
        field(5; Blocked; Boolean) { Caption = 'Заблоковано'; }
    }
    keys { key(PK; "Brand Code", Code) { Clustered = true; } }
    fieldgroups { fieldgroup(DropDown; Code, Name, "Brand Code") { } }
    trigger OnDelete()
    var Vehicle: Record "SI Vehicle Profile";
    begin
        Vehicle.SetRange("Brand Code", "Brand Code");
        Vehicle.SetRange("Model Code", Code);
        if not Vehicle.IsEmpty() then Error('Модель %1 / %2 використовується транспортними засобами.', "Brand Code", Code);
    end;
}
