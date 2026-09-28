page 59106 "SI WB Conversion Panel"
{
    PageType = CardPart;
    SourceTable = "SI Weighbridge Document Line";

    ApplicationArea = All;
    UsageCategory = None;

    Caption = 'Перерахунок';

    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            grid(Conversion)
            {
                GridLayout = Columns;

                field(SourceDisplay; SourceDisplay)
                {
                    ApplicationArea = All;
                    Caption = 'Джерело';
                    Editable = false;
                }

                field(FactorDisplay; FactorDisplay)
                {
                    ApplicationArea = All;
                    Caption = 'Коефіцієнт';
                    Editable = false;
                }

                field(ResultDisplay; ResultDisplay)
                {
                    ApplicationArea = All;
                    Caption = 'Результат';
                    Editable = false;
                }

                field("UoM Error Text"; Rec."UoM Error Text")
                {
                    ApplicationArea = All;
                    Caption = 'Помилка';
                    Editable = false;
                    Visible = ErrorVisible;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        LoadDisplayValues();
    end;

    local procedure LoadDisplayValues()
    begin
        Clear(SourceDisplay);
        Clear(FactorDisplay);
        Clear(ResultDisplay);

        SourceDisplay :=
            GetSourceDisplay();

        if Rec."Conversion Factor" <> 0 then
            FactorDisplay :=
                CopyStr(
                    StrSubstNo(
                        '%1 %2',
                        Format(Rec."Conversion Factor"),
                        Rec."Conversion Factor UoM Code"),
                    1,
                    MaxStrLen(FactorDisplay));

        if Rec."Unit of Measure Code" <> '' then
            ResultDisplay :=
                CopyStr(
                    StrSubstNo(
                        '%1 %2 → %3 %4',
                        Format(Rec."Allocated Weight"),
                        Rec."Weight UoM Code",
                        Format(Rec.Quantity),
                        Rec."Unit of Measure Code"),
                    1,
                    MaxStrLen(ResultDisplay));

        ErrorVisible :=
            Rec."UoM Error Text" <> '';
    end;

    local procedure GetSourceDisplay(): Text[100]
    begin
        case Rec."Conversion Source Type" of
            'DIRECT_SCALED':
                exit('Прямий / масштабований');

            'ITEM_ATTRIBUTE':
                exit('Атрибут товару');

            'PRODUCT_CONFIG':
                exit('Конфігурація товару');

            '':
                exit('');

            else
                exit(
                    CopyStr(
                        Rec."Conversion Source Type",
                        1,
                        100));
        end;
    end;

    var
        SourceDisplay: Text[100];
        FactorDisplay: Text[100];
        ResultDisplay: Text[150];
        ErrorVisible: Boolean;
}
