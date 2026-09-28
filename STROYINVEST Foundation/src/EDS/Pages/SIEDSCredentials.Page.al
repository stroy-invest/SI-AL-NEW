page 50460 "SI EDS Credentials"
{
    PageType = List;
    SourceTable = "SI EDS Credential";
    Caption = 'EDS: облікові дані';
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Provider Code"; Rec."Provider Code")
                {
                    ApplicationArea = All;
                }

                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                }

                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }

                field("Credential Type"; Rec."Credential Type")
                {
                    ApplicationArea = All;
                }

                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                }

                field(Configured; Configured)
                {
                    ApplicationArea = All;
                    Caption = 'Налаштовано';
                    Editable = false;
                }

                field("Last Changed At"; Rec."Last Changed At")
                {
                    ApplicationArea = All;
                }

                field("Last Changed By"; Rec."Last Changed By")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SetSecret)
            {
                ApplicationArea = All;
                Caption = 'Встановити / змінити секрет';
                Image = Edit;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    SecretDialog: Page "SI EDS Secret Dialog";
                    CredentialMgt: Codeunit "SI EDS Credential Mgt.";
                    SecretValue: Text;
                begin
                    Rec.TestField("Provider Code");
                    Rec.TestField(Code);

                    if SecretDialog.RunModal() <> Action::OK then
                        exit;

                    SecretValue :=
                        SecretDialog.GetSecretValue();

                    CredentialMgt.SetSecretText(
                        Rec."Provider Code",
                        Rec.Code,
                        SecretValue);

                    Clear(SecretValue);

                    UpdateCredentialAudit();

                    Message(
                        'Секретне значення для %1 / %2 збережено.',
                        Rec."Provider Code",
                        Rec.Code);

                    CurrPage.Update(false);
                end;
            }

            action(DeleteSecret)
            {
                ApplicationArea = All;
                Caption = 'Видалити секрет';
                Image = Delete;

                trigger OnAction()
                var
                    CredentialMgt: Codeunit "SI EDS Credential Mgt.";
                begin
                    if not Configured then
                        exit;

                    if not Confirm(
                        'Видалити секретне значення для %1 / %2?',
                        false,
                        Rec."Provider Code",
                        Rec.Code)
                    then
                        exit;

                    CredentialMgt.DeleteSecretText(
                        Rec."Provider Code",
                        Rec.Code);

                    UpdateCredentialAudit();

                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Configured :=
            CredentialMgt.HasSecret(
                Rec."Provider Code",
                Rec.Code);
    end;

    local procedure UpdateCredentialAudit()
    begin
        Rec."Last Changed At" :=
            CurrentDateTime;

        Rec."Last Changed By" :=
            CopyStr(
                UserId(),
                1,
                MaxStrLen(Rec."Last Changed By"));

        Rec.Modify(false);

        Configured :=
            CredentialMgt.HasSecret(
                Rec."Provider Code",
                Rec.Code);
    end;

    var
        CredentialMgt: Codeunit "SI EDS Credential Mgt.";
        Configured: Boolean;
}