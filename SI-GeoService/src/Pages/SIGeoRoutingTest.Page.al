page 63002 "SI Geo Routing Test"
{
    Caption = 'Тест маршрутизації Geoapify';
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    layout
    {
        area(Content)
        {
            group(Origin)
            {
                Caption = 'Початок маршруту';
                field(FromLatitude; FromLatitude) { ApplicationArea = All; Caption = 'Широта'; DecimalPlaces = 0 : 12; }
                field(FromLongitude; FromLongitude) { ApplicationArea = All; Caption = 'Довгота'; DecimalPlaces = 0 : 12; }
            }
            group(Destination)
            {
                Caption = 'Кінець маршруту';
                field(ToLatitude; ToLatitude) { ApplicationArea = All; Caption = 'Широта'; DecimalPlaces = 0 : 12; }
                field(ToLongitude; ToLongitude) { ApplicationArea = All; Caption = 'Довгота'; DecimalPlaces = 0 : 12; }
            }
            group(Result)
            {
                Caption = 'Результат';
                field(HttpStatus; HttpStatus) { ApplicationArea = All; Caption = 'HTTP статус'; Editable = false; }
                field(ResultText; ResultText) { ApplicationArea = All; Caption = 'Результат EDS'; Editable = false; }
                field(CorrelationId; CorrelationId) { ApplicationArea = All; Caption = 'Correlation ID'; Editable = false; }
                field(DistanceMeters; DistanceMeters) { ApplicationArea = All; Caption = 'Відстань, м'; Editable = false; }
                field(DurationSeconds; DurationSeconds) { ApplicationArea = All; Caption = 'Час, с'; Editable = false; }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(RunRoute)
            {
                ApplicationArea = All;
                Caption = 'Розрахувати маршрут';
                Image = Calculate;
                Promoted = true;
                PromotedCategory = Process;
                trigger OnAction()
                var
                    RoutingTest: Codeunit "SI Geo Routing Test Mgt.";
                begin
                    Clear(HttpStatus);
                    Clear(ResultText);
                    Clear(CorrelationId);
                    Clear(DistanceMeters);
                    Clear(DurationSeconds);
                    RoutingTest.TestRoute(FromLatitude, FromLongitude, ToLatitude, ToLongitude,
                        HttpStatus, ResultText, CorrelationId, DistanceMeters, DurationSeconds, UnusedGeoJson);
                    CurrPage.Update(false);
                end;
            }
        }
    }
    trigger OnOpenPage()
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        if not EnvironmentInformation.IsSandbox() then
            Error('Сторінка тестування доступна лише в Sandbox.');
        FromLatitude := 48.48249342331394;
        FromLongitude := 35.080141980922306;
        ToLatitude := 48.4772417;
        ToLongitude := 35.0889962;
    end;
    var
        UnusedGeoJson: Text;
        FromLatitude: Decimal;
        FromLongitude: Decimal;
        ToLatitude: Decimal;
        ToLongitude: Decimal;
        HttpStatus: Integer;
        ResultText: Text[100];
        CorrelationId: Guid;
        DistanceMeters: Decimal;
        DurationSeconds: Decimal;
}
