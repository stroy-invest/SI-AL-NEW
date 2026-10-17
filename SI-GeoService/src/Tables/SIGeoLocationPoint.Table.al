table 63000 "SI Geo Location Point"
{
    Caption = 'Географічна точка складу';
    DataClassification = CustomerContent;
    DataCaptionFields = "Location Code", Name;
    DrillDownPageId = "SI Geo Location Points";
    LookupPageId = "SI Geo Location Points";

    fields
    {
        field(1; "Location Code"; Code[10])
        {
            Caption = 'Код складу';
            TableRelation = Location.Code;
            NotBlank = true;
        }

        field(2; "Point Code"; Code[20])
        {
            Caption = 'Код точки';
            NotBlank = true;
        }

        field(3; Name; Text[100])
        {
            Caption = 'Назва';
            NotBlank = true;
        }

        field(4; Description; Text[250])
        {
            Caption = 'Опис';
        }

        field(5; "Point Type"; Enum "SI Geo Point Type")
        {
            Caption = 'Тип точки';
        }

        field(6; Latitude; Decimal)
        {
            Caption = 'Широта';
            DecimalPlaces = 0 : 12;

            trigger OnValidate()
            begin
                if (Latitude < -90) or (Latitude > 90) then
                    Error('Широта повинна бути в діапазоні від -90 до 90.');
            end;
        }

        field(7; Longitude; Decimal)
        {
            Caption = 'Довгота';
            DecimalPlaces = 0 : 12;

            trigger OnValidate()
            begin
                if (Longitude < -180) or (Longitude > 180) then
                    Error('Довгота повинна бути в діапазоні від -180 до 180.');
            end;
        }

        field(8; Active; Boolean)
        {
            Caption = 'Активна';
            InitValue = false;
        }

        field(9; "Default Point"; Boolean)
        {
            Caption = 'Точка за замовчуванням';

            trigger OnValidate()
            var
                OtherPoint: Record "SI Geo Location Point";
            begin
                if not "Default Point" then
                    exit;

                if not Active then
                    Error('Точка за замовчуванням повинна бути активною.');

                OtherPoint.SetRange("Location Code", "Location Code");
                OtherPoint.SetRange("Default Point", true);
                OtherPoint.SetFilter("Point Code", '<>%1', "Point Code");

                if not OtherPoint.IsEmpty() then
                    Error(
                        'Для складу %1 вже існує точка за замовчуванням.',
                        "Location Code");
            end;
        }

        field(10; Verified; Boolean)
        {
            Caption = 'Координати перевірено';
            InitValue = false;
        }
    }

    keys
    {
        key(PK; "Location Code", "Point Code")
        {
            Clustered = true;
        }
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
        OtherPoint: Record "SI Geo Location Point";
    begin
        TestField("Location Code");
        TestField("Point Code");
        TestField(Name);

        if (Latitude < -90) or (Latitude > 90) then
            Error('Некоректна широта.');

        if (Longitude < -180) or (Longitude > 180) then
            Error('Некоректна довгота.');

        if "Default Point" then begin
            if not Active then
                Error('Точка за замовчуванням повинна бути активною.');

            OtherPoint.SetRange("Location Code", "Location Code");
            OtherPoint.SetRange("Default Point", true);
            OtherPoint.SetFilter("Point Code", '<>%1', "Point Code");

            if not OtherPoint.IsEmpty() then
                Error('Для цього складу вже існує точка за замовчуванням.');
        end;
    end;
}