codeunit 61046 "SI Planning Run Context"
{
    SingleInstance = true;

    procedure Arm(ForecastName: Code[10])
    begin
        Armed := true;
        PlanningForecastName := ForecastName;
    end;

    procedure Consume(var ForecastName: Code[10]): Boolean
    begin
        if not Armed then
            exit(false);

        ForecastName := PlanningForecastName;
        Reset();
        exit(true);
    end;

    procedure Reset()
    begin
        Armed := false;
        PlanningForecastName := '';
    end;

    var
        Armed: Boolean;
        PlanningForecastName: Code[10];
}
