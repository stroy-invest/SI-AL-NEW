page 57200 "SI Prok TC01 Order Dialog"
{
    PageType = StandardDialog;
    Caption = 'TC-01: Вибір тестового замовлення';
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(Selection)
            {
                Caption = 'Параметри тесту';
                field(OrderNoInput; OrderNo)
                {
                    ApplicationArea = All;
                    Caption = 'Order No.';
                    ToolTip = 'Повний Order No. заявки Proktek, для якої потрібно оновити п’ять тестових фактів.';
                    ShowMandatory = true;
                }
            }
        }
    }

    procedure GetOrderNo(): Text[150]
    begin
        exit(OrderNo);
    end;

    var
        OrderNo: Text[150];
}
