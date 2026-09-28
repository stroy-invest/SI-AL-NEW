table 50301 "SI Legal Form"
{
    Caption = 'Legal Form';
    DataClassification = CustomerContent;
    DrillDownPageId = "SI Legal Forms";
    LookupPageId = "SI Legal Forms";

    fields
    {
        field(1; Code; Code[20])
        {
            Caption = 'Код';
            NotBlank = true;
        }

        field(2; Description; Text[100])
        {
            Caption = 'Опис';
        }

        field(3; "Description EN"; Text[100])
        {
            Caption = 'Description EN';
            ObsoleteState = Pending;
            ObsoleteReason = 'Поле більше не використовується.';
            ObsoleteTag = '1.1.0.0';
        }

        field(4; "Legal Form Group Code"; Code[20])
        {
            Caption = 'Код групи';
            NotBlank = true;
            TableRelation = "SI Legal Form Group".Code;
        }

        field(5; "Legal Form Group Desc."; Text[100])
        {
            Caption = 'Група організаційно-правової форми';
            FieldClass = FlowField;
            CalcFormula = lookup(
                "SI Legal Form Group".Description
                where(Code = field("Legal Form Group Code"))
            );
            Editable = false;
        }

        field(6; "Short Name"; Text[50])
        {
            Caption = 'Коротка назва';
            ToolTip = 'Specifies the short name of the legal form.';
        }
    }

    keys
    {
        key(PK; Code)
        {
            Clustered = true;
        }

        key(Group; "Legal Form Group Code")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; Code, Description, "Legal Form Group Code")
        {
        }
    }
}