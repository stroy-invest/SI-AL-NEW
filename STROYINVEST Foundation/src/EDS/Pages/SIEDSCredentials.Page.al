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

            action(MigrateAllLegacyCredentials)
            {
                ApplicationArea = All;
                Caption = 'Мігрувати всі облікові дані';
                ToolTip = 'Одноразово переносить наявні старі секрети всіх провайдерів до канонічного захищеного сховища. Старі секрети не видаляються.';
                Image = Import;

                trigger OnAction()
                var
                    Credential: Record "SI EDS Credential";
                    MigrationMgt: Codeunit "SI EDS Credential Mgt.";
                    MigratedCount: Integer;
                    AlreadyCount: Integer;
                    MissingCount: Integer;
                    TotalCount: Integer;
                begin
                    if not Confirm(
                        'Мігрувати всі облікові дані EDS до канонічного сховища? Старі секрети не видалятимуться.',
                        false)
                    then
                        exit;

                    // No COMMIT: any unexpected error rolls back the whole action.
                    if Credential.FindSet() then
                        repeat
                            TotalCount += 1;
                            if MigrationMgt.HasSecret(Credential."Provider Code", Credential.Code) then
                                AlreadyCount += 1
                            else
                                if MigrationMgt.HasLegacySecret(Credential."Provider Code", Credential.Code) then begin
                                    if MigrationMgt.MigrateLegacyCredential(Credential."Provider Code", Credential.Code) then
                                        MigratedCount += 1;
                                end else
                                    MissingCount += 1;
                        until Credential.Next() = 0;

                    Message(
                        'Міграція EDS завершена. Всього записів: %1. Перенесено: %2. Уже в канонічному сховищі: %3. Без збереженого секрету: %4.',
                        TotalCount, MigratedCount, AlreadyCount, MissingCount);
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