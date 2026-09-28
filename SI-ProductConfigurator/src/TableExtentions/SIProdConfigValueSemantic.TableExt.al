tableextension 53001 "SI Prod. Config. Value Sem." extends "SI Product Config. Value"
{
    fields
    {
        field(53000; "SI Family Code"; Code[30])
        {
            Caption = 'Код сімейства';
            FieldClass = FlowField;
            CalcFormula = lookup("SI Product Config."."Family Code" where("No." = field("Configuration No.")));
            Editable = false;
        }

        field(53001; "SI ERP Projection Role"; Enum "SI ERP Projection Role")
        {
            Caption = 'Роль в ERP-проєкції';
            FieldClass = FlowField;
            CalcFormula = lookup("SI Family Parameter"."ERP Projection Role" where("Family Code" = field("SI Family Code"), "Parameter Code" = field("Parameter Code")));
            Editable = false;
        }
    }
}
