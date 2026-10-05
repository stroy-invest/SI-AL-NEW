page 50447 "SI UA Identifier Test"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Tasks;
    Caption = 'Перевірка українських ідентифікаторів';

    layout
    {
        area(Content)
        {
            group(LocalValidation)
            {
                Caption = 'Локальна перевірка';

                group(RNOKPPGroup)
                {
                    Caption = 'РНОКПП (ІПН фізичної особи)';

                    field(RNOKPP; RNOKPPValue)
                    {
                        ApplicationArea = All;
                        Caption = 'РНОКПП';
                        ToolTip = 'Введіть 10-значний РНОКПП для локальної перевірки контрольної цифри.';
                    }

                    field(RNOKPPResult; RNOKPPResultText)
                    {
                        ApplicationArea = All;
                        Caption = 'Результат';
                        Editable = false;
                    }
                }

                group(EDRPOUGroup)
                {
                    Caption = 'Код ЄДРПОУ';

                    field(EDRPOU; EDRPOUValue)
                    {
                        ApplicationArea = All;
                        Caption = 'ЄДРПОУ';
                        ToolTip = 'Введіть 8-значний код ЄДРПОУ для локальної перевірки контрольної цифри.';
                    }

                    field(EDRPOUResult; EDRPOUResultText)
                    {
                        ApplicationArea = All;
                        Caption = 'Результат';
                        Editable = false;
                    }
                }
            }

            group(YouScoreTest)
            {
                Caption = 'YouScore / EDS — тест API';

                field(PersonResultId; PersonResultIdValue)
                {
                    ApplicationArea = All;
                    Caption = 'Result ID фізособи';
                    ToolTip = 'Result ID асинхронного запиту фізособи. Вставте значення з першої відповіді YouScore для отримання фактичного результату.';
                }

                field(ResponseProvider; ResponseProviderText)
                {
                    ApplicationArea = All;
                    Caption = 'Провайдер';
                    Editable = false;
                }

                field(ResponseStatus; ResponseStatusText)
                {
                    ApplicationArea = All;
                    Caption = 'HTTP / результат';
                    Editable = false;
                }

                field(UsrFlowStatus; UsrFlowStatusText)
                {
                    ApplicationArea = All;
                    Caption = 'USR async flow';
                    Editable = false;
                    ToolTip = 'Показує, на якому кроці інтерактивного USR-сценарію отримано фінальну відповідь.';
                }

                field(ResponseUrl; ResponseUrlText)
                {
                    ApplicationArea = All;
                    Caption = 'URL запиту';
                    Editable = false;
                    MultiLine = true;
                }

                field(ResponseBody; ResponseBodyText)
                {
                    ApplicationArea = All;
                    Caption = 'Raw JSON / відповідь';
                    Editable = false;
                    MultiLine = true;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ValidateRNOKPP)
            {
                ApplicationArea = All;
                Caption = 'Перевірити РНОКПП';
                Image = Check;

                trigger OnAction()
                begin
                    UAIdentifierMgt.ValidateRNOKPP(RNOKPPValue);
                    RNOKPPResultText := 'Коректний';
                end;
            }

            action(ValidateEDRPOU)
            {
                ApplicationArea = All;
                Caption = 'Перевірити ЄДРПОУ';
                Image = Check;

                trigger OnAction()
                begin
                    UAIdentifierMgt.ValidateEDRPOU(EDRPOUValue);
                    EDRPOUResultText := 'Коректний';
                end;
            }

            action(GetLegalEntityUsr)
            {
                ApplicationArea = All;
                Caption = 'YouScore: юрособа (USR)';
                Image = Web;
                ToolTip = 'Після локальної checksum-перевірки ЄДРПОУ виконує через EDS запит GET-USR та показує raw response.';

                trigger OnAction()
                begin
                    UAIdentifierMgt.ValidateEDRPOU(EDRPOUValue);
                    EDRPOUResultText := 'Коректний';
                    ExecuteUsr(EDRPOUValue);
                end;
            }

            action(GetSoleProprietorUsr)
            {
                ApplicationArea = All;
                Caption = 'YouScore: ФОП (USR)';
                Image = Web;
                ToolTip = 'Після локальної checksum-перевірки РНОКПП виконує через EDS запит GET-USR та показує raw response.';

                trigger OnAction()
                begin
                    UAIdentifierMgt.ValidateRNOKPP(RNOKPPValue);
                    RNOKPPResultText := 'Коректний';
                    ExecuteUsr(RNOKPPValue);
                end;
            }

            action(ForceUsrBackground)
            {
                ApplicationArea = All;
                Caption = 'YouScore: передати USR у фон';
                Image = SendTo;
                ToolTip = 'Діагностична дія: виконує один реальний GET-USR, після чого примусово ставить GET-USR у EDS Async Request Queue, минаючи стандартний foreground chain 3 x 5 с. Якщо первинна відповідь 202, додатково показує останні доступні дані через GET-USR-CURRENT.';

                trigger OnAction()
                begin
                    if EDRPOUValue <> '' then begin
                        UAIdentifierMgt.ValidateEDRPOU(EDRPOUValue);
                        EDRPOUResultText := 'Коректний';
                        ForceUsrToBackground(EDRPOUValue);
                        exit;
                    end;

                    if RNOKPPValue <> '' then begin
                        UAIdentifierMgt.ValidateRNOKPP(RNOKPPValue);
                        RNOKPPResultText := 'Коректний';
                        ForceUsrToBackground(RNOKPPValue);
                        exit;
                    end;

                    Error('Вкажіть код ЄДРПОУ або РНОКПП.');
                end;
            }

            action(GetUsrCurrentData)
            {
                ApplicationArea = All;
                Caption = 'YouScore: поточні дані USR';
                Image = Refresh;
                ToolTip = 'Після локальної перевірки ідентифікатора виконує GET-USR-CURRENT з showCurrentData=True та показує наявні в YouScore дані без очікування завершення актуалізації ЄДР.';

                trigger OnAction()
                begin
                    if EDRPOUValue <> '' then begin
                        UAIdentifierMgt.ValidateEDRPOU(EDRPOUValue);
                        EDRPOUResultText := 'Коректний';
                        ExecuteUsrCurrent(EDRPOUValue);
                        exit;
                    end;

                    if RNOKPPValue <> '' then begin
                        UAIdentifierMgt.ValidateRNOKPP(RNOKPPValue);
                        RNOKPPResultText := 'Коректний';
                        ExecuteUsrCurrent(RNOKPPValue);
                        exit;
                    end;

                    Error('Вкажіть код ЄДРПОУ або РНОКПП.');
                end;
            }

            action(GetIndividualByCode)
            {
                ApplicationArea = All;
                Caption = 'YouScore: фізособа за РНОКПП';
                Image = Web;
                ToolTip = 'Після локальної checksum-перевірки РНОКПП виконує асинхронний запит individualsRelatedPersonsByCode. Показує первинну raw response з resultId.';

                trigger OnAction()
                var
                    RuntimeParam: Record "SI EDS Runtime Param" temporary;
                begin
                    UAIdentifierMgt.ValidateRNOKPP(RNOKPPValue);
                    RNOKPPResultText := 'Коректний';
                    RuntimeParam.Add('PERSON-CODE', RNOKPPValue);
                    ExecuteEDS('GET-INDIVIDUAL-BY-CODE', RuntimeParam);
                end;
            }

            action(GetIndividualResult)
            {
                ApplicationArea = All;
                Caption = 'YouScore: отримати результат фізособи';
                Image = Refresh;
                ToolTip = 'Отримує фактичний результат асинхронного запиту за Result ID.';

                trigger OnAction()
                var
                    RuntimeParam: Record "SI EDS Runtime Param" temporary;
                begin
                    if PersonResultIdValue = '' then
                        Error('Вкажіть Result ID, отриманий у первинній відповіді YouScore.');

                    RuntimeParam.Add('RESULT-ID', PersonResultIdValue);
                    ExecuteEDS('GET-INDIVIDUAL-BY-RESULT', RuntimeParam);
                end;
            }

            action(GetRateLimits)
            {
                ApplicationArea = All;
                Caption = 'YouScore: баланс ключа';
                Image = Info;
                ToolTip = 'Виконує нетранзакційний запит rateLimits для перевірки авторизації та залишку тестового ліміту.';

                trigger OnAction()
                var
                    RuntimeParam: Record "SI EDS Runtime Param" temporary;
                begin
                    ExecuteEDS('GET-RATE-LIMITS', RuntimeParam);
                end;
            }

            action(ClearResults)
            {
                ApplicationArea = All;
                Caption = 'Очистити';
                Image = ClearFilter;

                trigger OnAction()
                begin
                    Clear(RNOKPPValue);
                    Clear(EDRPOUValue);
                    Clear(RNOKPPResultText);
                    Clear(EDRPOUResultText);
                    Clear(PersonResultIdValue);
                    ClearResponse();
                end;
            }
        }
    }

    var
        UAIdentifierMgt: Codeunit "SI UA Identifier Mgt.";
        EDSOrchestrator: Codeunit "SI EDS Orchestrator";
        RNOKPPValue: Text[10];
        EDRPOUValue: Text[8];
        RNOKPPResultText: Text[50];
        EDRPOUResultText: Text[50];
        PersonResultIdValue: Text[250];
        ResponseProviderText: Text[100];
        ResponseStatusText: Text[250];
        UsrFlowStatusText: Text[250];
        ResponseUrlText: Text;
        ResponseBodyText: Text;

    local procedure ExecuteUsr(IdentifierValue: Text)
    var
        HttpStatusCode: Integer;
        RetryNo: Integer;
        WaitDialog: Dialog;
        First202At: DateTime;
        AsyncEntryNo: Integer;
    begin
        Clear(UsrFlowStatusText);

        HttpStatusCode := ExecuteUsrRequest(IdentifierValue);
        if HttpStatusCode <> 202 then begin
            UsrFlowStatusText := StrSubstNo('GET-USR: HTTP %1, без очікування.', HttpStatusCode);
            CurrPage.Update(false);
            exit;
        end;

        First202At := CurrentDateTime;
        WaitDialog.Open('Триває актуалізація даних реєстру. Зачекайте...');
        for RetryNo := 1 to 3 do begin
            Sleep(5000);
            HttpStatusCode := ExecuteUsrRequest(IdentifierValue);

            if HttpStatusCode <> 202 then begin
                WaitDialog.Close();
                UsrFlowStatusText :=
                    StrSubstNo(
                        'GET-USR: HTTP %1 після повтору №%2 (~%3 с).',
                        HttpStatusCode,
                        RetryNo,
                        RetryNo * 5);
                CurrPage.Update(false);
                exit;
            end;
        end;
        WaitDialog.Close();

        ExecuteUsrCurrent(IdentifierValue);
        AsyncEntryNo := EnqueueUsrRefresh(IdentifierValue, First202At);
        UsrFlowStatusText :=
            StrSubstNo(
                'GET-USR: 202 після ~15 с; показано останні доступні дані; фоновий запит №%1.',
                AsyncEntryNo);
        CurrPage.Update(false);

        Message(
            'Актуалізація даних реєстру ще триває. Зараз буде показано останні доступні дані. Після завершення актуалізації система оновить їх автоматично.');
    end;


    local procedure ForceUsrToBackground(IdentifierValue: Text)
    var
        HttpStatusCode: Integer;
        StartedAt: DateTime;
        AsyncEntryNo: Integer;
    begin
        Clear(UsrFlowStatusText);
        StartedAt := CurrentDateTime;

        HttpStatusCode := ExecuteUsrRequest(IdentifierValue);

        // For a real 202, show the currently available snapshot before handing the refresh to the worker.
        if HttpStatusCode = 202 then
            ExecuteUsrCurrent(IdentifierValue);

        // This is deliberately a diagnostic force-handoff: even if GET-USR already returned 200,
        // enqueue the same real request so Queue -> Worker -> EDS -> Completed can be acceptance-tested.
        AsyncEntryNo := EnqueueUsrRefresh(IdentifierValue, StartedAt);
        UsrFlowStatusText :=
            StrSubstNo(
                'TEST background: первинний GET-USR HTTP %1; примусово передано у фоновий запит №%2.',
                HttpStatusCode,
                AsyncEntryNo);
        CurrPage.Update(false);

        Message(
            'Тестовий USR-запит передано у фонову чергу EDS. Номер асинхронного запиту: %1. Подальшу обробку виконає Job Queue.',
            AsyncEntryNo);
    end;

    local procedure EnqueueUsrRefresh(IdentifierValue: Text; StartedAt: DateTime): Integer
    var
        RuntimeParam: Record "SI EDS Runtime Param" temporary;
        AsyncMgt: Codeunit "SI EDS Async Mgt.";
    begin
        RuntimeParam.Add('CONTRACTOR-CODE', IdentifierValue);
        exit(
            AsyncMgt.Enqueue(
                'UA-REGISTRY',
                'GET-USR',
                IdentifierValue,
                StartedAt,
                RuntimeParam));
    end;

    local procedure ExecuteUsrRequest(IdentifierValue: Text): Integer
    var
        RuntimeParam: Record "SI EDS Runtime Param" temporary;
    begin
        RuntimeParam.Add('CONTRACTOR-CODE', IdentifierValue);
        exit(ExecuteEDSGetStatus('GET-USR', RuntimeParam));
    end;

    local procedure ExecuteUsrCurrent(IdentifierValue: Text)
    var
        RuntimeParam: Record "SI EDS Runtime Param" temporary;
    begin
        RuntimeParam.Add('CONTRACTOR-CODE', IdentifierValue);
        ExecuteEDS('GET-USR-CURRENT', RuntimeParam);
    end;

    local procedure ExecuteEDS(
        OperationCode: Code[50];
        var RuntimeParam: Record "SI EDS Runtime Param" temporary)
    begin
        ExecuteEDSGetStatus(OperationCode, RuntimeParam);
    end;

    local procedure ExecuteEDSGetStatus(
        OperationCode: Code[50];
        var RuntimeParam: Record "SI EDS Runtime Param" temporary): Integer
    var
        ResponseBuffer: Record "SI EDS Response Buffer" temporary;
    begin
        ClearResponse();

        EDSOrchestrator.Execute(
            'UA-REGISTRY',
            OperationCode,
            RuntimeParam,
            ResponseBuffer);

        if not ResponseBuffer.FindFirst() then
            Error('EDS не повернув Response Buffer.');

        ResponseProviderText := ResponseBuffer."Provider Code";
        ResponseStatusText :=
            StrSubstNo(
                '%1 %2 | %3 | %4 ms',
                ResponseBuffer."HTTP Status Code",
                ResponseBuffer."HTTP Reason Phrase",
                Format(ResponseBuffer."Result Type"),
                ResponseBuffer."Duration (ms)");
        ResponseUrlText := ResponseBuffer."Request URL";
        ResponseBodyText := ResponseBuffer.GetBodyText();

        if ResponseBuffer."Error Message" <> '' then
            ResponseBodyText :=
                StrSubstNo(
                    'EDS ERROR [%1]: %2\%3',
                    ResponseBuffer."Error Code",
                    ResponseBuffer."Error Message",
                    ResponseBodyText);

        CurrPage.Update(false);
        exit(ResponseBuffer."HTTP Status Code");
    end;

    local procedure ClearResponse()
    begin
        Clear(ResponseProviderText);
        Clear(ResponseStatusText);
        Clear(UsrFlowStatusText);
        Clear(ResponseUrlText);
        Clear(ResponseBodyText);
    end;
}
