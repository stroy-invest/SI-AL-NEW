page 61006 "SI Supply Req Intake Test"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Tasks;
    Caption = 'Тест Supply Request Intake';

    layout
    {
        area(Content)
        {
            group(Input)
            {
                Caption = 'Canonical Intake JSON';

                field(JsonPayload; JsonPayload)
                {
                    ApplicationArea = All;
                    Caption = 'JSON';
                    MultiLine = true;
                    ToolTip = 'Canonical JSON, який передається до SI Supply Request Intake Mgt.';
                }
            }
            group(Result)
            {
                Caption = 'Результат останнього запуску';

                field(ResultRequestNo; ResultRequestNo)
                {
                    ApplicationArea = All;
                    Caption = '№ заявки';
                    Editable = false;
                }
                field(ResultStatus; ResultStatus)
                {
                    ApplicationArea = All;
                    Caption = 'Статус';
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(LoadSample)
            {
                ApplicationArea = All;
                Caption = 'Завантажити тестовий JSON';
                Image = Import;
                ToolTip = 'Формує приклад canonical intake для перевірки V1 Intake.';

                trigger OnAction()
                begin
                    BuildSamplePayload();
                    Clear(ResultRequestNo);
                    Clear(ResultStatus);
                end;
            }
            action(ExecuteIntake)
            {
                ApplicationArea = All;
                Caption = 'Виконати Intake';
                Image = Start;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Передає JSON безпосередньо до SI Supply Request Intake Mgt.';

                trigger OnAction()
                var
                    IntakeMgt: Codeunit "SI Supply Request Intake Mgt.";
                    Header: Record "SI Supply Req Header";
                    Intake: JsonObject;
                begin
                    if JsonPayload = '' then
                        Error('Вставте canonical JSON або скористайтеся дією "Завантажити тестовий JSON".');

                    if not Intake.ReadFrom(JsonPayload) then
                        Error('Не вдалося прочитати JSON. Перевірте синтаксис payload.');

                    IntakeMgt.AcceptExternalApprovedRequest(Intake, Header);

                    ResultRequestNo := Header."No.";
                    ResultStatus := Format(Header.Status);
                    CurrPage.Update(false);

                    Message('Intake виконано. Заявка: %1. Статус: %2.', Header."No.", Format(Header.Status));
                end;
            }
            action(OpenResult)
            {
                ApplicationArea = All;
                Caption = 'Відкрити заявку';
                Image = View;
                ToolTip = 'Відкриває заявку, створену або знайдену останнім запуском Intake.';

                trigger OnAction()
                var
                    Header: Record "SI Supply Req Header";
                begin
                    if ResultRequestNo = '' then
                        Error('Спочатку виконайте Intake.');

                    Header.Get(ResultRequestNo);
                    Page.Run(Page::"SI Supply Req Card", Header);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        if JsonPayload = '' then
            BuildSamplePayload();
    end;

    local procedure BuildSamplePayload()
    var
        Intake: JsonObject;
        Line: JsonObject;
        Lines: JsonArray;
        Parameter: JsonObject;
        Parameters: JsonArray;
        Spec: JsonObject;
    begin
        Intake.Add('externalSystem', 'SCHRIFT-DEV');
        Intake.Add('externalDocumentId', 'DEV-121224');
        Intake.Add('externalDocumentNo', '01-08/00002-DEV');
        Intake.Add('externalRegisteredAt', CreateDateTime(DMY2Date(15, 9, 2026), 140658T));
        Intake.Add('projectNo', 'SI-PRJ-00001');
        Intake.Add('requiredOnSiteAt', CreateDateTime(DMY2Date(23, 9, 2026), 120000T));
        Intake.Add('description', 'DEV тест canonical Supply Request Intake');

        Line.Add('itemNo', 'БЕТОН M450');
        Line.Add('variantCode', '0000000001');
        Line.Add('quantity', 40);
        Line.Add('uomCode', 'M3');
        Line.Add('description', 'Тестова заявка на бетон через canonical Intake');

        Parameter.Add('parameterCode', 'MOBILITY');
        Parameter.Add('valueType', 'code');
        Parameter.Add('value', 'S3');
        Parameters.Add(Parameter);
        Clear(Parameter);

        Parameter.Add('parameterCode', 'WATER_RESISTANCE');
        Parameter.Add('valueType', 'code');
        Parameter.Add('value', 'W4');
        Parameters.Add(Parameter);
        Clear(Parameter);

        Parameter.Add('parameterCode', 'FROST_RESISTANCE');
        Parameter.Add('valueType', 'code');
        Parameter.Add('value', 'F100');
        Parameters.Add(Parameter);

        Line.Add('parameters', Parameters);
        Lines.Add(Line);
        Intake.Add('lines', Lines);

        Spec.Add('truckIntervalMinutes', 20);
        Spec.Add('deliveryAddress', 'DEV: тестова адреса доставки');
        Spec.Add('entryRestrictions', 'DEV: без обмежень');
        Spec.Add('accessRoadConditions', 'DEV: нормальний під''їзд');
        Spec.Add('unloadingMethod', 'concretepump');
        Spec.Add('concretePumpRequired', true);
        Spec.Add('pumpType', 'mobile');
        Spec.Add('pumpBoomLength', 32);
        Spec.Add('additionalChuteRequired', false);
        Spec.Add('dischargePipeRequired', false);
        Spec.Add('contactName', 'DEV Test');
        Spec.Add('contactPhone', '+380000000000');
        Spec.Add('contactEmail', 'dev@example.invalid');
        Spec.Add('specialInstructions', 'DEV harness test');
        Intake.Add('concreteSupplySpec', Spec);

        Intake.WriteTo(JsonPayload);
    end;

    var
        JsonPayload: Text;
        ResultRequestNo: Code[20];
        ResultStatus: Text[50];
}
