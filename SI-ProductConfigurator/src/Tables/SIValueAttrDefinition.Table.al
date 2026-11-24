table 53013 "SI Value Attr. Definition"
{
    Caption = 'Визначення характеристик значень';
    DataClassification = CustomerContent;
    fields
    {
        field(1; "Parameter Code"; Code[30]) { Caption = 'Код параметра'; TableRelation = "SI Product Parameter".Code; NotBlank = true; }
        field(2; "Code"; Code[30]) { Caption = 'Код характеристики'; NotBlank = true; }
        field(3; "Description"; Text[100]) { Caption = 'Назва'; NotBlank = true; }
        field(4; "Value Type"; Enum "SI Value Attr. Type") { Caption = 'Тип даних';  }
        field(5; "Semantic Code"; Code[50]) { Caption = 'Семантика'; TableRelation = "SI Attribute Semantic".Code; }
        field(6; "UoM Code"; Code[10]) { Caption = 'Одиниця виміру'; TableRelation = "Unit of Measure".Code; }
        field(7; "Sort Order"; Integer) { Caption = 'Порядок'; MinValue = 0; }
    }
    keys { key(PK; "Parameter Code", Code) { Clustered = true; } key(DisplayOrder; "Parameter Code", "Sort Order", Code) { } }
    trigger OnInsert()
    begin
        CheckSetup();
    end;
    trigger OnModify()
    begin
        CheckSetup();
        if "Value Type" <> xRec."Value Type" then
            CheckUnused();
    end;
    trigger OnDelete()
    begin
        CheckUnused();
    end;
    trigger OnRename()
    begin
        xRec.CheckUnused();
    end;
    local procedure CheckSetup()
    var
        Param: Record "SI Product Parameter";
    begin
        TestField(Code);
        TestField(Description);
        Param.Get("Parameter Code");
        Param.TestField("Value Type", Param."Value Type"::"Controlled Value");
    end;
    procedure CheckUnused()
    var
        Attr: Record "SI Parameter Value Attr.";
    begin
        Attr.SetRange("Parameter Code", "Parameter Code");
        Attr.SetRange("Attribute Code", Code);
        if not Attr.IsEmpty() then
            Error('Характеристика вже використовується.');
    end;
}
