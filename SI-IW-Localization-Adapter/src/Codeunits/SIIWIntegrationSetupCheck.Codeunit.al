codeunit 65007 "SI IW Integration Setup Check"
{
    procedure RunChecks(var Result: Record "SI IW Setup Check Result" temporary)
    var
        VehicleType: Record "SI Vehicle Type";
        Mapping: Record "SI IW Vehicle Type Mapping";
        JobEntry: Record "Job Queue Entry";
        FoundJob: Boolean;
    begin
        Result.DeleteAll();

        if VehicleType.FindSet() then
            repeat
                if not VehicleType.Blocked then begin
                    if not Mapping.Get(VehicleType.Code) then
                        AddResult(Result, 'Mapping', VehicleType.Code, 'ERROR',
                            'Немає відповідності для активного типу транспорту.',
                            'Створіть Mapping і вкажіть категорію IW.')
                    else
                        CheckMapping(Result, Mapping);
                end;
            until VehicleType.Next() = 0;

        if Mapping.FindSet() then
            repeat
                if not VehicleType.Get(Mapping."SI Vehicle Type Code") then
                    AddResult(Result, 'Mapping', Mapping."SI Vehicle Type Code", 'ERROR',
                        'Mapping посилається на відсутній тип SI VM.',
                        'Виправте або видаліть Mapping.')
                else
                    if VehicleType.Blocked then
                        AddResult(Result, 'Mapping', Mapping."SI Vehicle Type Code", 'WARNING',
                            'Тип транспорту заблокований у SI VM.',
                            'Перевірте актуальність відповідності.');
            until Mapping.Next() = 0;

        JobEntry.SetRange("Object Type to Run", JobEntry."Object Type to Run"::Codeunit);
        JobEntry.SetRange("Object ID to Run", Codeunit::"SI IW Vehicle Sync Processor");
        if JobEntry.FindSet() then
            repeat
                FoundJob := true;
                AddResult(Result, 'Job Queue', Format(JobEntry.ID), 'INFO',
                    CopyStr(StrSubstNo('Знайдено завдання. Статус: %1.', JobEntry.Status), 1, 250),
                    'Перевірте статус і розклад виконання завдання.');
            until JobEntry.Next() = 0;
        if not FoundJob then
            AddResult(Result, 'Job Queue', '', 'WARNING',
                'Не знайдено Job Queue Entry для процесора синхронізації.',
                'Створіть Job Queue Entry для codeunit 65005.');

        if Result.IsEmpty() then
            AddResult(Result, 'Integration', '', 'OK',
                'Критичних проблем конфігурації не виявлено.', '');
    end;

    local procedure CheckMapping(var Result: Record "SI IW Setup Check Result" temporary;
                                 Mapping: Record "SI IW Vehicle Type Mapping")
    begin
        if not Mapping.Enabled then begin
            AddResult(Result, 'Mapping', Mapping."SI Vehicle Type Code", 'WARNING',
                'Mapping вимкнений.', 'Увімкніть Mapping, якщо тип використовується.');
            exit;
        end;
        if Mapping."IW Vehicle Category".AsInteger() = 0 then begin
            AddResult(Result, 'Mapping', Mapping."SI Vehicle Type Code", 'ERROR',
                'Не задано категорію IW.', 'Виберіть категорію IW.');
            exit;
        end;
        AddResult(Result, 'Mapping', Mapping."SI Vehicle Type Code", 'OK',
            'Відповідність налаштована.', '');
    end;

    local procedure AddResult(var Result: Record "SI IW Setup Check Result" temporary;
                              CheckArea: Text[50]; ObjectCode: Code[50]; CheckResult: Text[20];
                              Details: Text[250]; ActionText: Text[250])
    var
        NextEntryNo: Integer;
    begin
        Result.Reset();
        if Result.FindLast() then
            NextEntryNo := Result."Entry No." + 1
        else
            NextEntryNo := 1;
        Result.Init();
        Result."Entry No." := NextEntryNo;
        Result."Check Area" := CheckArea;
        Result."Object Code" := ObjectCode;
        Result.Result := CheckResult;
        Result.Details := Details;
        Result."Recommended Action" := ActionText;
        Result.Insert();
    end;
}
