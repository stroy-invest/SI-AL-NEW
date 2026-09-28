page 53016 "SI Wiz. Param. Values"
{
    PageType = ListPart;
    SourceTable = "SI Parameter Value";
    ApplicationArea = All;
    Caption = 'Допустимі значення';

    DelayedInsert = true;
    PopulateAllFields = true;

    SourceTableView =
        sorting(
            "Parameter Code",
            "Sort Order",
            Code);

    layout
    {
        area(Content)
        {
            repeater(Values)
            {
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                    Caption = 'Код';
                    Importance = Promoted;
                    ToolTip = 'Визначає стабільний код значення параметра.';
                }

                field("Display Value"; Rec."Display Value")
                {
                    ApplicationArea = All;
                    Caption = 'Значення';
                    Importance = Promoted;
                    ToolTip = 'Визначає значення, яке бачить користувач.';
                }

                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Назва';
                    ToolTip = 'Визначає пояснювальну назву значення.';
                }

                field("Sort Order"; Rec."Sort Order")
                {
                    ApplicationArea = All;
                    Caption = 'Порядок';
                    ToolTip = 'Визначає порядок відображення значення.';
                }

                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = All;
                    Caption = 'Заблоковано';
                    ToolTip = 'Визначає, чи заборонено використання значення.';
                }
            }
        }
    }

    procedure SetParameterFilter(ParameterCode: Code[30])
    begin
        Rec.Reset();

        if ParameterCode <> '' then
            Rec.SetRange("Parameter Code", ParameterCode)
        else
            Rec.SetRange("Parameter Code", '');

        CurrPage.Update(false);
    end;
}