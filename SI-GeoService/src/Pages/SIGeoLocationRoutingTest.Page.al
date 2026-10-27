page 63003 "SI Geo Location Routing Test"
{
    Caption = 'Тест маршруту зі складу';
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            group(Origin)
            {
                Caption = 'Початок маршруту — склад BC';
                field(LocationCode; LocationCode)
                {
                    ApplicationArea = All;
                    Caption = 'Склад';
                    TableRelation = Location.Code;
                    trigger OnValidate()
                    begin
                        Clear(PointCode);
                        Clear(FromLatitude);
                        Clear(FromLongitude);
                        ClearResults();
                    end;
                }
                field(PointCode; PointCode)
                {
                    ApplicationArea = All;
                    Caption = 'Точка виїзду (порожньо = за замовчуванням)';
                    trigger OnLookup(var Text: Text): Boolean
                    var
                        GeoPoint: Record "SI Geo Location Point";
                        GeoPointsPage: Page "SI Geo Location Points";
                    begin
                        if LocationCode = '' then
                            Error('Спочатку виберіть склад.');
                        GeoPoint.SetRange("Location Code", LocationCode);
                        GeoPoint.SetRange(Active, true);
                        GeoPoint.SetRange(Verified, true);
                        GeoPoint.SetRange("Point Type", GeoPoint."Point Type"::"Exit");
                        GeoPointsPage.SetTableView(GeoPoint);
                        GeoPointsPage.LookupMode(true);
                        if GeoPointsPage.RunModal() = Action::LookupOK then begin
                            GeoPointsPage.GetRecord(GeoPoint);
                            PointCode := GeoPoint."Point Code";
                            Text := PointCode;
                            Clear(FromLatitude);
                            Clear(FromLongitude);
                            ClearResults();
                        end;
                        exit(true);
                    end;
                    trigger OnValidate()
                    begin
                        Clear(FromLatitude);
                        Clear(FromLongitude);
                        ClearResults();
                    end;
                }
                field(FromLatitude; FromLatitude)
                {
                    ApplicationArea = All;
                    Caption = 'Широта виїзду';
                    Editable = false;
                    DecimalPlaces = 0 : 12;
                }
                field(FromLongitude; FromLongitude)
                {
                    ApplicationArea = All;
                    Caption = 'Довгота виїзду';
                    Editable = false;
                    DecimalPlaces = 0 : 12;
                }
            }
            group(Destination)
            {
                Caption = 'Кінець маршруту — тестова точка доставки';
                field(ToLatitude; ToLatitude)
                {
                    ApplicationArea = All;
                    Caption = 'Широта';
                    DecimalPlaces = 0 : 12;
                    trigger OnValidate()
                    begin
                        ClearResults();
                    end;
                }
                field(ToLongitude; ToLongitude)
                {
                    ApplicationArea = All;
                    Caption = 'Довгота';
                    DecimalPlaces = 0 : 12;
                    trigger OnValidate()
                    begin
                        ClearResults();
                    end;
                }
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
                    PointResolver: Codeunit "SI Geo Point Resolver";
                    RoutingTest: Codeunit "SI Geo Routing Test Mgt.";
                begin
                    ClearResults();
                    PointResolver.ResolveOrigin(LocationCode, PointCode, FromLatitude, FromLongitude);
                    RoutingTest.TestRoute(FromLatitude, FromLongitude, ToLatitude, ToLongitude,
                        HttpStatus, ResultText, CorrelationId, DistanceMeters, DurationSeconds);
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
    end;

    local procedure ClearResults()
    begin
        Clear(HttpStatus);
        Clear(ResultText);
        Clear(CorrelationId);
        Clear(DistanceMeters);
        Clear(DurationSeconds);
    end;

    var
        LocationCode: Code[10];
        PointCode: Code[20];
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
