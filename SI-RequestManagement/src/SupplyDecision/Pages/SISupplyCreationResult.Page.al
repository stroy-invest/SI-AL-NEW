page 52051 "SI Supply Creation Result"
{
    PageType = StandardDialog;
    ApplicationArea = All;
    Caption = 'Створення документів';

    layout
    {
        area(Content)
        {
            group(Result)
            {
                Caption = 'Результат';

                field(ProductionResult; ProductionResult)
                {
                    ApplicationArea = All;
                    Caption = 'Виробничі замовлення';
                    Editable = false;
                    StyleExpr = ProductionStyle;
                }
                field(PurchaseResult; PurchaseResult)
                {
                    ApplicationArea = All;
                    Caption = 'Замовлення на закупівлю';
                    Editable = false;
                }
                field(TransferResult; TransferResult)
                {
                    ApplicationArea = All;
                    Caption = 'Ордери на переміщення';
                    Editable = false;
                }
                field(SummaryText; SummaryText)
                {
                    ApplicationArea = All;
                    Caption = 'Підсумок';
                    Editable = false;
                    MultiLine = true;
                    StyleExpr = SummaryStyle;
                }
                field(ErrorText; ErrorText)
                {
                    ApplicationArea = All;
                    Caption = 'Помилка';
                    Editable = false;
                    MultiLine = true;
                    Visible = HasError;
                    Style = Unfavorable;
                }
            }
        }
    }

    procedure SetSuccess(CreatedCount: Integer)
    begin
        ProductionResult := StrSubstNo(SuccessResultLbl, CreatedCount);
        ProductionStyle := 'Favorable';
        PurchaseResult := NotRequiredLbl;
        TransferResult := NotRequiredLbl;
        SummaryText := SuccessSummaryLbl;
        SummaryStyle := 'Favorable';
        HasError := false;
        ErrorText := '';
    end;

    procedure SetError(NewErrorText: Text)
    begin
        ProductionResult := ErrorResultLbl;
        ProductionStyle := 'Unfavorable';
        PurchaseResult := NotRequiredLbl;
        TransferResult := NotRequiredLbl;
        SummaryText := ErrorSummaryLbl;
        SummaryStyle := 'Unfavorable';
        HasError := true;
        ErrorText := CopyStr(NewErrorText, 1, MaxStrLen(ErrorText));
    end;

    var
        ProductionResult: Text[100];
        PurchaseResult: Text[100];
        TransferResult: Text[100];
        SummaryText: Text[250];
        ErrorText: Text[2048];
        ProductionStyle: Text;
        SummaryStyle: Text;
        HasError: Boolean;

        SuccessResultLbl: Label 'OK. Створено: %1';
        ErrorResultLbl: Label 'Помилка';
        NotRequiredLbl: Label 'Не потрібно';
        SuccessSummaryLbl: Label 'Усі необхідні документи успішно створено.';
        ErrorSummaryLbl: Label 'Під час створення документів сталася помилка.';
}
