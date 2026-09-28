table 54021 "SI BP Contact Point"
{
    Caption = 'Контакт контрагента';
    DataClassification = CustomerContent;
    DrillDownPageId = "SI BP Contact Points";
    LookupPageId = "SI BP Contact Points";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Номер запису';
            AutoIncrement = true;
        }
        field(2; "Business Partner No."; Code[60])
        {
            Caption = 'Код контрагента';
            TableRelation = "SI Business Partner"."No.";
            NotBlank = true;
        }
        field(3; Type; Enum "SI BP Contact Point Type")
        {
            Caption = 'Тип';
            NotBlank = true;
        }
        field(4; "Subtype Code"; Code[30])
        {
            Caption = 'Код підтипу';
        }
        field(5; Value; Text[250])
        {
            Caption = 'Значення';
            NotBlank = true;
        }
        field(6; Description; Text[100])
        {
            Caption = 'Опис';
        }
        field(7; "Is Primary"; Boolean)
        {
            Caption = 'Основний';

            trigger OnValidate()
            begin
                if "Is Primary" then
                    ClearOtherPrimaryContactPoints();
            end;
        }
        field(8; Active; Boolean)
        {
            Caption = 'Активний';
            InitValue = true;
        }
        field(9; Verified; Boolean)
        {
            Caption = 'Перевірено';
        }
        field(10; "Verification Date/Time"; DateTime)
        {
            Caption = 'Дата й час перевірки';
        }
        field(11; "Valid From"; Date)
        {
            Caption = 'Діє з';
        }
        field(12; "Valid To"; Date)
        {
            Caption = 'Діє до';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(BusinessPartner; "Business Partner No.", Type, Active)
        {
        }
    }

    trigger OnInsert()
    begin
        TestField("Business Partner No.");
        TestField(Type);
        TestField(Value);
        if "Is Primary" then
            ClearOtherPrimaryContactPoints();
    end;

    local procedure ClearOtherPrimaryContactPoints()
    var
        ContactPoint: Record "SI BP Contact Point";
    begin
        ContactPoint.SetRange("Business Partner No.", "Business Partner No.");
        ContactPoint.SetRange(Type, Type);
        ContactPoint.SetRange("Is Primary", true);
        ContactPoint.SetFilter("Entry No.", '<>%1', "Entry No.");

        if ContactPoint.FindSet(true) then
            repeat
                ContactPoint."Is Primary" := false;
                ContactPoint.Modify(false);
            until ContactPoint.Next() = 0;
    end;
}
