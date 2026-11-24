table 53014 "SI Parameter Value Attr."
{
    Caption = 'Додаткові характеристики значень';
    DataClassification = CustomerContent;
    fields
    {
        field(1; "Parameter Code"; Code[30]) { Caption = 'Код параметра'; TableRelation = "SI Product Parameter".Code; NotBlank = true; }
        field(2; "Value Code"; Code[30]) { Caption = 'Код значення'; TableRelation = "SI Parameter Value".Code where("Parameter Code" = field("Parameter Code")); }
        field(3; "Attribute Code"; Code[30]) { Caption = 'Характеристика'; TableRelation = "SI Value Attr. Definition".Code where("Parameter Code" = field("Parameter Code")); }
        field(10; "Decimal Value"; Decimal) { Caption = 'Десяткове значення';  }
        field(11; "Integer Value"; Integer) { Caption = 'Ціле значення';  }
        field(12; "Text Value"; Text[250]) { Caption = 'Текст';  }
        field(13; "Boolean Value"; Boolean) { Caption = 'Так/Ні';  }
        field(14; "Has Minimum"; Boolean) { Caption = 'Є нижня межа';  }
        field(15; "Minimum"; Decimal) { Caption = 'Нижня межа';  }
        field(16; "Has Maximum"; Boolean) { Caption = 'Є верхня межа';  }
        field(17; "Maximum"; Decimal) { Caption = 'Верхня межа';  }
    }
    keys { key(PK; "Parameter Code", "Value Code", "Attribute Code") { Clustered = true; } }
    trigger OnInsert()
    begin
        CheckData();
    end;
    trigger OnModify()
    begin
        CheckData();
    end;
    trigger OnRename()
    begin
        Error('Зміна ключа характеристики не дозволена.');
    end;
    trigger OnDelete()
    var
        Parent: Record "SI Parameter Value";
    begin
        if Parent.Get("Parameter Code", "Value Code") then
            Parent.TestField("Ever Used", false);
    end;
    local procedure CheckData()
    var
        Parent: Record "SI Parameter Value";
        Def: Record "SI Value Attr. Definition";
    begin
        Parent.Get("Parameter Code", "Value Code");
        Def.Get("Parameter Code", "Attribute Code");
        if Def."Value Type" = Def."Value Type"::Range then begin
            if not ("Has Minimum" or "Has Maximum") then
                Error('Задайте хоча б одну межу діапазону.');
            if "Has Minimum" and "Has Maximum" and (Minimum > Maximum) then
                Error('Нижня межа перевищує верхню.');
        end;
    end;
}
