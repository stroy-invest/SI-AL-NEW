table 63001 "SI Geo Ship-to Point"
{
    Caption = 'Географічна точка адреси доставки';
    DataClassification = CustomerContent;
    DataCaptionFields = "Customer No.", "Ship-to Code", Name;
    DrillDownPageId = "SI Geo Ship-to Points";
    LookupPageId = "SI Geo Ship-to Points";

    fields
    {
        field(1; "Customer No."; Code[20])
        {
            Caption = 'Код клієнта';
            TableRelation = Customer."No.";
            NotBlank = true;
        }
        field(2; "Ship-to Code"; Code[10])
        {
            Caption = 'Код адреси доставки';
            TableRelation = "Ship-to Address".Code where("Customer No." = field("Customer No."));
            NotBlank = true;
        }
        field(3; "Point Code"; Code[20])
        {
            Caption = 'Код точки';
            NotBlank = true;
        }
        field(4; Name; Text[100])
        {
            Caption = 'Назва';
            NotBlank = true;
        }
        field(5; Description; Text[250]) { Caption = 'Опис'; }
        field(6; "Point Type"; Enum "SI Geo Point Type") { Caption = 'Тип точки'; }
        field(7; Latitude; Decimal)
        {
            Caption = 'Широта';
            DecimalPlaces = 0 : 12;
            trigger OnValidate()
            begin
                if (Latitude < -90) or (Latitude > 90) then
                    Error('Широта повинна бути в діапазоні -90..90.');
                Verified := false;
            end;
        }
        field(8; Longitude; Decimal)
        {
            Caption = 'Довгота';
            DecimalPlaces = 0 : 12;
            trigger OnValidate()
            begin
                if (Longitude < -180) or (Longitude > 180) then
                    Error('Довгота повинна бути в діапазоні -180..180.');
                Verified := false;
            end;
        }
        field(9; Active; Boolean) { Caption = 'Активна'; }
        field(10; "Default Point"; Boolean)
        {
            Caption = 'Точка за замовчуванням';
            trigger OnValidate()
            begin
                if "Default Point" then
                    CheckDefault();
            end;
        }
        field(11; Verified; Boolean) { Caption = 'Координати перевірено'; }
    }
    keys
    {
        key(PK; "Customer No.", "Ship-to Code", "Point Code") { Clustered = true; }
    }
    trigger OnInsert()
    begin
        ValidatePoint();
    end;
    trigger OnModify()
    begin
        ValidatePoint();
    end;

    local procedure ValidatePoint()
    var
        ShipTo: Record "Ship-to Address";
    begin
        TestField("Customer No.");
        TestField("Ship-to Code");
        TestField("Point Code");
        TestField(Name);
        if not ShipTo.Get("Customer No.", "Ship-to Code") then
            Error('Адресу доставки %1 клієнта %2 не знайдено.', "Ship-to Code", "Customer No.");
        if (Latitude < -90) or (Latitude > 90) or (Longitude < -180) or (Longitude > 180) then
            Error('Координати поза допустимим діапазоном.');
        if "Default Point" then
            CheckDefault();
    end;

    local procedure CheckDefault()
    var
        OtherPoint: Record "SI Geo Ship-to Point";
    begin
        if not Active then
            Error('Точка за замовчуванням повинна бути активною.');
        OtherPoint.SetRange("Customer No.", "Customer No.");
        OtherPoint.SetRange("Ship-to Code", "Ship-to Code");
        OtherPoint.SetRange("Default Point", true);
        OtherPoint.SetFilter("Point Code", '<>%1', "Point Code");
        if not OtherPoint.IsEmpty() then
            Error('Для цієї адреси доставки вже існує точка за замовчуванням.');
    end;
}
