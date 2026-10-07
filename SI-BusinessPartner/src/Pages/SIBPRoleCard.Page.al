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

            action(Submit)
            {
                Caption = 'Передати на узгодження';
                ApplicationArea = All;
                Visible = false;
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
                Caption = 'Налаштувати та активувати роль';
                ApplicationArea = All;
                Image = Approve;
                Enabled = CanActivate;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    ActivationWizard: Page "SI BP Role Activation Wizard";
                    ActivationMgt: Codeunit "SI BP Role Activation Mgt.";
                    BPBankMgt: Codeunit "SI BP Bank Mgt.";
                    BankAccount: Record "SI BP Bank Account";
                    VATStatus: Enum "SI BP VAT Status";
                begin
                    // Banking details are a mandatory prerequisite for activation.
                    // If they are missing, complete the independent banking subflow first.
                    // Bank verification can write to the NBU directory and BP bank account,
                    // therefore commit that completed subflow before opening the activation
                    // wizard. This preserves the business order without RunModal-after-write.
                    if not BPBankMgt.HasVerifiedAccount(Rec) then begin
                        if not Confirm(
                            'Для активації ролі треба заповнити банківські реквізити. Зробити це зараз через онлайн-сервіс?',
                            false)
                        then
                            exit;

                        if not VerifyBankFromDialog(BankAccount) then
                            exit;

                        if not BPBankMgt.HasVerifiedAccount(Rec) then
                            Error(
                                'Банківські реквізити не були успішно створені та перевірені. Активацію ролі зупинено.');

                        Commit();
                    end;

                    ActivationWizard.SetRole(Rec);

                    if ActivationWizard.RunModal() <> Action::OK then
                        exit;

                    VATStatus := ActivationWizard.GetVATStatus();

                    ActivationMgt.ActivateRole(
                        Rec,
                        VATStatus);

                    CurrPage.Update(false);

                    Message(
                        'Роль успішно активовано. ERP-контрагента створено.');
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
            (Rec.Status = Rec.Status::Draft) or
            (Rec.Status = Rec.Status::Configured);

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


        IsCustomerRole :=
            Rec."Role Type" =
            Rec."Role Type"::Customer;

        IsVendorRole :=
            Rec."Role Type" =
            Rec."Role Type"::Vendor;

        CanEditBanking :=
            Rec.Status <>
            Rec.Status::Inactive;

        HasMaterializedERP :=
            ((Rec."Role Type" = Rec."Role Type"::Customer) and
             (Rec."Customer No." <> '')) or
            ((Rec."Role Type" = Rec."Role Type"::Vendor) and
             (Rec."Vendor No." <> ''));
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

    var
        CanSubmit: Boolean;
        CanReturnDraft: Boolean;
        CanActivate: Boolean;
        CanBlock: Boolean;
        CanUnblock: Boolean;
        CanDeactivate: Boolean;
        IsCustomerRole: Boolean;
        IsVendorRole: Boolean;
        CanEditBanking: Boolean;

        HasMaterializedERP: Boolean;
}