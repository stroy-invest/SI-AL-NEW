table 60014 "SI Site Assignment"
{
    Caption = 'Призначення на будівельний майданчик';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Project No."; Code[20])
        {
            Caption = '№ проєкту';
            DataClassification = CustomerContent;
            TableRelation = Job."No." where("SI Construction Project" = const(true));
        }
        field(2; "Site Code"; Code[20])
        {
            Caption = 'Код майданчика';
            DataClassification = CustomerContent;
            TableRelation = "SI Construction Site"."Site Code" where("Project No." = field("Project No."));
        }
        field(3; "Line No."; Integer)
        {
            Caption = '№ рядка';
            DataClassification = SystemMetadata;
        }
        field(4; "Role Code"; Code[20])
        {
            Caption = 'Роль';
            DataClassification = CustomerContent;
            TableRelation = "SI Project Role".Code where(Active = const(true), "Assignment Scope" = const(Site));
        }
        field(5; "Employee No."; Code[20])
        {
            Caption = '№ працівника';
            DataClassification = CustomerContent;
            TableRelation = Employee."No.";

            trigger OnValidate()
            var
                AssignmentMgt: Codeunit "SI Site Assignment Mgt.";
            begin
                AssignmentMgt.ValidateAssignment(Rec);
            end;
        }
        field(6; "Valid From"; Date)
        {
            Caption = 'Чинний з';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                AssignmentMgt: Codeunit "SI Site Assignment Mgt.";
            begin
                AssignmentMgt.ValidateAssignment(Rec);
            end;
        }
        field(7; "Valid To"; Date)
        {
            Caption = 'Чинний по';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                AssignmentMgt: Codeunit "SI Site Assignment Mgt.";
            begin
                AssignmentMgt.ValidateAssignment(Rec);
            end;
        }
        field(8; Primary; Boolean)
        {
            Caption = 'Основний';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                AssignmentMgt: Codeunit "SI Site Assignment Mgt.";
            begin
                AssignmentMgt.ValidateAssignment(Rec);
            end;
        }
    }

    keys
    {
        key(PK; "Project No.", "Site Code", "Line No.") { Clustered = true; }
        key(RolePeriod; "Project No.", "Site Code", "Role Code", "Valid From") { }
        key(EmployeeSites; "Employee No.", "Role Code", "Project No.", "Site Code") { }
    }

    trigger OnInsert()
    var
        AssignmentMgt: Codeunit "SI Site Assignment Mgt.";
    begin
        AssignmentMgt.ValidateAssignment(Rec);
    end;

    trigger OnModify()
    var
        AssignmentMgt: Codeunit "SI Site Assignment Mgt.";
    begin
        AssignmentMgt.ValidateAssignment(Rec);
    end;
}
