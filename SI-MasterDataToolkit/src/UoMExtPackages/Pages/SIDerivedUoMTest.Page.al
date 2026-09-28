page 58006 "SI Derived UoM Test"
{
    PageType = StandardDialog;
    ApplicationArea = All;
    Caption = 'Перевірка похідної одиниці';

    layout
    {
        area(Content)
        {
            group(Setup)
            {
                Caption = 'Вхідні дані';

                field(DerivedUoMCodeField; DerivedUoMCode)
                {
                    ApplicationArea = All;
                    Caption = 'Похідна одиниця';
                    Editable = false;
                    ToolTip = 'Показує похідну одиницю вимірювання, для якої виконується тестовий розрахунок.';
                }
                field(DerivedValueField; DerivedValue)
                {
                    ApplicationArea = All;
                    Caption = 'Значення похідної величини';
                    DecimalPlaces = 0 : 10;
                    ToolTip = 'Визначає значення похідної величини, наприклад 14 для витрати 14 л/100 км.';
                }
                field(RelatedQuantityField; RelatedQuantity)
                {
                    ApplicationArea = All;
                    Caption = 'Кількість знаменника';
                    DecimalPlaces = 0 : 10;
                    ToolTip = 'Визначає фактичну кількість величини знаменника, наприклад 247 км.';
                }
                field(RelatedUoMCodeField; RelatedUoMCode)
                {
                    ApplicationArea = All;
                    Caption = 'Одиниця знаменника';
                    TableRelation = "Unit of Measure".Code;
                    ToolTip = 'Визначає одиницю фактичної кількості знаменника. За потреби вона буде перерахована в одиницю знаменника похідної UoM.';
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        DerivedUoMCalc: Codeunit "SI Derived UoM Calc.";
    begin
        if DerivedUoMCode = '' then
            Error(DerivedUoMRequiredErr);

        if RelatedUoMCode = '' then
            RelatedUoMCode := DerivedUoMCalc.GetDenominatorUoMCode(DerivedUoMCode);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        DerivedUoMCalc: Codeunit "SI Derived UoM Calc.";
        ResultQuantity: Decimal;
        ResultUoMCode: Code[10];
    begin
        if CloseAction <> Action::OK then
            exit(true);

        if RelatedUoMCode = '' then
            Error(RelatedUoMRequiredErr);

        ResultUoMCode := DerivedUoMCalc.GetNumeratorUoMCode(DerivedUoMCode);
        ResultQuantity := DerivedUoMCalc.CalculateNumeratorQuantity(
            DerivedValue,
            DerivedUoMCode,
            RelatedQuantity,
            RelatedUoMCode,
            ResultUoMCode);

        Message(
            ResultMsg,
            Format(DerivedValue, 0, '<Precision,0:10><Standard Format,0>'),
            DerivedUoMCode,
            Format(RelatedQuantity, 0, '<Precision,0:10><Standard Format,0>'),
            RelatedUoMCode,
            Format(ResultQuantity, 0, '<Precision,0:10><Standard Format,0>'),
            ResultUoMCode);

        exit(true);
    end;

    procedure SetDerivedUoMCode(NewDerivedUoMCode: Code[10])
    begin
        DerivedUoMCode := NewDerivedUoMCode;
    end;

    var
        DerivedUoMCode: Code[10];
        RelatedUoMCode: Code[10];
        DerivedValue: Decimal;
        RelatedQuantity: Decimal;
        DerivedUoMRequiredErr: Label 'Не задано похідну одиницю вимірювання для перевірки.';
        RelatedUoMRequiredErr: Label 'Не задано одиницю знаменника для тестового розрахунку.';
        ResultMsg: Label '%1 %2 × %3 %4 = %5 %6';
}
