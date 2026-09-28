table 53011 "SI Family Template Parameter"
{
    Caption = 'Параметр шаблону сімейства';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Template Code"; Code[30])
        {
            Caption = 'Код шаблону сімейства';
            DataClassification = CustomerContent;
            NotBlank = true;
            TableRelation = "SI Product Family Template".Code;
        }
        field(2; "Parameter Code"; Code[30])
        {
            Caption = 'Код параметра';
            DataClassification = CustomerContent;
            NotBlank = true;
            TableRelation = "SI Product Parameter".Code where(Blocked = const(false));
        }
        field(10; "Parameter Order"; Integer) { Caption = 'Порядок параметра'; DataClassification = CustomerContent; MinValue = 0; }
        field(20; Mandatory; Boolean) { Caption = 'Обов’язковий'; DataClassification = CustomerContent; }
        field(40; "ERP Projection Role"; Enum "SI ERP Projection Role") { Caption = 'Роль в ERP-проєкції'; DataClassification = CustomerContent; }
        field(50; "Include in Description"; Boolean) { Caption = 'Входить у назву'; DataClassification = CustomerContent; }
        field(60; "Description Order"; Integer) { Caption = 'Порядок у назві'; DataClassification = CustomerContent; MinValue = 0; }
        field(90; "Include in Search"; Boolean) { Caption = 'Входить у пошук'; DataClassification = CustomerContent; }
        field(100; "Recipe Relevant"; Boolean) { Caption = 'Значущий для рецептури'; DataClassification = CustomerContent; }
        field(110; "Default Value Code"; Code[30])
        {
            Caption = 'Значення за замовчуванням';
            DataClassification = CustomerContent;
            TableRelation = "SI Parameter Value".Code where("Parameter Code" = field("Parameter Code"));
        }
        field(120; Blocked; Boolean) { Caption = 'Заблоковано'; DataClassification = CustomerContent; }
    }

    keys
    {
        key(PK; "Template Code", "Parameter Code") { Clustered = true; }
        key(ParameterOrder; "Template Code", "Parameter Order", "Parameter Code") { }
    }
}
