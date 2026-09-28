page 57000 "SI Prok Connections"
{
    PageType = List;
    SourceTable = "SI Prok Connection";
    Caption = 'Підключення Proktek';
    ApplicationArea = All;
    UsageCategory = Administration;
    CardPageId = "SI Prok Connection Card";

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(Code; Rec.Code) { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
                field(Environment; Rec.Environment) { ApplicationArea = All; }
                field("EDS Provider Code"; Rec."EDS Provider Code") { ApplicationArea = All; }
                field("Company Code"; Rec."Company Code") { ApplicationArea = All; }
                field(Username; Rec.Username) { ApplicationArea = All; }
                field(Active; Rec.Active) { ApplicationArea = All; }
                field(PasswordConfigured; PasswordConfigured)
                {
                    ApplicationArea = All;
                    Caption = 'Пароль налаштовано';
                    Editable = false;
                }
                field("Last Test At"; Rec."Last Test At") { ApplicationArea = All; }
                field("Last Test Result"; Rec."Last Test Result") { ApplicationArea = All; }
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
                    Session: Record "SI Prok Session";
                    AuthMgt: Codeunit "SI Prok Auth Mgt.";
                begin
                    AuthMgt.Login(Rec, Session);
                    Message(
                        'Авторизацію Proktek виконано успішно.\GUID: %1\Вузли: %2\Дійсний до: %3',
                        Session."Session GUID",
                        Session."Plant IDs",
                        GetExpiresText(Session));
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        PasswordConfigured := false;
        if (Rec."EDS Provider Code" <> '') and (Rec."Password Credential Code" <> '') then
            PasswordConfigured := CredentialMgt.HasSecret(
                Rec."EDS Provider Code",
                Rec."Password Credential Code");
    end;

    local procedure GetExpiresText(Session: Record "SI Prok Session"): Text
    begin
        if Session."Expires At" <> 0DT then
            exit(Format(Session."Expires At"));
        exit(Session."Expires At Raw");
    end;

    var
        CredentialMgt: Codeunit "SI EDS Credential Mgt.";
        PasswordConfigured: Boolean;
}
