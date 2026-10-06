page 54004 "SI Business Partner Card"
{
    PageType = Card;
    SourceTable = "SI Business Partner";
    ApplicationArea = All;
    UsageCategory = None;
    Caption = 'Контрагент';
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Загальні дані';

                group(GeneralIdentity)
                {
                    ShowCaption = false;

                    field("Entity Type"; Rec."Entity Type")
                    {
                        ApplicationArea = All;
                        Caption = 'Тип контрагента';
                        ToolTip = 'Визначає тип контрагента: юридична особа, фізична особа-підприємець або фізична особа без статусу підприємця.';
                        Editable = IsDraft;
                        ShowMandatory = true;

                        trigger OnValidate()
                        begin
                            UpdatePageState();
                            CurrPage.Update(false);
                        end;
                    }

                    field("Country/Region Code"; Rec."Country/Region Code")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the jurisdiction in which the business partner is registered.';
                        Editable = IsDraft;
                        ShowMandatory = true;

                        trigger OnValidate()
                        begin
                            UpdatePageState();
                            CurrPage.Update(false);
                        end;
                    }

                    field("Currency Code"; Rec."Currency Code")
                    {
                        ApplicationArea = All;
                        Caption = 'Валюта контрагента';
                        ToolTip = 'Визначає типову валюту контрагента. Вона використовується за замовчуванням для налаштувань ролей клієнта та постачальника.';
                    }
                }

                group(GeneralStatus)
                {
                    ShowCaption = false;

                    field("Registration No."; Rec."Registration No.")
                    {
                        ApplicationArea = All;
                        Caption = 'ЄДРПОУ';
                        ToolTip = 'Код ЄДРПОУ юридичної особи. Для фізичної особи-підприємця не застосовується.';
                        Editable = IsDraft and IsLegalEntity;
                        ShowMandatory = IsLegalEntity;

                        trigger OnValidate()
                        begin
                            // A BP Address is a child record with a real FK to SI Business Partner.
                            // The card uses DelayedInsert, so persist the Draft as soon as the
                            // minimum identity required by SI BP Validator is complete.
                            if Rec."Registration No." <> '' then
                                CurrPage.SaveRecord();

                            UpdatePageState();
                            CurrPage.Update(false);
                        end;
                    }

                    field("Tax Registration No."; Rec."Tax Registration No.")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the tax registration number of the business partner.';
                        Editable = IsDraft;
                        ShowMandatory = IsIndividualEntrepreneur;

                        trigger OnValidate()
                        begin
                            if IsIndividualEntrepreneur and (Rec."Tax Registration No." <> '') then
                                CurrPage.SaveRecord();
                            UpdatePageState();
                            CurrPage.Update(false);
                        end;
                    }

                    field(Status; Rec.Status)
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the current status of the business partner.';
                        Editable = false;
                        StyleExpr = StatusStyle;
                    }
                }
            }

            group(LegalIdentity)
            {
                Caption = 'Юридична ідентифікація';

                group(LegalIdentityMain)
                {
                    ShowCaption = false;

                    field("Local Legal Form Code"; Rec."Local Legal Form Code")
                    {
                        ApplicationArea = All;
                        Caption = 'Офіційна юридична форма';
                        ToolTip = 'Specifies the legal form used in the selected country or region.';
                        Editable = IsDraft;
                        ShowMandatory = IsLegalEntity;
                        Visible = IsLegalEntity;
                    }

                    field("Full Legal Form"; Rec."Full Legal Form")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the full country-specific legal form resolved from the selected country legal form.';
                        Editable = false;
                        Visible = IsLegalEntity;
                    }

                    field(LegalFormGroupDescription; LegalFormGroupDescription)
                    {
                        ApplicationArea = All;
                        Caption = 'Група';
                        ToolTip = 'Specifies the legal form group to which the selected legal form belongs.';
                        Editable = false;
                        Visible = IsLegalEntity;
                    }
                }

                group(LegalIdentityNames)
                {
                    ShowCaption = false;

                    field(Name; Rec.Name)
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies only the business partner name, without the legal form and without quotation marks.';
                        Editable = IsDraft;
                        ShowMandatory = true;
                    }

                    field("Short Name BK"; Rec."Short Name BK")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the accountant-facing short name generated from the name and the abbreviated country legal form.';
                        Editable = false;
                    }
                }
            }

            group(RegistryData)
            {
                Caption = 'Дані реєстру';

                field("Registry Legal Name"; Rec."Registry Legal Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Офіційна юридична назва, отримана з реєстру.';
                }
                field("Registry Short Name"; Rec."Registry Short Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Скорочена назва, отримана з реєстру.';
                }
                field("Registry Status"; Rec."Registry Status")
                {
                    ApplicationArea = All;
                    ToolTip = 'Поточний статус контрагента за даними реєстру.';
                }
                field("Main KVED No."; Rec."Main KVED No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Код основного виду економічної діяльності за даними реєстру.';
                }
                field("Main KVED Description"; Rec."Main KVED Description")
                {
                    ApplicationArea = All;
                    ToolTip = 'Основний вид економічної діяльності за даними реєстру.';
                }
                field("Registry Data Actual At"; Rec."Registry Data Actual At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Дата й час актуальності отриманих реєстрових даних.';
                }
                field("Registry Provider Code"; Rec."Registry Provider Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Реєстровий сервіс, з якого фактично отримано дані.';
                }
            }

            group(Manager)
            {
                Caption = 'Керівник';

                field("Manager Name"; Rec."Manager Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'ПІБ керівника за даними реєстру. Для ФОП — ПІБ самого підприємця.';
                }
                field("Manager Role"; Rec."Manager Role")
                {
                    ApplicationArea = All;
                    ToolTip = 'Посада або роль керівника за даними реєстру.';
                }
                field("Manager Appointed At"; Rec."Manager Appointed At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Дата призначення керівника за даними реєстру.';
                }
                field("Manager Authority"; Rec."Manager Authority")
                {
                    ApplicationArea = All;
                    MultiLine = true;
                    ToolTip = 'Відомості про повноваження керівника за даними реєстру.';
                }
            }

            group(Addresses)
            {
                Caption = 'Адреси';

                part(BPAddresses; "SI BP Addresses Part")
                {
                    ApplicationArea = All;
                    SubPageLink = "Business Partner No." = field("No.");
                    UpdatePropagation = Both;
                    Editable = IsDraft;
                }
            }

        }
    }

    actions
    {
        area(Processing)
        {
            group(RoleManagement)
            {
                Caption = 'Ролі';

                action(CreateCustomerRole)
                {
                    Caption = 'Створити роль покупця';
                    ApplicationArea = All;
                    ToolTip = 'Створює для поточного контрагента роль покупця.';
                    Enabled = CanCreateCustomerRole;

                    trigger OnAction()
                    var
                        RoleMgt: Codeunit "SI BP Role Mgt.";
                        NewRole: Record "SI BP Role";
                    begin
                        CurrPage.SaveRecord();
                        Rec.TestField("No.");

                        RoleMgt.CreateRole(
                            Rec."No.",
                            Enum::"SI BP Role Type"::Customer,
                            NewRole);

                        Page.Run(
                            Page::"SI BP Role Card",
                            NewRole);
                    end;
                }

                action(CreateVendorRole)
                {
                    Caption = 'Створити роль постачальника';
                    ApplicationArea = All;
                    ToolTip = 'Створює для поточного контрагента роль постачальника.';
                    Enabled = CanCreateVendorRole;

                    trigger OnAction()
                    var
                        RoleMgt: Codeunit "SI BP Role Mgt.";
                        NewRole: Record "SI BP Role";
                    begin
                        CurrPage.SaveRecord();
                        Rec.TestField("No.");

                        RoleMgt.CreateRole(
                            Rec."No.",
                            Enum::"SI BP Role Type"::Vendor,
                            NewRole);

                        Page.Run(
                            Page::"SI BP Role Card",
                            NewRole);
                    end;
                }

                action(OpenRoles)
                {
                    Caption = 'Ролі контрагента';
                    ApplicationArea = All;
                    ToolTip = 'Відкриває ролі поточного контрагента.';

                    trigger OnAction()
                    var
                        BPRole: Record "SI BP Role";
                    begin
                        CurrPage.SaveRecord();
                        Rec.TestField("No.");

                        BPRole.SetRange(
                            "Business Partner No.",
                            Rec."No.");

                        Page.Run(
                            Page::"SI BP Roles",
                            BPRole);
                    end;
                }
            }

            action(GetRegistryData)
            {
                ApplicationArea = All;
                Caption = 'Отримати дані з реєстру';
                ToolTip = 'Отримує актуальні дані українського контрагента з реєстру та оновлює дані Business Partner.';
                Image = Check;
                Enabled = CanGetRegistryData;

                trigger OnAction()
                var
                    EDRPOURegistryMgt: Codeunit "SI EDRPOU Registry Mgt.";
                    RegistryResult: Record "SI Registry Result" temporary;
                    BackgroundRefreshQueued: Boolean;
                begin
                    CurrPage.SaveRecord();
                    if not EDRPOURegistryMgt.CheckAndMaterialize(Rec, RegistryResult, BackgroundRefreshQueued) then
                        exit;

                    CurrPage.Update(false);

                    if BackgroundRefreshQueued then begin
                        Message(CurrentDataBackgroundRefreshMsg, Rec."Registry Provider Code");
                        exit;
                    end;

                    if RegistryResult.FindFirst() and RegistryResult."Fallback Used" then
                        Message(FallbackSuccessMsg, RegistryResult."Provider Code", RegistryResult."Primary Failure Reason")
                    else
                        Message(SuccessMsg, Rec."Registry Provider Code");
                end;
            }
        }

        area(Navigation)
        {
            action(CountryLegalForms)
            {
                ApplicationArea = All;
                Caption = 'Юридичні форми країн';
                ToolTip = 'Open the list of country-specific legal forms.';
                Image = List;
                RunObject = page "SI Country Legal Forms";
            }

            action(LegalForms)
            {
                ApplicationArea = All;
                Caption = 'Юридичні форми';
                ToolTip = 'Open the list of normalized corporate legal forms.';
                Image = List;
                RunObject = page "SI Legal Forms";
            }
        }

        area(Promoted)
        {
            actionref(GetRegistryDataPromoted; GetRegistryData)
            {
            }

            group(CreateRolePromoted)
            {
                Caption = 'Створити роль';
                ShowAs = SplitButton;

                actionref(CreateCustomerRolePromoted; CreateCustomerRole)
                {
                }

                actionref(CreateVendorRolePromoted; CreateVendorRole)
                {
                }
            }

            actionref(CountryLegalFormsPromoted; CountryLegalForms)
            {
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        UpdatePageState();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdatePageState();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        IsDraft := true;
        StatusStyle := 'Standard';

        if Rec."Entity Type" = Rec."Entity Type"::" " then
            Rec.Validate(
                "Entity Type",
                "SI BP Entity Type"::"Legal Entity");

        if Rec."Country/Region Code" = '' then
            Rec.Validate(
                "Country/Region Code",
                'UA');

        UpdatePageState();
    end;

    local procedure UpdatePageState()
    var
        EDRPOURegistryMgt: Codeunit "SI EDRPOU Registry Mgt.";
        BPRole: Record "SI BP Role";
    begin
        IsDraft := Rec.Status = Rec.Status::Draft;
        IsLegalEntity := Rec."Entity Type" = Rec."Entity Type"::"Legal Entity";
        IsIndividualEntrepreneur := Rec."Entity Type" = Rec."Entity Type"::"Individual Entrepreneur";
        CanGetRegistryData := EDRPOURegistryMgt.IsCheckAvailable(Rec);

        CanCreateCustomerRole := not HasRole(BPRole, Enum::"SI BP Role Type"::Customer);
        CanCreateVendorRole := not HasRole(BPRole, Enum::"SI BP Role Type"::Vendor);
        UpdateLegalFormGroupDescription();

        case Rec.Status of
            Rec.Status::Draft:
                StatusStyle := 'Standard';

            Rec.Status::Active:
                StatusStyle := 'Favorable';

            Rec.Status::Blocked:
                StatusStyle := 'Unfavorable';

            Rec.Status::Archived:
                StatusStyle := 'Subordinate';
        end;
    end;


    local procedure UpdateLegalFormGroupDescription()
    var
        LegalForm: Record "SI Legal Form";
    begin
        Clear(LegalFormGroupDescription);

        if Rec."Legal Form Code" = '' then
            exit;

        if not LegalForm.Get(Rec."Legal Form Code") then
            exit;

        LegalForm.CalcFields("Legal Form Group Desc.");
        LegalFormGroupDescription := LegalForm."Legal Form Group Desc.";
    end;

    local procedure HasRole(
        var BPRole: Record "SI BP Role";
        RoleType: Enum "SI BP Role Type"): Boolean
    begin
        if Rec."No." = '' then
            exit(false);

        BPRole.Reset();
        BPRole.SetRange("Business Partner No.", Rec."No.");
        BPRole.SetRange("Role Type", RoleType);

        exit(not BPRole.IsEmpty());
    end;

    var
        CanGetRegistryData: Boolean;
        IsLegalEntity: Boolean;
        IsIndividualEntrepreneur: Boolean;
        CanCreateCustomerRole: Boolean;
        CanCreateVendorRole: Boolean;
        IsDraft: Boolean;
        LegalFormGroupDescription: Text[100];
        StatusStyle: Text;
        SuccessMsg: Label 'Дані контрагента успішно отримано з реєстру %1.';
        CurrentDataBackgroundRefreshMsg: Label 'Отримано останні доступні дані з реєстру %1. YouScore продовжує актуалізацію у фоні. Після її завершення дані контрагента будуть оновлені автоматично.';
        FallbackSuccessMsg: Label 'Дані отримано з резервного реєстрового сервісу %1. Основний сервіс був недоступний. Причина: %2. Набір отриманих відомостей може бути обмеженим.';
}