table 63207 "SI Vehicle Model Capacity"
{
    Caption = 'Характеристика моделі транспорту';
    DataClassification = CustomerContent;
    fields
    {
        field(1; "Brand Code"; Code[20])
        {
            Caption = 'Бренд';
            TableRelation = "SI Vehicle Brand".Code;
            NotBlank = true;
        }
        field(2; "Model Code"; Code[20])
        {
            Caption = 'Модель';
            TableRelation = "SI Vehicle Model".Code where("Brand Code" = field("Brand Code"));
            NotBlank = true;
        }
        field(3; "Capacity Type Code"; Code[20])
        {
            Caption = 'Тип характеристики';
            TableRelation = "SI Vehicle Capacity Type".Code;
            NotBlank = true;
            trigger OnValidate()
            begin
                ValidateSemantic();
            end;
        }
        field(4; Quantity; Decimal)
        {
            Caption = 'Кількість';
            DecimalPlaces = 0 : 5;
            trigger OnValidate()
            begin
                if Quantity <= 0 then
                    Error('Значення характеристики має бути більшим за нуль.');
            end;
        }
        field(5; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Одиниця вимірювання';
            TableRelation = "Unit of Measure".Code;
            trigger OnValidate()
            begin
                ValidateSemantic();
            end;
        }
    }
    keys { key(PK; "Brand Code", "Model Code", "Capacity Type Code") { Clustered = true; } }
    trigger OnInsert()
    begin
        ValidateRecord();
    end;
    trigger OnModify()
    begin
        ValidateRecord();
    end;
    local procedure ValidateRecord()
    var Model: Record "SI Vehicle Model";
    begin
        TestField("Brand Code");
        TestField("Model Code");
        TestField("Capacity Type Code");
        TestField("Unit of Measure Code");
        if Quantity <= 0 then
            Error('Значення характеристики має бути більшим за нуль.');
        Model.Get("Brand Code", "Model Code");
        ValidateSemantic();
    end;
    local procedure ValidateSemantic()
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
