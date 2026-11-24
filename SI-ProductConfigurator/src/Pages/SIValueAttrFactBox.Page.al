page 53041 "SI Value Attr. FactBox"
{
    PageType = ListPart;
    SourceTable = "SI Category Attribute Buffer";
    SourceTableTemporary = true;
    ApplicationArea = All;
    Caption = 'Додаткові характеристики';
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Attributes)
            {
                field(AttributeName; Rec."Attribute Name")
                {
                    ApplicationArea = All;
                    Caption = 'Назва';
                }
                field(DisplayValue; Rec."Display Value")
                {
                    ApplicationArea = All;
                    Caption = 'Значення';
                }
            }
        }
    }

    procedure LoadAttributes(ParameterCode: Code[30]; ValueCode: Code[30])
    var
        Parent: Record "SI Parameter Value";
        Def: Record "SI Value Attr. Definition";
        Attr: Record "SI Parameter Value Attr.";
        Resolver: Codeunit "SI Value Attr. Resolver";
        EntryNo: Integer;
        ValueText: Text;
    begin
        Rec.Reset();
        Rec.DeleteAll();
        // Administrative view: blocked values remain visible for inspection.
        if (ParameterCode <> '') and (ValueCode <> '') then
            if Parent.Get(ParameterCode, ValueCode) then begin
                Def.SetCurrentKey("Parameter Code", "Sort Order", Code);
                Def.SetRange("Parameter Code", ParameterCode);
                if Def.FindSet() then
                    repeat
                        if Attr.Get(ParameterCode, ValueCode, Def.Code) then begin
                            ValueText := Resolver.FormatAttribute(Attr, Def."Value Type");
                            if (ValueText <> '') and (Def."UoM Code" <> '') then
                                ValueText := ValueText + ' ' + Def."UoM Code";
                            EntryNo += 1;
                            Rec.Init();
                            Rec."Entry No." := EntryNo;
                            Rec."Attribute Name" := CopyStr(Def.Description, 1, MaxStrLen(Rec."Attribute Name"));
                            Rec."Display Value" := CopyStr(ValueText, 1, MaxStrLen(Rec."Display Value"));
                            Rec.Insert();
                        end;
                    until Def.Next() = 0;
            end;
        if Rec.FindFirst() then;
        CurrPage.Update(false);
    end;
}
