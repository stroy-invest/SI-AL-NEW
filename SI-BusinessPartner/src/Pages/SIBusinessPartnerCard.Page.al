page 54004 "SI Business Partner Card"
{
    PageType = Card;
    SourceTable = "SI Business Partner";
    ApplicationArea = All;
    UsageCategory = None;
    Caption = 'Business Partner';
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

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
                        ToolTip = 'Specifies the official registration number of the business partner.';
                        Editable = IsDraft;
                        ShowMandatory = true;

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
                Caption = 'Legal Identity';

                group(LegalIdentityMain)
                {
                    ShowCaption = false;

                    field("Local Legal Form Code"; Rec."Local Legal Form Code")
                    {
                        ApplicationArea = All;
                        Caption = 'Офіційна юридична форма';
                        ToolTip = 'Specifies the legal form used in the selected country or region.';
                        Editable = IsDraft;
                        ShowMandatory = true;
                    }

                    field("Full Legal Form"; Rec."Full Legal Form")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the full country-specific legal form resolved from the selected country legal form.';
                        Editable = false;
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

            group(Addresses)
            {
                Caption = 'Addresses';

                part(BPAddresses; "SI BP Addresses Part")
                {
                    ApplicationArea = All;
                    SubPageLink = "Business Partner No." = field("No.");
                    UpdatePropagation = Both;
                    Editable = IsDraft;
                }
            }

            group(Roles)
            {
                Caption = 'Roles';

                field("Is Customer"; Rec."Is Customer")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the business partner is intended to have the customer role.';
                    Editable = IsDraft;

                    trigger OnValidate()
                    begin
                        RefreshRoleParts();
                    end;
                }

                field("Is Vendor"; Rec."Is Vendor")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the business partner is intended to have the vendor role.';
                    Editable = IsDraft;

                    trigger OnValidate()
                    begin
                        RefreshRoleParts();
                    end;
                }
            }

            part(CustomerSetup; "SI BP Customer Setup Part")
            {
                ApplicationArea = All;
                Caption = 'Customer Settings';
                SubPageLink = "Business Partner No." = field("No.");
                Visible = Rec."Is Customer";
            }

            part(VendorSetup; "SI BP Vendor Setup Part")
            {
                ApplicationArea = All;
                Caption = 'Vendor Settings';
                SubPageLink = "Business Partner No." = field("No.");
                Visible = Rec."Is Vendor";
            }

            group(ERPProjections)
            {
                Caption = 'ERP Projections';

                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the related Business Central customer number.';
                    Editable = false;
                }

                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the related Business Central vendor number.';
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            // New role-based architecture.
            // The legacy role setup remains below until the next
            // refactoring phase.
            group(RoleManagement)
            {
                Caption = 'Ролі';

                action(CreateCustomerRole)
                {
                    Caption = 'Створити роль покупця';
                    ApplicationArea = All;
                    ToolTip = 'Створює для поточного контрагента роль покупця.';

                    trigger OnAction()
                    var
                        RoleMgt: Codeunit "SI BP Role Mgt.";
                        NewRole: Record "SI BP Role";
                        CreateDialog: Page "SI BP Role Create Dialog";
                    begin
                        CurrPage.SaveRecord();
                        Rec.TestField("No.");

                        CreateDialog.SetContext(
                            Rec."No.",
                            Enum::"SI BP Role Type"::Customer);

                        if CreateDialog.RunModal() <> Action::OK then
                            exit;

                        RoleMgt.CreateRole(
                            Rec."No.",
                            Enum::"SI BP Role Type"::Customer,
                            CreateDialog.GetERPTemplateCode(),
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

                    trigger OnAction()
                    var
                        RoleMgt: Codeunit "SI BP Role Mgt.";
                        NewRole: Record "SI BP Role";
                        CreateDialog: Page "SI BP Role Create Dialog";
                    begin
                        CurrPage.SaveRecord();
                        Rec.TestField("No.");

                        CreateDialog.SetContext(
                            Rec."No.",
                            Enum::"SI BP Role Type"::Vendor);

                        if CreateDialog.RunModal() <> Action::OK then
                            exit;

                        RoleMgt.CreateRole(
                            Rec."No.",
                            Enum::"SI BP Role Type"::Vendor,
                            CreateDialog.GetERPTemplateCode(),
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

            action(ConfigureRoles)
            {
                ApplicationArea = All;
                Caption = 'Налаштувати ролі';
                ToolTip = 'Створює або оновлює налаштування ролей покупця та постачальника.';
                Image = Setup;
                Enabled = Rec."Is Customer" or Rec."Is Vendor";

                trigger OnAction()
                var
                    BPRoleSetupMgt: Codeunit "SI BP Role Setup Mgt.";
                begin
                    CurrPage.SaveRecord();

                    BPRoleSetupMgt.SynchronizeRoleSetups(Rec);

                    RefreshRoleParts();
                end;
            }

            action(CheckEDRPOURegistry)
            {
                ApplicationArea = All;
                Caption = 'Перевірити реєстр. №';
                ToolTip = 'Перевірити реєстраційний номер українського контрагента через сервіс adm.tools.';
                Image = Check;
                Enabled = CanCheckEDRPOU;

                trigger OnAction()
                var
                    EDRPOURegistryMgt: Codeunit "SI EDRPOU Registry Mgt.";
                begin
                    CurrPage.SaveRecord();
                    Commit();

                    EDRPOURegistryMgt.CheckAndShow(Rec);

                    CurrPage.Update(false);
                end;
            }

            action(TestRegistryEDS)
            {
                ApplicationArea = All;
                Caption = 'Тест Registry EDS';
                ToolTip = 'Діагностичний виклик реєстру контрагентів через Foundation EDS без зміни даних Business Partner.';
                Image = TestDatabase;
                Enabled = CanCheckEDRPOU;

                trigger OnAction()
                var
                    EDRPOURegistryMgt: Codeunit "SI EDRPOU Registry Mgt.";
                    RegistryResult: Record "SI Registry Result" temporary;
                    ResultMsg: Label 'Provider: %1\ЄДРПОУ: %2\ІПН: %3\Назва: %4\Юридична форма: %5\Повна назва: %6\Коротка назва реєстру: %7\Адреса: %8\Керівник: %9';
                begin
                    CurrPage.SaveRecord();

                    EDRPOURegistryMgt.ResolveViaEDS(
                        Rec,
                        RegistryResult);

                    if not RegistryResult.FindFirst() then
                        Error('Registry resolver не повернув результат.');

                    Message(
                        ResultMsg,
                        RegistryResult."Provider Code",
                        RegistryResult."Registration No.",
                        RegistryResult."Tax Registration No.",
                        RegistryResult."Core Name",
                        RegistryResult."Legal Form Short",
                        RegistryResult."Legal Name",
                        RegistryResult."Registry Short Name",
                        RegistryResult.Address,
                        RegistryResult.Director);
                end;
            }
        }

        area(Navigation)
        {
            action(CountryLegalForms)
            {
                ApplicationArea = All;
                Caption = 'Country Legal Forms';
                ToolTip = 'Open the list of country-specific legal forms.';
                Image = List;
                RunObject = page "SI Country Legal Forms";
            }

            action(LegalForms)
            {
                ApplicationArea = All;
                Caption = 'Legal Forms';
                ToolTip = 'Open the list of normalized corporate legal forms.';
                Image = List;
                RunObject = page "SI Legal Forms";
            }
        }

        area(Promoted)
        {
            actionref(CheckEDRPOURegistryPromoted; CheckEDRPOURegistry)
            {
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

    local procedure RefreshRoleParts()
    begin
        CurrPage.SaveRecord();
        CurrPage.Update(false);

        if Rec."Is Customer" then
            CurrPage.CustomerSetup.Page.Update(false);

        if Rec."Is Vendor" then
            CurrPage.VendorSetup.Page.Update(false);
    end;

    local procedure UpdatePageState()
    var
        EDRPOURegistryMgt: Codeunit "SI EDRPOU Registry Mgt.";
    begin
        IsDraft := Rec.Status = Rec.Status::Draft;
        CanCheckEDRPOU :=
            EDRPOURegistryMgt.IsCheckAvailable(Rec);

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

    var
        CanCheckEDRPOU: Boolean;
        IsDraft: Boolean;
        StatusStyle: Text;
}