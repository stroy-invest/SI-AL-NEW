codeunit 54071 "SI BP Mat. Preflight"
{
    procedure ValidateRun(
        MatRun: Record "SI BP Materialization Run";
        var ErrorText: Text;
        var Details: Text): Boolean
    var
        Role: Record "SI BP Role";
        Projection: Record "SI BP ERP Projection";
    begin
        Clear(ErrorText);
        Clear(Details);

        if not Role.Get(MatRun."Role Code") then begin
            AddError(
                ErrorText,
                StrSubstNo(
                    'Роль %1 не знайдено.',
                    MatRun."Role Code"));

            exit(false);
        end;

        CheckRole(
            Role,
            ErrorText);

        CheckProjection(
            Role,
            Projection,
            ErrorText);

        CheckProjectedBankAccounts(
            Role,
            ErrorText);

        CheckStandardTemplateAvailability(
            Role,
            ErrorText);

        CheckERPNumberSeries(
            Role,
            ErrorText);

        CheckOppositeRole(
            Role,
            ErrorText,
            Details);

        if RequiresCompanyContact(Role) then
            CheckContactSetup(
                ErrorText);

        if ErrorText = '' then begin
            Details :=
                AppendLine(
                    Details,
                    'Pre-flight validation успішна.');

            Details :=
                AppendLine(
                    Details,
                    StrSubstNo(
                        'Роль: %1.',
                        Role.Code));

            Details :=
                AppendLine(
                    Details,
                    StrSubstNo(
                        'Тип ролі: %1.',
                        Format(Role."Role Type")));

            exit(true);
        end;

        exit(false);
    end;

    local procedure CheckRole(
        Role: Record "SI BP Role";
        var ErrorText: Text)
    begin
        if Role.Status <> Role.Status::Active then
            AddError(
                ErrorText,
                StrSubstNo(
                    'Роль %1 повинна мати стан Активна.',
                    Role.Code));

        if Role."Business Partner No." = '' then
            AddError(
                ErrorText,
                'У ролі не зазначено контрагента.');
    end;

    local procedure CheckProjection(
        Role: Record "SI BP Role";
        var Projection: Record "SI BP ERP Projection";
        var ErrorText: Text)
    begin
        if not Projection.Get(Role.Code) then begin
            AddError(
                ErrorText,
                StrSubstNo(
                    'Для ролі %1 не створено ERP-проєкцію.',
                    Role.Code));

            exit;
        end;

        if Projection.Status <>
           Projection.Status::Ready
        then
            AddError(
                ErrorText,
                StrSubstNo(
                    'ERP-проєкція ролі %1 повинна мати стан Готова. Поточний стан: %2.',
                    Role.Code,
                    Format(Projection.Status)));

        if Projection.Name = '' then
            AddError(
                ErrorText,
                'У ERP-проєкції не зазначено назву контрагента.');

        if Projection."Country/Region Code" = '' then
            AddError(
                ErrorText,
                'У ERP-проєкції не зазначено країну.');

        if Projection."Address City" = '' then
            AddError(
                ErrorText,
                'У ERP-проєкції не зазначено місто юридичної адреси.');

        if Projection."Address Street" = '' then
            AddError(
                ErrorText,
                'У ERP-проєкції не зазначено вулицю юридичної адреси.');
    end;

    local procedure CheckProjectedBankAccounts(
        Role: Record "SI BP Role";
        var ErrorText: Text)
    var
        ProjectionBank: Record "SI BP ERP Proj. Bank";
    begin
        ProjectionBank.SetRange(
            "Role Code",
            Role.Code);

        if ProjectionBank.IsEmpty() then
            AddError(
                ErrorText,
                'ERP-проєкція не містить жодного банківського рахунку.');
    end;

    local procedure CheckStandardTemplateAvailability(
        Role: Record "SI BP Role";
        var ErrorText: Text)
    var
        CustomerTempl: Record "Customer Templ.";
        VendorTempl: Record "Vendor Templ.";
    begin
        // Тимчасова Stage 1.3b перевірка:
        // до рефакторингу Stage 1.1 перевіряємо,
        // що стандартні шаблони відповідного типу взагалі налаштовані.
        //
        // Після введення Role."ERP Template Code"
        // цей check буде замінено на точний Get(template code).

        case Role."Role Type" of
            Role."Role Type"::Customer:
                if CustomerTempl.IsEmpty() then
                    AddError(
                        ErrorText,
                        'У Business Central не налаштовано жодного стандартного шаблону клієнта.');

            Role."Role Type"::Vendor:
                if VendorTempl.IsEmpty() then
                    AddError(
                        ErrorText,
                        'У Business Central не налаштовано жодного стандартного шаблону постачальника.');
        end;
    end;

    local procedure CheckERPNumberSeries(
        Role: Record "SI BP Role";
        var ErrorText: Text)
    var
        SalesSetup: Record "Sales & Receivables Setup";
        PurchasesSetup: Record "Purchases & Payables Setup";
        NoSeries: Record "No. Series";
    begin
        case Role."Role Type" of
            Role."Role Type"::Customer:
                begin
                    if not SalesSetup.Get() then begin
                        AddError(
                            ErrorText,
                            'Не знайдено Sales & Receivables Setup.');

                        exit;
                    end;

                    if SalesSetup."Customer Nos." = '' then begin
                        AddError(
                            ErrorText,
                            'У Sales & Receivables Setup не заповнено Customer Nos.');

                        exit;
                    end;

                    if not NoSeries.Get(
                        SalesSetup."Customer Nos.")
                    then
                        AddError(
                            ErrorText,
                            StrSubstNo(
                                'Серію номерів клієнтів %1 не знайдено.',
                                SalesSetup."Customer Nos."));
                end;

            Role."Role Type"::Vendor:
                begin
                    if not PurchasesSetup.Get() then begin
                        AddError(
                            ErrorText,
                            'Не знайдено Purchases & Payables Setup.');

                        exit;
                    end;

                    if PurchasesSetup."Vendor Nos." = '' then begin
                        AddError(
                            ErrorText,
                            'У Purchases & Payables Setup не заповнено Vendor Nos.');

                        exit;
                    end;

                    if not NoSeries.Get(
                        PurchasesSetup."Vendor Nos.")
                    then
                        AddError(
                            ErrorText,
                            StrSubstNo(
                                'Серію номерів постачальників %1 не знайдено.',
                                PurchasesSetup."Vendor Nos."));
                end;
        end;
    end;

    local procedure CheckContactSetup(
        var ErrorText: Text)
    var
        MarketingSetup: Record "Marketing Setup";
        BusinessRelation: Record "Business Relation";
        NoSeries: Record "No. Series";
    begin
        if not MarketingSetup.Get() then begin
            AddError(
                ErrorText,
                'Не знайдено Marketing Setup.');

            exit;
        end;

        if MarketingSetup."Contact Nos." = '' then
            AddError(
                ErrorText,
                'У Marketing Setup не заповнено Contact Nos.')
        else
            if not NoSeries.Get(
                MarketingSetup."Contact Nos.")
            then
                AddError(
                    ErrorText,
                    StrSubstNo(
                        'Серію номерів контактів %1 не знайдено.',
                        MarketingSetup."Contact Nos."));

        if MarketingSetup."Bus. Rel. Code for Customers" = '' then
            AddError(
                ErrorText,
                'У Marketing Setup не заповнено Bus. Rel. Code for Customers.')
        else
            if not BusinessRelation.Get(
                MarketingSetup."Bus. Rel. Code for Customers")
            then
                AddError(
                    ErrorText,
                    StrSubstNo(
                        'Business Relation %1 для клієнтів не знайдено.',
                        MarketingSetup."Bus. Rel. Code for Customers"));

        if MarketingSetup."Bus. Rel. Code for Vendors" = '' then
            AddError(
                ErrorText,
                'У Marketing Setup не заповнено Bus. Rel. Code for Vendors.')
        else
            if not BusinessRelation.Get(
                MarketingSetup."Bus. Rel. Code for Vendors")
            then
                AddError(
                    ErrorText,
                    StrSubstNo(
                        'Business Relation %1 для постачальників не знайдено.',
                        MarketingSetup."Bus. Rel. Code for Vendors"));
    end;

    local procedure CheckOppositeRole(
        Role: Record "SI BP Role";
        var ErrorText: Text;
        var Details: Text)
    var
        OppositeRole: Record "SI BP Role";
        OppositeProjection: Record "SI BP ERP Projection";
        Customer: Record Customer;
        Vendor: Record Vendor;
        ContactBusinessRelation: Record "Contact Business Relation";
        Contact: Record Contact;
        ContactNo: Code[20];
    begin
        if not GetOppositeRole(
            Role,
            OppositeRole)
        then begin
            Details :=
                AppendLine(
                    Details,
                    'Матеріалізованої протилежної ролі немає; Company Contact на цьому запуску не потрібний.');

            exit;
        end;

        if not OppositeProjection.Get(
            OppositeRole.Code)
        then begin
            AddError(
                ErrorText,
                StrSubstNo(
                    'Для протилежної ролі %1 відсутня ERP-проєкція.',
                    OppositeRole.Code));

            exit;
        end;

        if OppositeProjection.Status <>
           OppositeProjection.Status::Materialized
        then begin
            Details :=
                AppendLine(
                    Details,
                    StrSubstNo(
                        'Протилежна роль %1 існує, але ще не матеріалізована.',
                        OppositeRole.Code));

            exit;
        end;

        case OppositeRole."Role Type" of
            OppositeRole."Role Type"::Customer:
                begin
                    if OppositeRole."Customer No." = '' then begin
                        AddError(
                            ErrorText,
                            StrSubstNo(
                                'Матеріалізована роль %1 не містить Customer No.',
                                OppositeRole.Code));

                        exit;
                    end;

                    if not Customer.Get(
                        OppositeRole."Customer No.")
                    then begin
                        AddError(
                            ErrorText,
                            StrSubstNo(
                                'Клієнта %1 з матеріалізованої протилежної ролі не знайдено.',
                                OppositeRole."Customer No."));

                        exit;
                    end;

                    ContactNo :=
                        ContactBusinessRelation.GetContactNo(
                            Enum::"Contact Business Relation Link To Table"::Customer,
                            Customer."No.");
                end;

            OppositeRole."Role Type"::Vendor:
                begin
                    if OppositeRole."Vendor No." = '' then begin
                        AddError(
                            ErrorText,
                            StrSubstNo(
                                'Матеріалізована роль %1 не містить Vendor No.',
                                OppositeRole.Code));

                        exit;
                    end;

                    if not Vendor.Get(
                        OppositeRole."Vendor No.")
                    then begin
                        AddError(
                            ErrorText,
                            StrSubstNo(
                                'Постачальника %1 з матеріалізованої протилежної ролі не знайдено.',
                                OppositeRole."Vendor No."));

                        exit;
                    end;

                    ContactNo :=
                        ContactBusinessRelation.GetContactNo(
                            Enum::"Contact Business Relation Link To Table"::Vendor,
                            Vendor."No.");
                end;
        end;

        if ContactNo = '' then begin
            Details :=
                AppendLine(
                    Details,
                    'Протилежна ERP-роль матеріалізована, але ще не пов''язана зі стандартним Company Contact.');

            exit;
        end;

        if not Contact.Get(ContactNo) then begin
            AddError(
                ErrorText,
                StrSubstNo(
                    'Contact %1, пов''язаний із протилежною ERP-роллю, не знайдено.',
                    ContactNo));

            exit;
        end;

        if Contact.Type <> Contact.Type::Company then
            AddError(
                ErrorText,
                StrSubstNo(
                    'Contact %1 повинен мати Type = Company.',
                    ContactNo))
        else
            Details :=
                AppendLine(
                    Details,
                    StrSubstNo(
                        'Знайдено існуючий Company Contact %1; його можна буде повторно використати.',
                        ContactNo));
    end;

    local procedure RequiresCompanyContact(
        Role: Record "SI BP Role"): Boolean
    var
        OppositeRole: Record "SI BP Role";
        OppositeProjection: Record "SI BP ERP Projection";
    begin
        if not GetOppositeRole(
            Role,
            OppositeRole)
        then
            exit(false);

        if not OppositeProjection.Get(
            OppositeRole.Code)
        then
            exit(false);

        exit(
            OppositeProjection.Status =
            OppositeProjection.Status::Materialized);
    end;

    local procedure GetOppositeRole(
        Role: Record "SI BP Role";
        var OppositeRole: Record "SI BP Role"): Boolean
    begin
        OppositeRole.Reset();

        OppositeRole.SetRange(
            "Business Partner No.",
            Role."Business Partner No.");

        case Role."Role Type" of
            Role."Role Type"::Customer:
                OppositeRole.SetRange(
                    "Role Type",
                    OppositeRole."Role Type"::Vendor);

            Role."Role Type"::Vendor:
                OppositeRole.SetRange(
                    "Role Type",
                    OppositeRole."Role Type"::Customer);
        end;

        exit(
            OppositeRole.FindFirst());
    end;

    local procedure AddError(
        var ErrorText: Text;
        NewError: Text)
    begin
        if ErrorText = '' then
            ErrorText :=
                '• ' + NewError
        else
            ErrorText :=
                ErrorText + '\' +
                '• ' + NewError;
    end;

    local procedure AppendLine(
        ExistingText: Text;
        NewLine: Text): Text
    begin
        if ExistingText = '' then
            exit(NewLine);

        exit(
            ExistingText + '\' +
            NewLine);
    end;
}