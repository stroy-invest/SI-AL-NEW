page 50441 "SI Bank Directory"
{
    PageType = List;
    SourceTable = "SI Bank Directory";

    Caption = 'Довідник банків';
    ApplicationArea = All;
    UsageCategory = Administration;

    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("NBU ID"; Rec."NBU ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає унікальний ідентифікатор банку за даними НБУ.';
                }

                field(MFO; Rec.MFO)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає код банку (МФО).';
                }

                field(EDRPOU; Rec.EDRPOU)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає код ЄДРПОУ банку.';
                }

                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Відображає нормалізовану назву банку для пошуку, сортування та вибору.';
                }

                field(Active; Rec.Active)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає, чи дозволено використовувати банк для нових банківських реквізитів.';
                }

                field("NBU Status Name"; Rec."NBU Status Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Відображає офіційний стан банку за даними НБУ.';
                }

                field("License Status Name"; Rec."License Status Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Відображає стан банківської ліцензії.';
                }

                field(City; Rec.City)
                {
                    ApplicationArea = All;
                    ToolTip = 'Відображає населений пункт банку.';
                }

                field("Full Name"; Rec."Full Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Відображає повну офіційну назву банку за даними НБУ.';
                }

                field("Short Name"; Rec."Short Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Відображає коротку назву банку в тому вигляді, як її повернув API НБУ.';
                }

                field(Address; Rec.Address)
                {
                    ApplicationArea = All;
                    ToolTip = 'Відображає адресу банку.';
                }

                field(Website; Rec.Website)
                {
                    ApplicationArea = All;
                    ToolTip = 'Відображає вебсайт банку.';
                }

                field("Last Sync At"; Rec."Last Sync At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Відображає дату й час останньої успішної актуалізації запису з НБУ.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SyncWithNBU)
            {
                Caption = 'Синхронізувати з НБУ';
                ApplicationArea = All;
                Image = Refresh;
                ToolTip = 'Отримує актуальний довідник банків із офіційного API НБУ та актуалізує локальний довідник.';

                trigger OnAction()
                var
                    NBUBankSyncMgt: Codeunit "SI NBU Bank Sync Mgt.";
                    InsertedCount: Integer;
                    UpdatedCount: Integer;
                    DeactivatedCount: Integer;
                begin
                    NBUBankSyncMgt.SyncDirectory(
                        InsertedCount,
                        UpdatedCount,
                        DeactivatedCount);

                    CurrPage.Update(false);

                    Message(
                        'Синхронізацію з НБУ завершено.\' +
                        'Створено: %1\' +
                        'Оновлено: %2\' +
                        'Деактивовано: %3',
                        InsertedCount,
                        UpdatedCount,
                        DeactivatedCount);
                end;
            }

            action(RefreshFromNBU)
            {
                Caption = 'Оновити з НБУ';
                ApplicationArea = All;
                Image = RefreshLines;
                ToolTip = 'Отримує з НБУ актуальні дані вибраного банку та оновлює його запис у довіднику.';

                trigger OnAction()
                var
                    NBUBankSyncMgt: Codeunit "SI NBU Bank Sync Mgt.";
                    Bank: Record "SI Bank Directory";
                    NBUId: Code[20];
                begin
                    NBUId := Rec."NBU ID";

                    if NBUId = '' then
                        Error('Для вибраного запису не зазначено ID НБУ.');

                    if not NBUBankSyncMgt.SyncBank(NBUId, Bank) then
                        Error(
                            'Банк з ID НБУ %1 не знайдено у відповіді НБУ.',
                            NBUId);

                    CurrPage.Update(false);

                    Message(
                        'Дані банку %1 (%2) актуалізовано з НБУ.',
                        Bank.Name,
                        Bank."NBU ID");
                end;
            }

            action(TestIBAN)
            {
                Caption = 'Перевірити IBAN';
                ApplicationArea = All;
                Image = TestDatabase;
                ToolTip = 'Перевіряє український IBAN, визначає ID НБУ та знаходить відповідний банк у довіднику.';

                trigger OnAction()
                var
                    IBANDialog: Page "SI IBAN Test Dialog";
                    BankResolver: Codeunit "SI Bank Resolver";
                    IBANMgt: Codeunit "SI IBAN Mgt.";
                    Bank: Record "SI Bank Directory";
                    IBAN: Text[100];
                    NBUId: Code[6];
                begin
                    if IBANDialog.RunModal() <> Action::OK then
                        exit;

                    IBAN := IBANDialog.GetIBAN();
                    NBUId := IBANMgt.GetNBUId(IBAN);

                    if not BankResolver.ResolveByIBAN(IBAN, Bank) then
                        Error(
                            'Для IBAN не знайдено банк з ID НБУ %1.',
                            NBUId);

                    CurrPage.Update(false);

                    Message(
                        'IBAN перевірено.\' +
                        'ID НБУ: %1\' +
                        'Банк: %2\' +
                        'МФО: %3\' +
                        'ЄДРПОУ: %4\' +
                        'Стан НБУ: %5\' +
                        'Ліцензія: %6',
                        NBUId,
                        Bank.Name,
                        Bank.MFO,
                        Bank.EDRPOU,
                        Bank."NBU Status Name",
                        Bank."License Status Name");
                end;
            }
        }
    }
}
