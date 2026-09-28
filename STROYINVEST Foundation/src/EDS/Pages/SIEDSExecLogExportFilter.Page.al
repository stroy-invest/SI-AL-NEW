page 50457 "SI EDS Exec Log Export Filter"
{
    PageType = StandardDialog;
    Caption = 'Експорт журналу EDS в Excel';

    layout
    {
        area(Content)
        {
            group(Filters)
            {
                Caption = 'Фільтри';

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
                field(ServiceCode; ServiceCode)
                {
                    ApplicationArea = All;
                    Caption = 'Код сервісу';
                    TableRelation = "SI EDS Service".Code;
                }
                field(OperationCode; OperationCode)
                {
                    ApplicationArea = All;
                    Caption = 'Код операції';
                }
                field(ProviderCode; ProviderCode)
                {
                    ApplicationArea = All;
                    Caption = 'Код провайдера';
                    TableRelation = "SI EDS Provider".Code;
                }
                field(EndpointCode; EndpointCode)
                {
                    ApplicationArea = All;
                    Caption = 'Код точки під''єднання';
                }
                field(ResultFilter; ResultFilter)
                {
                    ApplicationArea = All;
                    Caption = 'Результат';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        if DateFrom = 0D then
            DateFrom := Today;
        if DateTo = 0D then
            DateTo := Today;
        ResultFilter := ResultFilter::All;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = Action::OK then
            if (DateFrom <> 0D) and (DateTo <> 0D) and (DateFrom > DateTo) then
                Error(DateRangeErr);

        exit(true);
    end;

    procedure GetDateFrom(): Date
    begin
        exit(DateFrom);
    end;

    procedure GetDateTo(): Date
    begin
        exit(DateTo);
    end;

    procedure GetServiceCode(): Code[50]
    begin
        exit(ServiceCode);
    end;

    procedure GetOperationCode(): Code[50]
    begin
        exit(OperationCode);
    end;

    procedure GetProviderCode(): Code[50]
    begin
        exit(ProviderCode);
    end;

    procedure GetEndpointCode(): Code[50]
    begin
        exit(EndpointCode);
    end;

    procedure GetResultFilter(): Enum "SI EDS Exec Log Result Filter"
    begin
        exit(ResultFilter);
    end;

    var
        DateFrom: Date;
        DateTo: Date;
        ServiceCode: Code[50];
        OperationCode: Code[50];
        ProviderCode: Code[50];
        EndpointCode: Code[50];
        ResultFilter: Enum "SI EDS Exec Log Result Filter";
        DateRangeErr: Label 'Дата "з" не може бути пізнішою за дату "по".';
}
