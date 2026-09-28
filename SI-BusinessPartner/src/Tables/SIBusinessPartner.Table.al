table 54003 "SI Business Partner"
{
    Caption = 'Business Partner';
    DataClassification = CustomerContent;
    DrillDownPageId = "SI Business Partners";
    LookupPageId = "SI Business Partners";
    DataCaptionFields = "Short Name BK";

    fields
    {
        field(1; "No."; Code[60])
        {
            Caption = 'No.';
            NotBlank = true;
        }

        field(2; Name; Text[100])
        {
            Caption = 'Назва контрагента';
            trigger OnValidate()
            var
                BPNamingMgt: Codeunit "SI BP Naming Mgt.";
                BPValidator: Codeunit "SI BP Validator";
            begin
                BPValidator.CheckCriticalFieldCanBeChanged(Rec, xRec, FieldCaption(Name));
                BPNamingMgt.HandleNameChange(Rec);
            end;
        }

        field(3; "Search Name"; Code[100])
        {
            Caption = 'Назва для пошуку';
            Editable = false;
        }

        field(4; Status; Enum "SI BP Status")
        {
            Caption = 'Статус';
            InitValue = Draft;
        }


        field(16; "Entity Type"; Enum "SI BP Entity Type")
        {
            Caption = 'Тип контрагента';
            trigger OnValidate()
            var
                BPNamingMgt: Codeunit "SI BP Naming Mgt.";
                BPValidator: Codeunit "SI BP Validator";
            begin
                if "Entity Type" = "Entity Type"::" " then
                    Error(EntityTypeRequiredErr);

                if "Entity Type" = xRec."Entity Type" then
                    exit;

                BPValidator.CheckCriticalFieldCanBeChanged(Rec, xRec, FieldCaption("Entity Type"));
                ClearLegalIdentity();
                BPNamingMgt.UpdateDerivedNames(Rec);
            end;
        }

        field(5; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            NotBlank = true;
            TableRelation = "Country/Region".Code;

            trigger OnValidate()
            var
                BPNamingMgt: Codeunit "SI BP Naming Mgt.";
                BPValidator: Codeunit "SI BP Validator";
                BPCurrencyMgt: Codeunit "SI BP Currency Mgt.";
            begin
                if (not IsNullGuid(SystemId)) and
                   ("Country/Region Code" = xRec."Country/Region Code")
                then
                    exit;

                BPValidator.CheckCriticalFieldCanBeChanged(
                    Rec,
                    xRec,
                    FieldCaption("Country/Region Code"));

                ClearLegalIdentity();

                BPCurrencyMgt.HandleCountryChange(Rec, xRec);

                BPNamingMgt.UpdateDerivedNames(Rec);
            end;
        }

        field(6; "Registration No."; Text[50])
        {
            Caption = 'Реєстраційний номер';
            NotBlank = true;

            trigger OnValidate()
            var
                BPIdentityMgt: Codeunit "SI BP Identity Mgt.";
                BPValidator: Codeunit "SI BP Validator";
            begin
                BPValidator.CheckCriticalFieldCanBeChanged(Rec, xRec, FieldCaption("Registration No."));
                BPIdentityMgt.SynchronizeIdentity(Rec);
            end;
        }

        field(7; "Tax Registration No."; Text[50])
        {
            Caption = 'Податковий реєстраційний номер';

            trigger OnValidate()
            var
                BPValidator: Codeunit "SI BP Validator";
            begin
                BPValidator.CheckCriticalFieldCanBeChanged(Rec, xRec, FieldCaption("Tax Registration No."));
            end;
        }

        field(8; "Legal Form Code"; Code[20])
        {
            Caption = 'Normalized Legal Form';
            TableRelation = "SI Legal Form".Code;
            Editable = false;
        }

        field(9; "Local Legal Form Code"; Code[20])
        {
            Caption = 'Офіційна юридична форма';

            TableRelation = "SI Country Legal Form".Code
                where("Country/Region Code" = field("Country/Region Code"));

            trigger OnLookup()
            var
                CountryLegalForm: Record "SI Country Legal Form";
            begin
                CheckCountrySelected();

                CountryLegalForm.SetRange("Country/Region Code", "Country/Region Code");

                if Page.RunModal(Page::"SI Country Legal Forms", CountryLegalForm) = Action::LookupOK then
                    Validate("Local Legal Form Code", CountryLegalForm.Code);
            end;

            trigger OnValidate()
            var
                BPNamingMgt: Codeunit "SI BP Naming Mgt.";
                BPValidator: Codeunit "SI BP Validator";
            begin
                BPValidator.CheckCriticalFieldCanBeChanged(Rec, xRec, FieldCaption("Local Legal Form Code"));

                if "Local Legal Form Code" = '' then begin
                    Clear("Legal Form Code");
                    BPNamingMgt.UpdateDerivedNames(Rec);
                    exit;
                end;

                CheckCountrySelected();
                ResolveLegalFormCode();
                BPNamingMgt.UpdateDerivedNames(Rec);
            end;
        }

        field(10; "Is Customer"; Boolean)
        {
            Caption = 'Клієнт';

            trigger OnValidate()
            var
                BPValidator: Codeunit "SI BP Validator";
            begin
                BPValidator.CheckCriticalFieldCanBeChanged(Rec, xRec, FieldCaption("Is Customer"));
            end;
        }

        field(11; "Is Vendor"; Boolean)
        {
            Caption = 'Постачальник';

            trigger OnValidate()
            var
                BPValidator: Codeunit "SI BP Validator";
            begin
                BPValidator.CheckCriticalFieldCanBeChanged(Rec, xRec, FieldCaption("Is Vendor"));
            end;
        }

        field(12; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            TableRelation = Customer."No.";
            Editable = false;
        }

        field(13; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor."No.";
            Editable = false;
        }

        field(14; "Full Legal Form"; Text[150])
        {
            Caption = 'Повна юридична форма';
            FieldClass = FlowField;
            CalcFormula = lookup(
                "SI Country Legal Form"."Country Legal Form Name"
                where(
                    "Country/Region Code" = field("Country/Region Code"),
                    Code = field("Local Legal Form Code")));
            Editable = false;
        }

        field(15; "Short Name BK"; Text[150])
        {
            Caption = 'Робоча назва';
            Editable = false;
        }

        field(17; "Currency Code"; Code[10])
        {
            Caption = 'Валюта контрагента';
            TableRelation = Currency.Code;

            trigger OnValidate()
            var
                BPCurrencyMgt: Codeunit "SI BP Currency Mgt.";
            begin
                if "Currency Code" = xRec."Currency Code" then
                    exit;

                BPCurrencyMgt.HandleCurrencyChanged(Rec, xRec);
            end;
        }
    }

    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }

        key(SearchName; "Search Name")
        {
        }


        key(BusinessIdentity; "Country/Region Code", "Entity Type", "Registration No.")
        {
            Unique = true;
        }

        key(TaxRegistrationNo; "Country/Region Code", "Tax Registration No.")
        {
        }

        key(StatusKey; Status)
        {
        }
    }

    trigger OnInsert()
    var
        BPIdentityMgt: Codeunit "SI BP Identity Mgt.";
        BPNamingMgt: Codeunit "SI BP Naming Mgt.";
        BPValidator: Codeunit "SI BP Validator";
        BPCurrencyMgt: Codeunit "SI BP Currency Mgt.";
    begin
        BPCurrencyMgt.EnsureDefaultCurrency(Rec);
        BPValidator.ValidateBeforeInsert(Rec);
        BPIdentityMgt.AssignIdentity(Rec);
        BPNamingMgt.UpdateDerivedNames(Rec);
    end;

    trigger OnModify()
    var
        BPValidator: Codeunit "SI BP Validator";
    begin
        BPValidator.ValidateCriticalFieldsUnchanged(Rec, xRec);
    end;

    trigger OnDelete()
    var
        BPAddress: Record "SI BP Address";
    begin
        BPAddress.SetRange("Business Partner No.", "No.");
        BPAddress.DeleteAll(true);
    end;

    local procedure CheckCountrySelected()
    begin
        if "Country/Region Code" = '' then
            Error(SelectCountryFirstErr);
    end;

    local procedure ResolveLegalFormCode()
    var
        CountryLegalForm: Record "SI Country Legal Form";
    begin
        Clear("Legal Form Code");

        if "Local Legal Form Code" = '' then
            exit;

        TestField("Country/Region Code");

        if not CountryLegalForm.Get("Country/Region Code", "Local Legal Form Code") then
            Error(LocalLegalFormNotFoundErr, "Local Legal Form Code", "Country/Region Code");

        CountryLegalForm.TestField("Legal Form Code");
        "Legal Form Code" := CountryLegalForm."Legal Form Code";
    end;

    local procedure ClearLegalIdentity()
    begin
        Clear("Local Legal Form Code");
        Clear("Legal Form Code");
        Clear("Registration No.");
        Clear("Tax Registration No.");
        Clear("Short Name BK");
        Clear("Search Name");
    end;

    var
        EntityTypeRequiredErr: Label 'Тип контрагента є обов''язковим.';
        LocalLegalFormNotFoundErr: Label 'Country legal form %1 was not found for country/region %2.';
        SelectCountryFirstErr: Label 'Select the country/region first.', Comment = 'UKR="Спочатку оберіть країну."';
}
