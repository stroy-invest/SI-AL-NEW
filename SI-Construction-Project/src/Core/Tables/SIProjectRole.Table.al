table 60010 "SI Project Role"
{
    Caption = 'Роль у будівельному проєкті';
    DataClassification = CustomerContent;

    fields
    {
        field(1; Code; Code[20])
        {
            Caption = 'Код ролі';
            DataClassification = CustomerContent;
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Назва ролі';
            DataClassification = CustomerContent;
        }
        field(3; "Assignment Cardinality"; Enum "SI Assignment Cardinality")
        {
            Caption = 'Кількість одночасних призначень';
            DataClassification = CustomerContent;
        }
        field(4; "Require Primary"; Boolean)
        {
            Caption = 'Вимагати основного';
            DataClassification = CustomerContent;
        }
        field(5; Active; Boolean)
        {
            Caption = 'Активна';
            DataClassification = CustomerContent;
            InitValue = true;
        }
        field(6; "Assignment Scope"; Enum "SI Assignment Scope")
        {
            Caption = 'Рівень призначення';
            DataClassification = CustomerContent;
        }
        field(7; "Required Capability Code"; Code[20])
        {
            Caption = 'Компетенція Workforce';
            DataClassification = CustomerContent;
            TableRelation = "SI Workforce Capability".Code where(Active = const(true));

            trigger OnValidate()
            var
                Capability: Record "SI Workforce Capability";
            begin
                if "Required Capability Code" = '' then
                    exit;
                Capability.Get("Required Capability Code");
                if not Capability.Active then
                    Error('Компетенція Workforce %1 неактивна.', Capability.Description);
            end;
        }
        field(8; Purpose; Enum "SI Project Role Purpose")
        {
            Caption = 'Системне призначення';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                ValidatePurposeUniqueness();
            end;
        }
        field(9; "Capability Description"; Text[100])
        {
            Caption = 'Назва компетенції Workforce';
            FieldClass = FlowField;
            CalcFormula = lookup("SI Workforce Capability".Description where(Code = field("Required Capability Code")));
            Editable = false;
        }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
        key(PurposeKey; Purpose, Active) { }
    }

    trigger OnInsert()
    begin
        ValidatePurposeUniqueness();
    end;

    trigger OnModify()
    begin
        ValidatePurposeUniqueness();
    end;

    local procedure ValidatePurposeUniqueness()
    var
        OtherRole: Record "SI Project Role";
    begin
        if not Active then
            exit;
        if Purpose = Purpose::General then
            exit;

        OtherRole.SetRange(Purpose, Purpose);
        OtherRole.SetRange(Active, true);
        OtherRole.SetFilter(Code, '<>%1', Code);
        if OtherRole.FindFirst() then
            Error('Системне призначення "%1" уже використовується активною роллю "%2".', Format(Purpose), OtherRole.Description);
    end;
}
