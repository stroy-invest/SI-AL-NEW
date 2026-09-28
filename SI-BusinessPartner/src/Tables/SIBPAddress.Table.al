table 54020 "SI BP Address"
{
    Caption = 'Адреса контрагента';
    DataClassification = CustomerContent;
    DrillDownPageId = "SI BP Addresses";
    LookupPageId = "SI BP Addresses";

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
        field(3; "Address Type"; Enum "SI BP Address Type")
        {
            Caption = 'Тип адреси';
            NotBlank = true;
        }
        field(4; "Country/Region Code"; Code[10])
        {
            Caption = 'Код країни/регіону';
            TableRelation = "Country/Region".Code;
            NotBlank = true;
        }
        field(5; "Region/State"; Text[100])
        {
            Caption = 'Область/регіон';
        }
        field(6; District; Text[100])
        {
            Caption = 'Район';
        }
        field(7; City; Text[100])
        {
            Caption = 'Місто';
        }
        field(8; "Post Code"; Code[20])
        {
            Caption = 'Поштовий індекс';
        }
        field(9; Street; Text[150])
        {
            Caption = 'Вулиця';
        }
        field(10; "Building No."; Text[30])
        {
            Caption = 'Номер будинку';
        }
        field(11; "Office/Apartment"; Text[30])
        {
            Caption = 'Офіс/квартира';
        }
        field(12; "Address Details"; Text[250])
        {
            Caption = 'Деталі адреси';
        }
        field(13; "Raw Address"; Text[500])
        {
            Caption = 'Адреса з джерела';
        }
        field(14; "Valid From"; Date)
        {
            Caption = 'Діє з';

            trigger OnValidate()
            begin
                ValidateValidityPeriod();
            end;
        }
        field(15; "Valid To"; Date)
        {
            Caption = 'Діє до';

            trigger OnValidate()
            begin
                ValidateValidityPeriod();
            end;
        }
        field(16; "Is Primary"; Boolean)
        {
            Caption = 'Основний';
        }
        field(17; Verified; Boolean)
        {
            Caption = 'Перевірено';
        }
        field(18; "Verification Source"; Code[30])
        {
            Caption = 'Джерело перевірки';
        }
        field(19; "Verification Date/Time"; DateTime)
        {
            Caption = 'Дата й час перевірки';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(BusinessPartner; "Business Partner No.", "Address Type", "Valid From")
        {
        }
        key(CurrentAddress; "Business Partner No.", "Address Type", "Valid To")
        {
        }
    }

    trigger OnInsert()
    begin
        ValidateRecord();
    end;

    trigger OnModify()
    begin
        ValidateRecord();
    end;

    local procedure ValidateRecord()
    begin
        TestField("Business Partner No.");
        TestField("Address Type");
        TestField("Country/Region Code");
        ValidateValidityPeriod();
        ValidateNoOverlappingLegalAddress();
    end;

    local procedure ValidateValidityPeriod()
    begin
        if ("Valid To" <> 0D) and ("Valid From" <> 0D) and ("Valid To" < "Valid From") then
            Error(InvalidValidityPeriodErr);
    end;

    local procedure ValidateNoOverlappingLegalAddress()
    var
        BPAddress: Record "SI BP Address";
    begin
        if "Address Type" <> "Address Type"::Legal then
            exit;

        BPAddress.SetRange("Business Partner No.", "Business Partner No.");
        BPAddress.SetRange("Address Type", BPAddress."Address Type"::Legal);
        BPAddress.SetFilter("Entry No.", '<>%1', "Entry No.");

        if BPAddress.FindSet() then
            repeat
                if PeriodsOverlap("Valid From", "Valid To", BPAddress."Valid From", BPAddress."Valid To") then
                    Error(
                        OverlappingLegalAddressErr,
                        BPAddress."Entry No.",
                        BPAddress."Valid From",
                        BPAddress."Valid To");
            until BPAddress.Next() = 0;
    end;

    local procedure PeriodsOverlap(FromDate1: Date; ToDate1: Date; FromDate2: Date; ToDate2: Date): Boolean
    var
        EffectiveFrom1: Date;
        EffectiveFrom2: Date;
        EffectiveTo1: Date;
        EffectiveTo2: Date;
    begin
        EffectiveFrom1 := FromDate1;
        EffectiveFrom2 := FromDate2;

        if EffectiveFrom1 = 0D then
            EffectiveFrom1 := DMY2Date(1, 1, 1753);
        if EffectiveFrom2 = 0D then
            EffectiveFrom2 := DMY2Date(1, 1, 1753);

        EffectiveTo1 := ToDate1;
        EffectiveTo2 := ToDate2;

        if EffectiveTo1 = 0D then
            EffectiveTo1 := DMY2Date(31, 12, 9999);
        if EffectiveTo2 = 0D then
            EffectiveTo2 := DMY2Date(31, 12, 9999);

        exit((EffectiveFrom1 <= EffectiveTo2) and (EffectiveFrom2 <= EffectiveTo1));
    end;

    var
        InvalidValidityPeriodErr: Label 'Valid To cannot be earlier than Valid From.';
        OverlappingLegalAddressErr: Label 'The legal address overlaps address entry %1 with validity period %2–%3.';
}
