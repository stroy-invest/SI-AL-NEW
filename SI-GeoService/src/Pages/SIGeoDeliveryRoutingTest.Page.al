page 63005 "SI Geo Delivery Routing Test"
{
    Caption = 'Тест маршруту до адреси доставки';
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    layout
    {
        area(Content)
        {
            group(Origin)
            {
                Caption = 'Відправлення — склад';
                field(LocationCode; LocationCode)
                {
                    ApplicationArea = All;
                    Caption = 'Склад';
                    TableRelation = Location.Code;
                    trigger OnValidate()
                    begin
                        Clear(OriginPointCode);
                        ClearResults();
                    end;
                }
                field(OriginPointCode; OriginPointCode)
                {
                    ApplicationArea = All;
                    Caption = 'Точка виїзду (порожньо = за замовчуванням)';
                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Point: Record "SI Geo Location Point";
                        PointPage: Page "SI Geo Location Points";
                    begin
                        if LocationCode = '' then
                            Error('Спочатку виберіть склад.');
                        Point.SetRange("Location Code", LocationCode);
                        Point.SetRange(Active, true);
                        Point.SetRange(Verified, true);
                        Point.SetRange("Point Type", Point."Point Type"::"Exit");
                        PointPage.SetTableView(Point);
                        PointPage.LookupMode(true);
                        if PointPage.RunModal() = Action::LookupOK then begin
                            PointPage.GetRecord(Point);
                            OriginPointCode := Point."Point Code";
                            Text := OriginPointCode;
                            ClearResults();
                        end;
                        exit(true);
                    end;
                    trigger OnValidate()
                    begin
                        ClearResults();
                    end;
                }
                field(FromLatitude; FromLatitude) { ApplicationArea = All; Caption = 'Широта виїзду'; Editable = false; DecimalPlaces = 0 : 12; }
                field(FromLongitude; FromLongitude) { ApplicationArea = All; Caption = 'Довгота виїзду'; Editable = false; DecimalPlaces = 0 : 12; }
            }
            group(Destination)
            {
                Caption = 'Призначення — стандартна адреса доставки';
                field(CustomerNo; CustomerNo)
                {
                    ApplicationArea = All;
                    Caption = 'Клієнт';
                    TableRelation = Customer."No.";
                    trigger OnValidate()
                    begin
                        Clear(ShipToCode);
                        Clear(DestinationPointCode);
                        ClearResults();
                    end;
                }
                field(ShipToCode; ShipToCode)
                {
                    ApplicationArea = All;
                    Caption = 'Адреса доставки';
                    trigger OnLookup(var Text: Text): Boolean
                    var
                        ShipTo: Record "Ship-to Address";
                    begin
                        if CustomerNo = '' then
                            Error('Спочатку виберіть клієнта.');
                        ShipTo.SetRange("Customer No.", CustomerNo);
                        if Page.RunModal(Page::"Ship-to Address List", ShipTo) = Action::LookupOK then begin
                            ShipToCode := ShipTo.Code;
                            Text := ShipToCode;
                            Clear(DestinationPointCode);
                            ClearResults();
                        end;
                        exit(true);
                    end;
                    trigger OnValidate()
                    begin
                        Clear(DestinationPointCode);
                        ClearResults();
                    end;
                }
                field(DestinationPointCode; DestinationPointCode)
                {
                    ApplicationArea = All;
                    Caption = 'Точка доставки (порожньо = за замовчуванням)';
                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Point: Record "SI Geo Ship-to Point";
                        PointPage: Page "SI Geo Ship-to Points";
                    begin
                        if (CustomerNo = '') or (ShipToCode = '') then
                            Error('Спочатку виберіть клієнта та адресу доставки.');
                        Point.SetRange("Customer No.", CustomerNo);
                        Point.SetRange("Ship-to Code", ShipToCode);
                        Point.SetRange(Active, true);
                        Point.SetRange(Verified, true);
                        PointPage.SetTableView(Point);
                        PointPage.LookupMode(true);
                        if PointPage.RunModal() = Action::LookupOK then begin
                            PointPage.GetRecord(Point);
                            DestinationPointCode := Point."Point Code";
                            Text := DestinationPointCode;
                            ClearResults();
                        end;
                        exit(true);
                    end;
                    trigger OnValidate()
                    begin
                        ClearResults();
                    end;
                }
                field(ToLatitude; ToLatitude) { ApplicationArea = All; Caption = 'Широта доставки'; Editable = false; DecimalPlaces = 0 : 12; }
                field(ToLongitude; ToLongitude) { ApplicationArea = All; Caption = 'Довгота доставки'; Editable = false; DecimalPlaces = 0 : 12; }
            }
            group(RouteVisualization)
            {
                Caption = 'Карта маршруту';
                usercontrol(RouteMap; "SI Geo Route Map")
                {
                    ApplicationArea = All;
                    trigger ControlReady()
                    begin
                        MapReady := true;
                        if RouteDisplayRequested and (RouteGeoJson <> '') then
                            CurrPage.RouteMap.RenderRoute(RouteGeoJson, FromLatitude, FromLongitude, ToLatitude, ToLongitude);
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
            action(ShowRoute)
            {
                ApplicationArea = All;
                Caption = 'Показати маршрут';
                Image = Map;
                Promoted = true;
                PromotedCategory = Process;
                trigger OnAction()
                begin
                    if RouteGeoJson = '' then
                        Error('Спочатку розрахуйте маршрут.');
                    RouteDisplayRequested := true;
                    if MapReady then
                        CurrPage.RouteMap.RenderRoute(RouteGeoJson, FromLatitude, FromLongitude, ToLatitude, ToLongitude);
                    // If the add-in is still starting, ControlReady renders the pending route.
                    // No error and no repeated clicks are required.
                end;
            }
            action(RunRoute)
            {
                ApplicationArea = All;
                Caption = 'Розрахувати маршрут';
                Image = Calculate;
                Promoted = true;
                PromotedCategory = Process;
                trigger OnAction()
                var
                    OriginResolver: Codeunit "SI Geo Point Resolver";
                    DestinationResolver: Codeunit "SI Geo Ship-to Resolver";
                    Routing: Codeunit "SI Geo Routing Test Mgt.";
                begin
                    ClearResults();
                    OriginResolver.ResolveOrigin(LocationCode, OriginPointCode, FromLatitude, FromLongitude);
                    DestinationResolver.ResolveDestination(CustomerNo, ShipToCode, DestinationPointCode, ToLatitude, ToLongitude);
                    Routing.TestRoute(FromLatitude, FromLongitude, ToLatitude, ToLongitude,
                        HttpStatus, ResultText, CorrelationId, DistanceMeters, DurationSeconds, RouteGeoJson);
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
        Clear(FromLatitude);
        Clear(FromLongitude);
        Clear(ToLatitude);
        Clear(ToLongitude);
        Clear(HttpStatus);
        Clear(ResultText);
        Clear(CorrelationId);
        Clear(DistanceMeters);
        Clear(DurationSeconds);
        Clear(RouteGeoJson);
        RouteDisplayRequested := false;
        if MapReady then
            CurrPage.RouteMap.ClearRoute();
    end;
    var
        LocationCode: Code[10];
        OriginPointCode: Code[20];
        CustomerNo: Code[20];
        ShipToCode: Code[10];
        DestinationPointCode: Code[20];
        FromLatitude: Decimal;
        FromLongitude: Decimal;
        ToLatitude: Decimal;
        ToLongitude: Decimal;
        HttpStatus: Integer;
        ResultText: Text[100];
        CorrelationId: Guid;
        DistanceMeters: Decimal;
        DurationSeconds: Decimal;
        RouteGeoJson: Text;
        MapReady: Boolean;
        RouteDisplayRequested: Boolean;
}
