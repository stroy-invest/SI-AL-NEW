table 63202 "SI Vehicle Capacity Type"
{
    Caption = 'Тип характеристики місткості';
    DataClassification = CustomerContent;
    LookupPageId = "SI Vehicle Capacity Types";
    fields
    {
        field(1; Code; Code[20]) { Caption = 'Код'; NotBlank = true; }
        field(2; Description; Text[100]) { Caption = 'Найменування'; }
        field(3; "Required Semantic Code"; Code[30])
        {
            Caption = 'Семантичний профіль';
            TableRelation = "SI UoM Semantic Profile".Code where(Blocked = const(false), "Is Package" = const(false));
            trigger OnValidate()
            var Mgt: Codeunit "SI Vehicle Management";
            begin
                TestField("Required Semantic Code");
                Mgt.ValidateCapacityTypeDependents(Rec);
            end;
        }
        field(4; Blocked; Boolean) { Caption = 'Заблоковано'; }
    }
    keys { key(PK; Code) { Clustered = true; } }
    trigger OnModify()
    var Mgt: Codeunit "SI Vehicle Management";
    begin
        Mgt.ValidateCapacityTypeDependents(Rec);
    end;
}
