codeunit 54050 "SI BP Bank Mgt."
{
    procedure HasVerifiedAccount(
        Role: Record "SI BP Role"): Boolean
    var
        BankAccount: Record "SI BP Bank Account";
    begin
        BankAccount.SetRange(
            "Role Code",
            Role.Code);

        BankAccount.SetRange(
            Active,
            true);

        BankAccount.SetRange(
            "Verification Status",
            BankAccount."Verification Status"::Verified);

        exit(not BankAccount.IsEmpty());
    end;

    procedure ValidateBankingReady(
        Role: Record "SI BP Role")
    begin
        if HasVerifiedAccount(Role) then
            exit;

        Error(
            'Для активації ролі %1 необхідно мати щонайменше один активний перевірений банківський рахунок.',
            Role.Code);
    end;

    [TryFunction]
    procedure TryVerifyAndUpsertAccount(
        Role: Record "SI BP Role";
        IBAN: Text;
        var BankAccount: Record "SI BP Bank Account")
    begin
        VerifyAndUpsertAccount(
            Role,
            IBAN,
            BankAccount);
    end;

    procedure VerifyAndUpsertAccount(
        Role: Record "SI BP Role";
        IBAN: Text;
        var BankAccount: Record "SI BP Bank Account")
    var
        IBANMgt: Codeunit "SI IBAN Mgt.";
        NBUBankSyncMgt: Codeunit "SI NBU Bank Sync Mgt.";
        BankDirectory: Record "SI Bank Directory";
        NormalizedIBAN: Text;
        NBUId: Code[20];
        IsNew: Boolean;
    begin
        Role.TestField(Code);

        if Role.Status in [Role.Status::Inactive, Role.Status::Closed] then
            Error(
                'Для неактивної ролі банківські реквізити змінювати не можна.');

        NormalizedIBAN :=
            IBANMgt.Normalize(IBAN);

        IBANMgt.ValidateUA(
            NormalizedIBAN);

        NBUId :=
            IBANMgt.GetNBUId(
                NormalizedIBAN);

        // Для верифікації перед активацією ролі
        // примусово актуалізуємо банк через НБУ.
        if not NBUBankSyncMgt.SyncBank(
            NBUId,
            BankDirectory)
        then
            Error(
                'Банк з ID НБУ %1 не знайдено в актуальній відповіді НБУ.',
                NBUId);

        if not BankDirectory.Active then
            Error(
                'Банк %1 (%2) не дозволено використовувати для нових банківських реквізитів.',
                BankDirectory.Name,
                BankDirectory."NBU ID");

        IsNew :=
            not FindByIBAN(
                Role.Code,
                NormalizedIBAN,
                BankAccount);

        if IsNew then begin
            BankAccount.Init();

            BankAccount."Role Code" :=
                Role.Code;

            BankAccount.Code :=
                GetNextCode(
                    Role.Code);

            BankAccount.IBAN :=
                CopyStr(
                    NormalizedIBAN,
                    1,
                    MaxStrLen(BankAccount.IBAN));

            // UA IBAN:
            // 1-2  Country Code
            // 3-4  Check digits
            // 5-10 NBU ID
            // 11-29 Account No.
            BankAccount."Account No." :=
                CopyStr(
                    NormalizedIBAN,
                    11,
                    MaxStrLen(
                        BankAccount."Account No."));

            BankAccount."Country/Region Code" :=
                'UA';

            BankAccount."Currency Code" :=
                GetRoleCurrency(Role);

            BankAccount.Active :=
                true;

            BankAccount.Primary :=
                not HasPrimaryAccount(
                    Role.Code,
                    BankAccount."Currency Code");
        end;

        ApplyBankDirectory(
            BankDirectory,
            BankAccount);

        BankAccount."Verification Status" :=
            BankAccount."Verification Status"::Verified;

        BankAccount."Verification Source" :=
            'NBU';

        BankAccount."Verified At" :=
            CurrentDateTime;

        BankAccount.Active :=
            true;

        if IsNew then
            BankAccount.Insert(true)
        else
            BankAccount.Modify(true);
    end;

    procedure GetNextCode(
        RoleCode: Code[30]): Code[20]
    var
        BankAccount: Record "SI BP Bank Account";
        MaxNo: Integer;
        CurrentNo: Integer;
        SuffixText: Text;
        NumberText: Text;
        ResultCode: Code[20];
    begin
        BankAccount.SetRange(
            "Role Code",
            RoleCode);

        if BankAccount.FindSet() then
            repeat
                if CopyStr(
                    BankAccount.Code,
                    1,
                    5) = 'BANK-'
                then begin
                    SuffixText :=
                        CopyStr(
                            BankAccount.Code,
                            6);

                    if Evaluate(
                        CurrentNo,
                        SuffixText)
                    then
                        if CurrentNo > MaxNo then
                            MaxNo :=
                                CurrentNo;
                end;
            until BankAccount.Next() = 0;

        MaxNo += 1;

        if MaxNo > 999999 then
            Error(
                'Для ролі %1 вичерпано діапазон кодів банківських рахунків.',
                RoleCode);

        NumberText :=
            Format(MaxNo);

        while StrLen(NumberText) < 6 do
            NumberText :=
                '0' + NumberText;

        ResultCode :=
            CopyStr(
                'BANK-' + NumberText,
                1,
                MaxStrLen(ResultCode));

        exit(ResultCode);
    end;

    local procedure FindByIBAN(
        RoleCode: Code[30];
        IBANValue: Text;
        var BankAccount: Record "SI BP Bank Account"): Boolean
    begin
        BankAccount.Reset();

        BankAccount.SetRange(
            "Role Code",
            RoleCode);

        BankAccount.SetRange(
            IBAN,
            IBANValue);

        exit(
            BankAccount.FindFirst());
    end;

    local procedure HasPrimaryAccount(
        RoleCode: Code[30];
        CurrencyCode: Code[10]): Boolean
    var
        BankAccount: Record "SI BP Bank Account";
    begin
        BankAccount.SetRange(
            "Role Code",
            RoleCode);

        BankAccount.SetRange(
            "Currency Code",
            CurrencyCode);

        BankAccount.SetRange(
            Primary,
            true);

        exit(
            not BankAccount.IsEmpty());
    end;

    local procedure GetRoleCurrency(
        Role: Record "SI BP Role"): Code[10]
    var
        CustSetup: Record "SI BP Cust. Role Setup";
        VendSetup: Record "SI BP Vend. Role Setup";
        BusinessPartner: Record "SI Business Partner";
    begin
        case Role."Role Type" of
            Role."Role Type"::Customer:
                if CustSetup.Get(
                    Role.Code)
                then
                    if CustSetup."Currency Code" <> '' then
                        exit(
                            CustSetup."Currency Code");

            Role."Role Type"::Vendor:
                if VendSetup.Get(
                    Role.Code)
                then
                    if VendSetup."Currency Code" <> '' then
                        exit(
                            VendSetup."Currency Code");
        end;

        if BusinessPartner.Get(
            Role."Business Partner No.")
        then
            exit(
                BusinessPartner."Currency Code");

        exit('');
    end;

    local procedure ApplyBankDirectory(
        BankDirectory: Record "SI Bank Directory";
        var BankAccount: Record "SI BP Bank Account")
    begin
        BankAccount."NBU ID" :=
            CopyStr(
                BankDirectory."NBU ID",
                1,
                MaxStrLen(
                    BankAccount."NBU ID"));

        BankAccount.MFO :=
            CopyStr(
                BankDirectory.MFO,
                1,
                MaxStrLen(
                    BankAccount.MFO));

        BankAccount."Bank EDRPOU" :=
            CopyStr(
                BankDirectory.EDRPOU,
                1,
                MaxStrLen(
                    BankAccount."Bank EDRPOU"));

        BankAccount."Bank Name" :=
            CopyStr(
                BankDirectory.Name,
                1,
                MaxStrLen(
                    BankAccount."Bank Name"));

        BankAccount."Bank Full Name" :=
            CopyStr(
                BankDirectory."Full Name",
                1,
                MaxStrLen(
                    BankAccount."Bank Full Name"));

        BankAccount."Bank Address" :=
            CopyStr(
                BankDirectory.Address,
                1,
                MaxStrLen(
                    BankAccount."Bank Address"));

        BankAccount."Bank City" :=
            CopyStr(
                BankDirectory.City,
                1,
                MaxStrLen(
                    BankAccount."Bank City"));

        BankAccount."Bank Postal Code" :=
            CopyStr(
                BankDirectory."Postal Code",
                1,
                MaxStrLen(
                    BankAccount."Bank Postal Code"));

        BankAccount."Bank Phone" :=
            CopyStr(
                BankDirectory.Phone,
                1,
                MaxStrLen(
                    BankAccount."Bank Phone"));

        BankAccount."Bank Website" :=
            CopyStr(
                BankDirectory.Website,
                1,
                MaxStrLen(
                    BankAccount."Bank Website"));

        BankAccount."NBU Status Name" :=
            CopyStr(
                BankDirectory."NBU Status Name",
                1,
                MaxStrLen(
                    BankAccount."NBU Status Name"));

        BankAccount."License Status Name" :=
            CopyStr(
                BankDirectory."License Status Name",
                1,
                MaxStrLen(
                    BankAccount."License Status Name"));
    end;
}