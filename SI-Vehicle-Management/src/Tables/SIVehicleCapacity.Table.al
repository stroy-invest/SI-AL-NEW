table 63203 "SI Vehicle Capacity"
{
    Caption = 'Характеристика транспорту';
    DataClassification = CustomerContent;
    fields
    {
        field(1; "Vehicle No."; Code[20])
        {
            Caption = 'Транспортний засіб';
            TableRelation = "SI Vehicle Profile"."No.";
            NotBlank = true;
        }
        field(2; "Capacity Type Code"; Code[20])
        {
            Caption = 'Тип характеристики';
            TableRelation = "SI Vehicle Capacity Type".Code;
            NotBlank = true;
            trigger OnValidate()
            begin
                ValidateCapacity();
            end;
        }
        field(3; Quantity; Decimal)
        {
            Caption = 'Кількість';
            DecimalPlaces = 0 : 5;
            trigger OnValidate()
            begin
                if Quantity <= 0 then Error('Значення характеристики має бути більшим за нуль.');
            end;
        }
        field(4; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Одиниця вимірювання';
            TableRelation = "Unit of Measure".Code;
            trigger OnValidate()
            begin
                ValidateCapacity();
            end;
        }
    }
    keys { key(PK; "Vehicle No.", "Capacity Type Code") { Clustered = true; } }
    trigger OnInsert()
    begin
        TestField("Vehicle No.");
        TestField("Capacity Type Code");
        TestField("Unit of Measure Code");
        if Quantity <= 0 then Error('Значення характеристики має бути більшим за нуль.');
        ValidateCapacity();
    end;
    trigger OnModify()
    begin
        TestField("Unit of Measure Code");
        if Quantity <= 0 then Error('Значення характеристики має бути більшим за нуль.');
        ValidateCapacity();
    end;
    local procedure ValidateCapacity()
    var
        CapacityType: Record "SI Vehicle Capacity Type";
        SemanticMgt: Codeunit "SI UoM Semantic Mgt.";
    begin
        if "Capacity Type Code" = '' then exit;
        CapacityType.Get("Capacity Type Code");
        CapacityType.TestField(Blocked, false);
        CapacityType.TestField("Required Semantic Code");
        if "Unit of Measure Code" <> '' then
            SemanticMgt.AssertPhysicalUoM("Unit of Measure Code", CapacityType."Required Semantic Code");
    end;
}
