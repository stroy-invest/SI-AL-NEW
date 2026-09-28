page 53031 "SI Semantic Parameters Part"
{
    PageType = ListPart;
    SourceTable = "SI Product Config. Value";
    Caption = 'Параметри';
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Parameters)
            {
                field(ParameterDescription; ParameterDescription)
                {
                    ApplicationArea = All;
                    Caption = 'Параметр';
                }

                field(DisplayValue; Rec."Display Value")
                {
                    ApplicationArea = All;
                    Caption = 'Значення';
                }

                field(UnitOfMeasureCode; UnitOfMeasureCode)
                {
                    ApplicationArea = All;
                    Caption = 'Одиниця виміру';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        LoadParameterPresentation();
    end;

    local procedure LoadParameterPresentation()
    var
        ProductParameter: Record "SI Product Parameter";
    begin
        Clear(ParameterDescription);
        Clear(UnitOfMeasureCode);

        if not ProductParameter.Get(Rec."Parameter Code") then begin
            ParameterDescription := Rec."Parameter Code";
            exit;
        end;

        ParameterDescription := ProductParameter.Description;
        if ParameterDescription = '' then
            ParameterDescription := ProductParameter.Code;

        UnitOfMeasureCode := ProductParameter."Unit of Measure Code";
    end;

    var
        ParameterDescription: Text[100];
        UnitOfMeasureCode: Code[10];
}
