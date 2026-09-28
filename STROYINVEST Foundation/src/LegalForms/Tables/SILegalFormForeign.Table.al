table 50302 "SI Legal Form Foreign"
{
    Caption = 'Foreign Legal Form';
    DataClassification = CustomerContent;
    DrillDownPageId = "SI Foreign Legal Forms";
    LookupPageId = "SI Foreign Legal Forms";

    fields
    {
        field(1; "Legal Form Code"; Code[20])
        {
            Caption = 'Legal Form Code';
            NotBlank = true;
            TableRelation = "SI Legal Form".Code;
        }

        field(2; Code; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }

        field(3; "Foreign Legal Form Name"; Text[150])
        {
            Caption = 'Foreign Legal Form Name';
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
            Caption = 'Організаційно-правова форма';
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
            "Foreign Legal Form Name")
        {
        }
    }
}