table 60012 "SI Employee Project Role"
{
    Caption = 'Допустима роль працівника в будівельних проєктах';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Employee No."; Code[20])
        {
            Caption = '№ працівника';
            DataClassification = CustomerContent;
            TableRelation = Employee."No.";

            trigger OnValidate()
            var
                Employee: Record Employee;
            begin
                if ("Employee No." <> '') and not Employee.Get("Employee No.") then
                    Error('Працівник %1 не існує.', "Employee No.");
            end;
        }
        field(2; "Role Code"; Code[20])
        {
            Caption = 'Роль';
            DataClassification = CustomerContent;
            TableRelation = "SI Project Role".Code where(Active = const(true));

            trigger OnValidate()
            var
                ProjectRole: Record "SI Project Role";
            begin
                if "Role Code" = '' then
                    exit;
                if not ProjectRole.Get("Role Code") then
                    Error('Роль проєкту %1 не існує.', "Role Code");
                if not ProjectRole.Active then
                    Error('Роль проєкту "%1" неактивна.', ProjectRole.Description);
            end;
        }
    }

    keys
    {
        key(PK; "Employee No.", "Role Code")
        {
            Clustered = true;
        }
        key(RoleEmployees; "Role Code", "Employee No.")
        {
        }
    }
}
