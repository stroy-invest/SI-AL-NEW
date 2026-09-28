table 50303 "SI Country Legal Form"
{
    Caption = 'Country Legal Form';
    DataClassification = CustomerContent;
    DrillDownPageId = "SI Country Legal Forms";
    LookupPageId = "SI Country Legal Forms";

    fields
    {
        field(1; "Legal Form Code"; Code[20])
        {
            Caption = 'Legal Form Code';
            NotBlank = true;
            TableRelation = "SI Legal Form".Code;

            trigger OnValidate()
            begin
                if "Legal Form Code" = '' then
                    exit;

                CheckCountrySelected();
                FillDomesticLegalFormNames();
            end;
        }

        field(2; Code; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }

        field(3; "Country Legal Form Name"; Text[150])
        {
            Caption = 'Country Legal Form Name';
        }

        field(4; "Short Name"; Text[50])
        {
            Caption = 'Short Name';
        }

        field(5; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            NotBlank = true;
            TableRelation = "Country/Region".Code;
        }

        field(6; "Legal Form Desc."; Text[50])
        {
            Caption = 'Legal Form Description';
            FieldClass = FlowField;
            CalcFormula = lookup(
                "SI Legal Form"."Short Name"
                where(Code = field("Legal Form Code"))
            );
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Country/Region Code", Code)
        {
            Clustered = true;
        }

        key(LegalForm; "Legal Form Code")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown;
        "Country/Region Code",
            Code,
            "Short Name",
            "Country Legal Form Name")
        {
        }
    }

    local procedure CheckCountrySelected()
    begin
        if "Country/Region Code" = '' then
            Error(SelectCountryFirstErr);
    end;

    local procedure FillDomesticLegalFormNames()
    var
        CompanyInformation: Record "Company Information";
        LegalForm: Record "SI Legal Form";
    begin
        if "Legal Form Code" = '' then
            exit;

        if not CompanyInformation.Get() then
            exit;

        if "Country/Region Code" <>
        CompanyInformation."Country/Region Code"
        then
            exit;

        if not LegalForm.Get("Legal Form Code") then
            exit;

        "Country Legal Form Name" :=
            CopyStr(
                LegalForm.Description,
                1,
                MaxStrLen("Country Legal Form Name"));

        "Short Name" :=
            CopyStr(
                LegalForm."Short Name",
                1,
                MaxStrLen("Short Name"));
    end;

    var
        SelectCountryFirstErr: Label
            'Select the country/region first.',
            Comment = 'UKR="Спочатку оберіть країну."';
}
