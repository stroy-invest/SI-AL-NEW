namespace STROYINVEST.ConcreteRecipeEngine;

page 62108 "SI Recipe Resolve Date"
{
    PageType = StandardDialog;
    Caption = 'Визначити ревізії рецептури';

    layout
    {
        area(Content)
        {
            group(Options)
            {
                field(TargetDateField; TargetDate)
                {
                    ApplicationArea = All;
                    Caption = 'Цільова дата';
                    ToolTip = 'Вказує дату, на яку визначатимуться актуальні сертифіковані ревізії рецептур.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        if TargetDate = 0D then
            TargetDate := Today();
    end;

    procedure SetTargetDate(NewTargetDate: Date)
    begin
        TargetDate := NewTargetDate;
    end;

    procedure GetTargetDate(): Date
    begin
        exit(TargetDate);
    end;

    var
        TargetDate: Date;
}
