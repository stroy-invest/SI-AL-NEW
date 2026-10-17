page 63000 "SI Geo Geocoding Test"
{
    Caption = 'Тест геокодування';
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    Editable = true;

    layout
    {
        area(Content)
        {
            group(Request)
            {
                Caption = 'Запит';

                field(AddressInput; AddressInput)
                {
                    ApplicationArea = All;
                    Caption = 'Адреса';
                    MultiLine = true;
                    ToolTip = 'Адреса, яку потрібно перевірити через Geoapify.';
                }
            }

            group(Result)
            {
                Caption = 'Результат';

                field(HttpStatus; HttpStatus)
                {
                    ApplicationArea = All;
                    Caption = 'HTTP статус';
                    Editable = false;
                }
                field(ResultText; ResultText)
                {
                    ApplicationArea = All;
                    Caption = 'Результат EDS';
                    Editable = false;
                }
                field(CorrelationId; CorrelationId)
                {
                    ApplicationArea = All;
                    Caption = 'Correlation ID';
                    Editable = false;
                }
                field(DiagnosticUrl; DiagnosticUrl)
                {
                    ApplicationArea = All;
                    Caption = 'Діагностичний URL';
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RunGeocoding)
            {
                ApplicationArea = All;
                Caption = 'Виконати геокодування';
                Image = TestFile;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    GeoTestMgt: Codeunit "SI Geo Test Mgt.";
                begin
                    Clear(HttpStatus);
                    Clear(ResultText);
                    Clear(CorrelationId);
                    Clear(DiagnosticUrl);
                    GeoTestMgt.TestForwardGeocoding(
                        AddressInput, HttpStatus, ResultText,
                        CorrelationId, DiagnosticUrl);
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
            Error('Сторінка тестування Geo Service доступна лише в Sandbox.');
    end;

    var
        AddressInput: Text[2048];
        HttpStatus: Integer;
        ResultText: Text[100];
        CorrelationId: Guid;
        DiagnosticUrl: Text[100];
}
