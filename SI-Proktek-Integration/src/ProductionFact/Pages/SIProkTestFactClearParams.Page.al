
page 57181 "SI Prok Test Fact Clear Params"
{
    PageType = StandardDialog;
    Caption = 'Очистити факти Proktek';
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(Period)
            {
                Caption = 'Період виробництва';

                field(DateFrom; DateFrom)
                {
                    ApplicationArea = All;
                    Caption = 'Дата з';
                }
                field(DateTo; DateTo)
                {
                    ApplicationArea = All;
                    Caption = 'Дата по';
                }
            }

            group(StatusFilter)
            {
                Caption = 'Додаткові фільтри';

                field(ProductionIdFilter; ProductionIdFilter)
                {
                    ApplicationArea = All;
                    Caption = 'Production ID';
                    ToolTip = 'Необов’язковий фільтр за ідентифікатором виробництва Proktek. Значення 0 означає всі виробництва за період.';
                }

                field(FilterByStatus; FilterByStatus)
                {
                    ApplicationArea = All;
                    Caption = 'Фільтрувати за статусом';
                }

                field(FactStatus; FactStatus)
                {
                    ApplicationArea = All;
                    Caption = 'Статус';
                    Enabled = FilterByStatus;
                }
            }

            group(Scope)
            {
                Caption = 'Обмеження';

                field(CaptureMode; CaptureMode)
                {
                    ApplicationArea = All;
                    Caption = 'Режим приймання';
                    ToolTip = 'Виберіть Тест або Звичайний. Очищення звичайних фактів дозволяється лише в Sandbox.';
                }
            }
        }
    }

    procedure SetDefaults(NewDateFrom: Date; NewDateTo: Date)
    begin
        DateFrom := NewDateFrom;
        DateTo := NewDateTo;
        CaptureMode := CaptureMode::Test;
        ProductionIdFilter := 0;
        FilterByStatus := false;
    end;

    procedure GetDateFrom(): Date
    begin
        exit(DateFrom);
    end;

    procedure GetDateTo(): Date
    begin
        exit(DateTo);
    end;

    procedure GetFilterByStatus(): Boolean
    begin
        exit(FilterByStatus);
    end;

    procedure GetStatus(): Enum "SI Prok Prod Fact Status"
    begin
        exit(FactStatus);
    end;

    procedure GetCaptureMode(): Enum "SI Prok Capture Mode"
    begin
        exit(CaptureMode);
    end;

    procedure GetProductionIdFilter(): BigInteger
    begin
        exit(ProductionIdFilter);
    end;

    var
        DateFrom: Date;
        DateTo: Date;
        FilterByStatus: Boolean;
        FactStatus: Enum "SI Prok Prod Fact Status";
        CaptureMode: Enum "SI Prok Capture Mode";
        ProductionIdFilter: BigInteger;
}
