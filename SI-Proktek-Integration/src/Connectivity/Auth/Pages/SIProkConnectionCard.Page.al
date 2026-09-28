page 57001 "SI Prok Connection Card"
{
    PageType = Card;
    SourceTable = "SI Prok Connection";
    Caption = 'Підключення Proktek';
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Профіль';

                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                }

                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }

                field(Environment; Rec.Environment)
                {
                    ApplicationArea = All;
                }

                field(Active; Rec.Active)
                {
                    ApplicationArea = All;
                }
            }

            group(EDS)
            {
                Caption = 'External Data Services';

                field("EDS Service Code"; Rec."EDS Service Code")
                {
                    ApplicationArea = All;
                }

                field("EDS Provider Code"; Rec."EDS Provider Code")
                {
                    ApplicationArea = All;
                }

                field("EDS Login Operation"; Rec."EDS Login Operation")
                {
                    ApplicationArea = All;
                }

                field("EDS Prod. Operation"; Rec."EDS Prod. Operation")
                {
                    ApplicationArea = All;
                }

                field("Password Credential Code"; Rec."Password Credential Code")
                {
                    ApplicationArea = All;
                }

                field(PasswordConfigured; PasswordConfigured)
                {
                    ApplicationArea = All;
                    Caption = 'Пароль налаштовано';
                    Editable = false;
                }
            }

            group(Login)
            {
                Caption = 'Авторизація Proktek';

                field("Company Code"; Rec."Company Code")
                {
                    ApplicationArea = All;
                }

                field(Username; Rec.Username)
                {
                    ApplicationArea = All;
                }

                field("Last Test At"; Rec."Last Test At")
                {
                    ApplicationArea = All;
                }

                field("Last Test Result"; Rec."Last Test Result")
                {
                    ApplicationArea = All;
                }
            }

            group(OperationTestConsole)
            {
                Caption = 'Тестування операції';

                field(TestPayloadText; TestPayloadText)
                {
                    ApplicationArea = All;
                    Caption = 'Payload';
                    MultiLine = true;
                    ToolTip = 'JSON payload поточної EDS-операції без поля guid. GUID активного сеансу Proktek буде автоматично додано в корінь JSON перед відправленням. Для стандартних GET-тестів поле можна залишити порожнім.';

                    trigger OnValidate()
                    begin
                        Rec.SetTestPayload(TestPayloadText);
                        Rec.Modify(true);
                    end;
                }
            }

            group(SessionInfo)
            {
                Caption = 'Останній успішний сеанс';

                field(SessionGuid; Session."Session GUID")
                {
                    ApplicationArea = All;
                    Caption = 'GUID сеансу';
                    Editable = false;
                }

                field(SessionUsername; Session.Username)
                {
                    ApplicationArea = All;
                    Caption = 'Користувач сеансу';
                    Editable = false;
                }

                field(ExpiresAt; Session."Expires At")
                {
                    ApplicationArea = All;
                    Caption = 'Дійсний до';
                    Editable = false;
                }

                field(PlantIds; Session."Plant IDs")
                {
                    ApplicationArea = All;
                    Caption = 'Ідентифікатори вузлів';
                    Editable = false;
                }

                field(ScaleIds; Session."Scale IDs")
                {
                    ApplicationArea = All;
                    Caption = 'Ідентифікатори ваг';
                    Editable = false;
                }

                field(LoggedInAt; Session."Logged In At")
                {
                    ApplicationArea = All;
                    Caption = 'Час входу';
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SetActive)
            {
                ApplicationArea = All;
                Caption = 'Зробити активним';
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    ConnectionMgt: Codeunit "SI Prok Connection Mgt.";
                begin
                    CurrPage.SaveRecord();

                    ConnectionMgt.SetActive(Rec);

                    CurrPage.Update(false);
                end;
            }

            action(Credentials)
            {
                ApplicationArea = All;
                Caption = 'Облікові дані EDS';

                RunObject = page "SI EDS Credentials";
                RunPageLink = "Provider Code" = field("EDS Provider Code");
            }

            action(TestLogin)
            {
                ApplicationArea = All;
                Caption = 'Перевірити авторизацію';
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    AuthMgt: Codeunit "SI Prok Auth Mgt.";
                begin
                    CurrPage.SaveRecord();

                    AuthMgt.Login(
                        Rec,
                        Session);

                    LoadState();

                    Message(
                        'Авторизацію Proktek виконано успішно.\' +
                        'GUID: %1\' +
                        'Користувач: %2\' +
                        'Вузли: %3\' +
                        'Ваги: %4\' +
                        'Дійсний до: %5',
                        Session."Session GUID",
                        Session.Username,
                        Session."Plant IDs",
                        Session."Scale IDs",
                        GetExpiresText());

                    CurrPage.Update(false);
                end;
            }

            action(ClearSession)
            {
                ApplicationArea = All;
                Caption = 'Очистити сеанс';

                trigger OnAction()
                begin
                    if Session.Get(Rec.Code) then
                        Session.ClearSession();

                    LoadState();

                    CurrPage.Update(false);
                end;
            }

            action(TestCompanyInfo)
            {
                ApplicationArea = All;
                Caption = 'Тест CompanyInfo';
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    CompanyInfo: Codeunit "SI Prok Company Info";
                    ResponseText: Text;
                begin
                    CurrPage.SaveRecord();

                    CompanyInfo.Execute(
                        Rec,
                        ResponseText);

                    // CompanyInfo може виконати повторний Login,
                    // якщо поточний сеанс відсутній або прострочений.
                    LoadState();

                    Message(
                        'Proktek CompanyInfo успішно отримано.\' +
                        '\' +
                        '%1',
                        ResponseText);

                    CurrPage.Update(false);
                end;
            }

            action(TestCurrentOperation)
            {
                ApplicationArea = All;
                Caption = 'Тестувати поточну операцію';
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    OperationTest: Codeunit "SI Prok Operation Test";
                    SummaryText: Text;
                    ResponsePreview: Text;
                begin
                    SaveTestPayload();
                    CurrPage.SaveRecord();

                    OperationTest.ExecuteCurrent(
                        Rec,
                        SummaryText,
                        ResponsePreview);

                    LoadState();

                    if ResponsePreview <> '' then
                        Message(
                            '%1\\Response:\%2',
                            SummaryText,
                            ResponsePreview)
                    else
                        Message('%1', SummaryText);

                    CurrPage.Update(false);
                end;
            }


            action(TestRawLogin)
            {
                ApplicationArea = All;
                Caption = 'RAW Login A/B test';

                trigger OnAction()
                var
                    RawLoginTest: Codeunit "SI Prok Raw Login Test";
                    ResultText: Text;
                begin
                    CurrPage.SaveRecord();

                    RawLoginTest.Execute(
                        Rec,
                        ResultText);

                    LoadState();

                    Message(
                        '%1',
                        ResultText);

                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        LoadState();
    end;

    local procedure LoadState()
    begin
        TestPayloadText := Rec.GetTestPayload();
        Clear(Session);

        if Rec.Code <> '' then
            if not Session.Get(Rec.Code) then
                Clear(Session);

        PasswordConfigured := false;

        if (Rec."EDS Provider Code" <> '') and
           (Rec."Password Credential Code" <> '')
        then
            PasswordConfigured :=
                CredentialMgt.HasSecret(
                    Rec."EDS Provider Code",
                    Rec."Password Credential Code");
    end;

    local procedure SaveTestPayload()
    begin
        Rec.SetTestPayload(TestPayloadText);
    end;

    local procedure GetExpiresText(): Text
    begin
        if Session."Expires At" <> 0DT then
            exit(Format(Session."Expires At"));

        exit(Session."Expires At Raw");
    end;

    var
        Session: Record "SI Prok Session";
        CredentialMgt: Codeunit "SI EDS Credential Mgt.";
        PasswordConfigured: Boolean;
        TestPayloadText: Text;
}