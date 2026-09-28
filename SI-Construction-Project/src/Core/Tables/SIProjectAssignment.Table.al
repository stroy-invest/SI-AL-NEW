table 60011 "SI Project Assignment"
{
    Caption = 'Призначення на роль проєкту';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Project No."; Code[20])
        {
            Caption = '№ проєкту';
            DataClassification = CustomerContent;
            TableRelation = Job."No." where("SI Construction Project" = const(true));
        }
        field(2; "Line No."; Integer)
        {
            Caption = '№ рядка';
            DataClassification = SystemMetadata;
        }
        field(3; "Role Code"; Code[20])
        {
            Caption = 'Роль';
            DataClassification = CustomerContent;
            TableRelation = "SI Project Role".Code where(Active = const(true), "Assignment Scope" = const(Project));

            trigger OnValidate()
            var
                AssignmentMgt: Codeunit "SI Project Assignment Mgt.";
            begin
                AssignmentMgt.ApplyRoleDefaults(Rec);
                AssignmentMgt.ValidateAssignment(Rec);
            end;
        }
        field(4; "Employee No."; Code[20])
        {
            Caption = '№ працівника';
            DataClassification = CustomerContent;
            TableRelation = Employee."No.";

            trigger OnValidate()
            var
                AssignmentMgt: Codeunit "SI Project Assignment Mgt.";
            begin
                AssignmentMgt.ValidateAssignment(Rec);
            end;
        }
        field(5; "Valid From"; Date)
        {
            Caption = 'Чинний з';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                AssignmentMgt: Codeunit "SI Project Assignment Mgt.";
            begin
                AssignmentMgt.ValidateAssignment(Rec);
            end;
        }
        field(6; "Valid To"; Date)
        {
            Caption = 'Чинний по';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                AssignmentMgt: Codeunit "SI Project Assignment Mgt.";
            begin
                AssignmentMgt.ValidateAssignment(Rec);
            end;
        }
        field(7; Primary; Boolean)
        {
            Caption = 'Основний';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                AssignmentMgt: Codeunit "SI Project Assignment Mgt.";
            begin
                AssignmentMgt.ValidateAssignment(Rec);
            end;
        }
    }

    keys
    {
        key(PK; "Project No.", "Line No.")
        {
            Clustered = true;
        }
        key(RolePeriod; "Project No.", "Role Code", "Valid From")
        {
        }
        key(EmployeeProjects; "Employee No.", "Role Code", "Project No.")
        {
        }
    }

    trigger OnInsert()
    var
        AssignmentMgt: Codeunit "SI Project Assignment Mgt.";
    begin
        AssignmentMgt.ApplyRoleDefaults(Rec);
        AssignmentMgt.ValidateAssignment(Rec);
    end;

    trigger OnModify()
    var
        AssignmentMgt: Codeunit "SI Project Assignment Mgt.";
    begin
        AssignmentMgt.ValidateAssignment(Rec);
    end;
}
