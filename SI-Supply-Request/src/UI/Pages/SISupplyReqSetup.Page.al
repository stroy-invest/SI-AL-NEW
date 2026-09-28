page 61000 "SI Supply Req Setup"
{
    PageType = Card;
    SourceTable = "SI Supply Req Setup";
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'Налаштування заявок на забезпечення';
    Editable = true;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = true;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Загальні';
                field("Request Nos."; Rec."Request Nos.")
                {
                    ApplicationArea = All;
                    Editable = true;
                    ShowMandatory = true;
                    ToolTip = 'Визначає серію номерів, яка використовується для нових заявок на забезпечення.';
                }
                field("VSC Nos."; Rec."VSC Nos.")
                {
                    ApplicationArea = All;
                    Editable = true;
                    ToolTip = 'Визначає серію номерів для каналів постачання постачальників.';
                }
                field("Planning Forecast Name"; Rec."Planning Forecast Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає окремий стандартний прогноз Business Central, у який проєктується Єдиний реєстр планових потреб.';
                }
            }
            group(Schrift)
            {
                Caption = 'Schrift';
                field("Schrift Enabled"; Rec."Schrift Enabled")
                {
                    ApplicationArea = All;
                    ToolTip = 'Вмикає отримання погоджених заявок зі Schrift.';
                }
                field("Schrift Base URL"; Rec."Schrift Base URL")
                {
                    ApplicationArea = All;
                    ToolTip = 'Базова адреса External API Schrift, наприклад https://c16445.ostrean.com/api/v1/External.';
                }
                field("Schrift Template ID"; Rec."Schrift Template ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'TemplateId повного документа Schrift. Для заявки на бетон: 45332.';
                }
                field("Schrift Document Type ID"; Rec."Schrift Document Type ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'DocumentTypeId зі списку документів Schrift. Для заявки на бетон: 102381.';
                }
                field(SchriftApiKeyConfigured; ApiKeyConfigured)
                {
                    ApplicationArea = All;
                    Caption = 'API-ключ налаштовано';
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SetSchriftApiKey)
            {
                ApplicationArea = All;
                Caption = 'Встановити API-ключ Schrift';
                Image = EncryptionKeys;

                trigger OnAction()
                var
                    SchriftClient: Codeunit "SI Schrift Client";
                    ApiKeyDialog: Page "SI Schrift API Key Dialog";
                    ApiKey: Text;
                begin
                    if ApiKeyDialog.RunModal() <> Action::OK then
                        exit;
                    ApiKey := ApiKeyDialog.GetApiKey();
                    SchriftClient.SetApiKey(ApiKey);
                    ApiKeyConfigured := true;
                    CurrPage.Update(false);
                end;
            }
            action(ClearSchriftApiKey)
            {
                ApplicationArea = All;
                Caption = 'Очистити API-ключ Schrift';
                Image = Delete;

                trigger OnAction()
                var
                    SchriftClient: Codeunit "SI Schrift Client";
                begin
                    SchriftClient.ClearApiKey();
                    ApiKeyConfigured := false;
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        EnsureSetupRecord();
    end;

    local procedure EnsureSetupRecord()
    begin
        Rec.Reset();
        if not Rec.Get('') then begin
            Rec.Init();
            Rec."Primary Key" := '';
            Rec.Insert(true);
        end;

        // Re-read the persisted singleton record so the card is bound to an
        // existing database row and opens in normal modify mode.
        Rec.Get('');
    end;

    trigger OnAfterGetRecord()
    var
        SchriftClient: Codeunit "SI Schrift Client";
    begin
        ApiKeyConfigured := SchriftClient.HasApiKey();
    end;

    var
        ApiKeyConfigured: Boolean;
}
