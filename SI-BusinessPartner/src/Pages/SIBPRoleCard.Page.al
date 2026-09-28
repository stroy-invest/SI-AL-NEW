page 54031 "SI BP Role Card"
{
    PageType = Card;
    SourceTable = "SI BP Role";

    Caption = 'Роль контрагента';
    ApplicationArea = All;

    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Загальні дані';

                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field("Business Partner No."; Rec."Business Partner No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field("Role Type"; Rec."Role Type")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field("ERP Template Code"; Rec."ERP Template Code")
                {
                    ApplicationArea = All;
                    Caption = 'Шаблон BC';
                    Editable = false;
                    ToolTip = 'Стандартний шаблон Business Central, який буде застосовано під час матеріалізації ERP-сутності.';
                }
            }

            group(Banking)
            {
                Caption = 'Банківські реквізити';

                part(BankAccounts; "SI BP Bank Accounts Part")
                {
                    ApplicationArea = All;
                    SubPageLink = "Role Code" = field(Code);
                }
            }

            group(CreatedCustomer)
            {
                Caption = 'Створений клієнт';
                Visible = IsCustomerRole and HasMaterializedERP;

                part(CustomerProjectionSummary; "SI BP ERP Projection Part")
                {
                    ApplicationArea = All;
                    SubPageLink = Code = field(Code);
                }
            }

            group(CreatedVendor)
            {
                Caption = 'Створений постачальник';
                Visible = IsVendorRole and HasMaterializedERP;

                part(VendorProjectionSummary; "SI BP ERP Projection Part")
                {
                    ApplicationArea = All;
                    SubPageLink = Code = field(Code);
                }
            }

            group(Audit)
            {
                Caption = 'Історія';

                field("Created At"; Rec."Created At")
                {
                    ApplicationArea = All;
                }

                field("Created By"; Rec."Created By")
                {
                    ApplicationArea = All;
                }

                field("Last Changed At"; Rec."Last Changed At")
                {
                    ApplicationArea = All;
                }

                field("Last Changed By"; Rec."Last Changed By")
                {
                    ApplicationArea = All;
                }

                field("Last Activated At"; Rec."Last Activated At")
                {
                    ApplicationArea = All;
                }

                field("Last Inactivated At"; Rec."Last Inactivated At")
                {
                    ApplicationArea = All;
                }

                field("Closed At"; Rec."Closed At")
                {
                    ApplicationArea = All;
                }
            }

            part(History; "SI BP Role History")
            {
                ApplicationArea = All;
                SubPageLink = "Role Code" = field(Code);
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(AddBankAccount)
            {
                Caption = 'Додати банківський рахунок';
                ApplicationArea = All;
                Enabled = CanEditBanking;

                trigger OnAction()
                var
                    BankAccount: Record "SI BP Bank Account";
                begin
                    if not VerifyBankFromDialog(BankAccount) then
                        exit;

                    CurrPage.Update(false);

                    ShowBankVerificationResult(
                        BankAccount,
                        false);
                end;
            }

            action(CreateMaterializationRun)
            {
                Caption = 'Створити запуск матеріалізації';
                ApplicationArea = All;
                Enabled = CanCreateMatRun;

                trigger OnAction()
                var
                    MatMgt: Codeunit "SI BP Materialization Mgt.";
                    MatRun: Record "SI BP Materialization Run";
                begin
                    MatMgt.CreateRun(
                        Rec,
                        MatRun);

                    Page.Run(
                        Page::"SI BP Mat. Run Card",
                        MatRun);
                end;
            }

            action(CreateERPProjection)
            {
                Caption = 'Створити ERP-проєкцію';
                ApplicationArea = All;
                Enabled = CanCreateProjection;

                trigger OnAction()
                var
                    ProjectionMgt: Codeunit "SI BP Projection Mgt.";
                    Projection: Record "SI BP ERP Projection";
                begin
                    ProjectionMgt.CreateProjection(
                        Rec,
                        Projection);

                    CurrPage.Update(false);

                    Page.Run(
                        Page::"SI BP Projection Card",
                        Projection);
                end;
            }

            action(ViewERPProjection)
            {
                Caption = 'Переглянути проєкцію';
                ApplicationArea = All;
                Enabled = CanViewProjection;

                trigger OnAction()
                var
                    Projection: Record "SI BP ERP Projection";
                begin
                    if not Projection.Get(Rec.Code) then
                        exit;

                    Page.Run(
                        Page::"SI BP Projection Card",
                        Projection);
                end;
            }

            action(DeleteERPProjection)
            {
                Caption = 'Видалити проєкцію';
                ApplicationArea = All;
                Enabled = CanDeleteProjection;

                trigger OnAction()
                var
                    ProjectionMgt: Codeunit "SI BP Projection Mgt.";
                begin
                    Rec.CalcFields(
                        "Business Partner Name");

                    if not Confirm(
                        'Видалити нематеріалізовану ERP-проєкцію ролі контрагента %1? Проєкцію можна буде сформувати повторно з актуальних даних ролі.',
                        false,
                        Rec."Business Partner Name")
                    then
                        exit;

                    ProjectionMgt.DeleteProjection(
                        Rec.Code);

                    CurrPage.Update(false);
                end;
            }

            action(MaterializeERPProjection)
            {
                Caption = 'Матеріалізувати проєкцію';
                ApplicationArea = All;
                Enabled = CanMaterializeProjection;

                trigger OnAction()
                var
                    ProjectionMgt: Codeunit "SI BP Projection Mgt.";
                    Projection: Record "SI BP ERP Projection";
                    ERPTypeCaption: Text;
                begin
                    if not Projection.Get(Rec.Code) then
                        Error(
                            'ERP-проєкцію не знайдено.');

                    Rec.CalcFields(
                        "Business Partner Name");

                    ERPTypeCaption :=
                        GetERPTypeCaption();

                    if not Confirm(
                        'Матеріалізувати проєкцію ролі контрагента %1 та створити нового %2?',
                        false,
                        Rec."Business Partner Name",
                        ERPTypeCaption)
                    then
                        exit;

                    ProjectionMgt.MaterializeProjection(
                        Projection);

                    CurrPage.Update(false);

                    Message(
                        'ERP-проєкцію успішно матеріалізовано. Створено %1 %2.',
                        ERPTypeCaption,
                        Projection."ERP No.");
                end;
            }

            action(Submit)
            {
                Caption = 'Передати на узгодження';
                ApplicationArea = All;
                Image = SendApprovalRequest;
                Enabled = CanSubmit;

                trigger OnAction()
                var
                    RoleMgt: Codeunit "SI BP Role Mgt.";
                begin
                    RoleMgt.SubmitRole(
                        Rec,
                        '',
                        '');

                    CurrPage.Update(false);
                end;
            }

            action(ReturnDraft)
            {
                Caption = 'Повернути в чернетку';
                ApplicationArea = All;
                Image = ReOpen;
                Enabled = CanReturnDraft;

                trigger OnAction()
                var
                    RoleMgt: Codeunit "SI BP Role Mgt.";
                    Reason: Text;
                    Comment: Text;
                begin
                    if not GetChangeData(
                        Reason,
                        Comment)
                    then
                        exit;

                    RoleMgt.ReturnToDraft(
                        Rec,
                        Reason,
                        Comment);

                    CurrPage.Update(false);
                end;
            }

            action(Activate)
            {
                Caption = 'Активувати';
                ApplicationArea = All;
                Image = Approve;
                Enabled = CanActivate;

                trigger OnAction()
                var
                    RoleMgt: Codeunit "SI BP Role Mgt.";
                    BPBankMgt: Codeunit "SI BP Bank Mgt.";
                    BankAccount: Record "SI BP Bank Account";
                    BankVerifiedNow: Boolean;
                begin
                    if not BPBankMgt.HasVerifiedAccount(Rec) then begin
                        if not Confirm(
                            'Для активації ролі треба заповнити банківські реквізити. Зробити це зараз через онлайн-сервіс?',
                            false)
                        then
                            exit;

                        if not VerifyBankFromDialog(
                            BankAccount)
                        then
                            exit;

                        BankVerifiedNow :=
                            true;
                    end;

                    RoleMgt.ActivateRole(
                        Rec,
                        '',
                        '');

                    CurrPage.Update(false);

                    if BankVerifiedNow then
                        ShowBankVerificationResult(
                            BankAccount,
                            true)
                    else
                        ShowRoleActivationResult();
                end;
            }

            action(Block)
            {
                Caption = 'Заблокувати';
                ApplicationArea = All;
                Enabled = CanBlock;

                trigger OnAction()
                var
                    RoleMgt: Codeunit "SI BP Role Mgt.";
                    Reason: Text;
                    Comment: Text;
                begin
                    if not GetChangeData(
                        Reason,
                        Comment)
                    then
                        exit;

                    RoleMgt.BlockRole(
                        Rec,
                        Reason,
                        Comment);

                    CurrPage.Update(false);
                end;
            }

            action(Unblock)
            {
                Caption = 'Розблокувати';
                ApplicationArea = All;
                Image = UnLinkAccount;
                Enabled = CanUnblock;

                trigger OnAction()
                var
                    RoleMgt: Codeunit "SI BP Role Mgt.";
                begin
                    RoleMgt.UnblockRole(
                        Rec,
                        '',
                        '');

                    CurrPage.Update(false);
                end;
            }

            action(Deactivate)
            {
                Caption = 'Деактивувати';
                ApplicationArea = All;
                Image = Cancel;
                Enabled = CanDeactivate;

                trigger OnAction()
                var
                    RoleMgt: Codeunit "SI BP Role Mgt.";
                    Reason: Text;
                    Comment: Text;
                begin
                    if not GetChangeData(
                        Reason,
                        Comment)
                    then
                        exit;

                    RoleMgt.DeactivateRole(
                        Rec,
                        Reason,
                        Comment);

                    CurrPage.Update(false);
                end;
            }

            action(Reactivate)
            {
                Caption = 'Відновити співпрацю';
                ApplicationArea = All;
                Image = ReOpen;
                Enabled = CanReactivate;

                trigger OnAction()
                var
                    RoleMgt: Codeunit "SI BP Role Mgt.";
                begin
                    RoleMgt.ReactivateRole(
                        Rec,
                        '',
                        '');

                    CurrPage.Update(false);
                end;
            }

            action(CloseRole)
            {
                Caption = 'Закрити роль';
                ApplicationArea = All;
                Image = Close;
                Enabled = CanClose;

                trigger OnAction()
                var
                    RoleMgt: Codeunit "SI BP Role Mgt.";
                    Reason: Text;
                    Comment: Text;
                begin
                    if not Confirm(
                        'Закрита роль більше не може бути активована. Продовжити?',
                        false)
                    then
                        exit;

                    if not GetChangeData(
                        Reason,
                        Comment)
                    then
                        exit;

                    RoleMgt.CloseRole(
                        Rec,
                        Reason,
                        Comment);

                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SetActionStates();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        SetActionStates();
    end;

    local procedure SetActionStates()
    begin
        CanSubmit :=
            Rec.Status =
            Rec.Status::Draft;

        CanReturnDraft :=
            Rec.Status =
            Rec.Status::Configured;

        CanActivate :=
            Rec.Status =
            Rec.Status::Configured;

        CanBlock :=
            Rec.Status =
            Rec.Status::Active;

        CanUnblock :=
            Rec.Status =
            Rec.Status::Blocked;

        CanDeactivate :=
            (Rec.Status =
             Rec.Status::Active) or
            (Rec.Status =
             Rec.Status::Blocked);

        CanReactivate :=
            Rec.Status =
            Rec.Status::Inactive;

        CanClose :=
            (Rec.Status =
             Rec.Status::Active) or
            (Rec.Status =
             Rec.Status::Blocked) or
            (Rec.Status =
             Rec.Status::Inactive);

        IsCustomerRole :=
            Rec."Role Type" =
            Rec."Role Type"::Customer;

        IsVendorRole :=
            Rec."Role Type" =
            Rec."Role Type"::Vendor;

        CanEditBanking :=
            Rec.Status <>
            Rec.Status::Closed;

        CanCreateMatRun :=
            CanCreateMaterializationRun();

        SetProjectionActionStates();
    end;

    local procedure CanCreateMaterializationRun(): Boolean
    var
        Projection: Record "SI BP ERP Projection";
        MatRun: Record "SI BP Materialization Run";
        MatMgt: Codeunit "SI BP Materialization Mgt.";
    begin
        if Rec.Status <> Rec.Status::Active then
            exit(false);

        if not Projection.Get(Rec.Code) then
            exit(false);

        if Projection.Status <> Projection.Status::Ready then
            exit(false);

        if MatMgt.GetOpenRun(
            Rec.Code,
            MatRun)
        then
            exit(false);

        exit(true);
    end;

    local procedure SetProjectionActionStates()
    var
        Projection: Record "SI BP ERP Projection";
    begin
        HasProjection :=
            Projection.Get(
                Rec.Code);

        HasMaterializedERP :=
            HasProjection and
            (Projection.Status = Projection.Status::Materialized) and
            (Projection."ERP No." <> '');

        CanCreateProjection :=
            (Rec.Status =
             Rec.Status::Active) and
            (not HasProjection);

        CanViewProjection :=
            HasProjection;

        CanDeleteProjection :=
            HasProjection and
            (Projection.Status <>
             Projection.Status::Materialized);

        CanMaterializeProjection :=
            HasProjection and
            (Projection.Status =
             Projection.Status::Ready);
    end;

    local procedure GetChangeData(
        var Reason: Text;
        var Comment: Text): Boolean
    var
        ChangeDialog: Page "SI BP Role Change Dialog";
    begin
        if ChangeDialog.RunModal() <>
           Action::OK
        then
            exit(false);

        Reason :=
            ChangeDialog.GetReason();

        Comment :=
            ChangeDialog.GetComment();

        exit(true);
    end;

    local procedure VerifyBankFromDialog(
        var BankAccount: Record "SI BP Bank Account"): Boolean
    var
        IBANDialog: Page "SI BP Bank IBAN Dialog";
        BPBankMgt: Codeunit "SI BP Bank Mgt.";
        IBAN: Text;
        ErrorDetails: Text;
    begin
        if IBANDialog.RunModal() <>
           Action::OK
        then
            exit(false);

        IBAN :=
            IBANDialog.GetIBAN();

        ClearLastError();

        if not BPBankMgt.TryVerifyAndUpsertAccount(
            Rec,
            IBAN,
            BankAccount)
        then begin
            ErrorDetails :=
                GetLastErrorText();

            Message(
                'Під час верифікації IBAN сталася помилка. Перевірте дані банківських реквізитів ролі %1.\Деталі: %2',
                Format(Rec."Role Type"),
                ErrorDetails);

            exit(false);
        end;

        exit(true);
    end;

    local procedure ShowBankVerificationResult(
        BankAccount: Record "SI BP Bank Account";
        RoleActivated: Boolean)
    begin
        if RoleActivated then
            Message(
                'Банківські реквізити ролі %1 успішно перевірено. Роль активовано.\' +
                'Банк: %2\' +
                'ID НБУ / МФО: %3 / %4\' +
                'ЄДРПОУ банку: %5\' +
                'Стан НБУ: %6\' +
                'Ліцензія: %7',
                Format(Rec."Role Type"),
                BankAccount."Bank Name",
                BankAccount."NBU ID",
                BankAccount.MFO,
                BankAccount."Bank EDRPOU",
                BankAccount."NBU Status Name",
                BankAccount."License Status Name")
        else
            Message(
                'Банківські реквізити ролі %1 успішно перевірено.\' +
                'Банк: %2\' +
                'ID НБУ / МФО: %3 / %4\' +
                'ЄДРПОУ банку: %5\' +
                'Стан НБУ: %6\' +
                'Ліцензія: %7',
                Format(Rec."Role Type"),
                BankAccount."Bank Name",
                BankAccount."NBU ID",
                BankAccount.MFO,
                BankAccount."Bank EDRPOU",
                BankAccount."NBU Status Name",
                BankAccount."License Status Name");
    end;

    local procedure ShowRoleActivationResult()
    begin
        case Rec."Role Type" of
            Rec."Role Type"::Customer:
                Message('Роль покупця успішно активовано.');

            Rec."Role Type"::Vendor:
                Message('Роль постачальника успішно активовано.');

            else
                Message('Роль успішно активовано.');
        end;
    end;

    local procedure GetERPTypeCaption(): Text
    begin
        case Rec."Role Type" of
            Rec."Role Type"::Customer:
                exit('Покупця');

            Rec."Role Type"::Vendor:
                exit('Постачальника');
        end;

        exit('ERP-запис');
    end;

    var
        CanSubmit: Boolean;
        CanReturnDraft: Boolean;
        CanActivate: Boolean;
        CanBlock: Boolean;
        CanUnblock: Boolean;
        CanDeactivate: Boolean;
        CanReactivate: Boolean;
        CanClose: Boolean;
        IsCustomerRole: Boolean;
        IsVendorRole: Boolean;
        CanEditBanking: Boolean;

        HasProjection: Boolean;
        HasMaterializedERP: Boolean;
        CanCreateProjection: Boolean;
        CanViewProjection: Boolean;
        CanDeleteProjection: Boolean;
        CanMaterializeProjection: Boolean;
        CanCreateMatRun: Boolean;
}