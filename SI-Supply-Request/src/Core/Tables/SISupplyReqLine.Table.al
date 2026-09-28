table 61002 "SI Supply Req Line"
{
    Caption = 'Рядок заявки на забезпечення';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Request No."; Code[20])
        {
            Caption = '№ заявки';
            TableRelation = "SI Supply Req Header"."No.";
        }
        field(2; "Line No."; Integer)
        {
            Caption = '№ рядка';
        }
        field(5; "Construction Site Code"; Code[20])
        {
            Caption = 'Буд. майданчик';

            trigger OnValidate()
            begin
                TestHeaderEditable();
                ValidateConstructionSite();
            end;
        }
        field(10; "Line Type"; Enum "SI Supply Line Type")
        {
            Caption = 'Тип рядка';

            trigger OnValidate()
            begin
                TestHeaderEditable();
                if "Line Type" = "Line Type"::"Free Text" then begin
                    "Item No." := '';
                    "Variant Code" := '';
                    "Unit of Measure Code" := '';
                end;
            end;
        }
        field(20; "Item No."; Code[20])
        {
            Caption = 'Товар';
            TableRelation = Item."No.";

            trigger OnValidate()
            var
                Item: Record Item;
            begin
                TestHeaderEditable();
                if "Item No." = '' then begin
                    "Variant Code" := '';
                    "Unit of Measure Code" := '';
                    exit;
                end;

                TestField("Line Type", "Line Type"::Item);
                Item.Get("Item No.");
                Description := Item.Description;
                "Variant Code" := '';
                "Unit of Measure Code" := Item."Base Unit of Measure";
            end;
        }
        field(30; "Variant Code"; Code[10])
        {
            Caption = 'Варіант';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));

            trigger OnValidate()
            var
                Variant: Record "Item Variant";
            begin
                TestHeaderEditable();
                if "Variant Code" = '' then
                    exit;
                TestField("Item No.");
                Variant.Get("Item No.", "Variant Code");
                if Variant.Description <> '' then
                    Description := Variant.Description;
            end;
        }
        field(40; Description; Text[250])
        {
            Caption = 'Опис потреби';
        }
        field(50; "Requested Quantity"; Decimal)
        {
            Caption = 'Заявлена кількість';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                TestHeaderEditable();
                if ("Line Type" = "Line Type"::Item) and ("Requested Quantity" <= 0) then
                    Error('Для товарного рядка заявлена кількість має бути більшою за нуль.');
            end;
        }
        field(60; "Approved Quantity"; Decimal)
        {
            Caption = 'Погоджена кількість';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(70; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Од. вим.';
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));
        }
        field(80; "Required on Site Date"; Date)
        {
            Caption = 'Потрібно на об''єкті (legacy)';
            ObsoleteState = Pending;
            ObsoleteReason = 'Replaced by Required on Site At with DateTime precision.';
        }
        field(81; "Required on Site At"; DateTime)
        {
            Caption = 'Потрібно на об''єкті';

            trigger OnValidate()
            begin
                TestHeaderEditable();
                ValidateRequiredOnSiteAt("Required on Site At");
            end;
        }
        field(90; Comment; Text[250])
        {
            Caption = 'Коментар';
        }
    }

    keys
    {
        key(PK; "Request No.", "Line No.") { Clustered = true; }
        key(Item; "Item No.", "Variant Code") { }
    }

    trigger OnInsert()
    begin
        TestHeaderEditable();
        ApplyHeaderDefaults();
    end;

    trigger OnModify()
    begin
        TestHeaderEditable();
    end;

    trigger OnDelete()
    var
        Parameter: Record "SI Supply Req Parameter";
    begin
        TestHeaderEditable();
        Parameter.SetRange("Request No.", "Request No.");
        Parameter.SetRange("Request Line No.", "Line No.");
        Parameter.DeleteAll(true);
    end;

    procedure ApplyHeaderDefaults()
    var
        Header: Record "SI Supply Req Header";
    begin
        if "Request No." = '' then
            exit;
        if not Header.Get("Request No.") then
            exit;
        if "Required on Site At" = 0DT then
            "Required on Site At" := Header."Required on Site At";
    end;

    local procedure ValidateRequiredOnSiteAt(RequiredOnSiteAt: DateTime)
    begin
        if RequiredOnSiteAt = 0DT then
            Error('Необхідно вказати дату та час потреби на об''єкті.');

        if DT2Time(RequiredOnSiteAt) = 000000T then
            Error('Необхідно вказати точний час потреби на об''єкті. Значення 00:00 не допускається.');

        if RequiredOnSiteAt < CurrentDateTime() then
            Error('Дата та час потреби на об''єкті не можуть бути раніше поточного часу.');
    end;

    local procedure ValidateConstructionSite()
    var
        Header: Record "SI Supply Req Header";
        Site: Record "SI Construction Site";
        RequestSite: Record "SI Supply Request Site";
    begin
        if "Construction Site Code" = '' then
            exit;

        if not Header.Get("Request No.") then
            Error('Не знайдено заявку %1.', "Request No.");
        Header.TestField("Project No.");

        if not Site.Get(Header."Project No.", "Construction Site Code") then
            Error('Будівельний майданчик %1 не належить проєкту %2.', "Construction Site Code", Header."Project No.");
        if Site.Status <> Site.Status::Active then
            Error('Будівельний майданчик %1 не є активним.', Site.Name);
        if (not RequestSite.Get("Request No.", "Construction Site Code")) or (not RequestSite.Selected) then
            Error('Будівельний майданчик %1 не включено до заявки %2.', Site.Name, "Request No.");
    end;

    local procedure TestHeaderEditable()
    var
        Header: Record "SI Supply Req Header";
    begin
        if not Header.Get("Request No.") then
            exit;
        Header.TestEditable();
    end;
}
