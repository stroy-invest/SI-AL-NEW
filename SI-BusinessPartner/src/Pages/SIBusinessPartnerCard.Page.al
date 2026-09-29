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
                        ShowMandatory = true;
                    }

                    field("Full Legal Form"; Rec."Full Legal Form")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the full country-specific legal form resolved from the selected country legal form.';
                        Editable = false;
                    }

                    field(LegalFormGroupDescription; LegalFormGroupDescription)
                    {
                        ApplicationArea = All;
                        Caption = 'Група';
                        ToolTip = 'Specifies the legal form group to which the selected legal form belongs.';
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

            action(CheckEDRPOURegistry)
            {
                ApplicationArea = All;
                Caption = 'Перевірити реєстр. №';
                ToolTip = 'Отримує актуальні дані українського контрагента з реєстру та оновлює дані Business Partner.';
                Image = Check;
                Enabled = CanCheckEDRPOU;

                trigger OnAction()
                var
                    EDRPOURegistryMgt: Codeunit "SI EDRPOU Registry Mgt.";
                    SuccessMsg: Label 'Дані контрагента успішно отримано з реєстру та матеріалізовано.';
                begin
                    CurrPage.SaveRecord();

                    EDRPOURegistryMgt.CheckAndMaterialize(Rec);

                    CurrPage.Update(false);

                    Message(SuccessMsg);
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
            actionref(CheckEDRPOURegistryPromoted; CheckEDRPOURegistry)
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
        CanCheckEDRPOU :=
            EDRPOURegistryMgt.IsCheckAvailable(Rec);

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
        CanCheckEDRPOU: Boolean;
        CanCreateCustomerRole: Boolean;
        CanCreateVendorRole: Boolean;
        IsDraft: Boolean;
        LegalFormGroupDescription: Text[100];
        StatusStyle: Text;
}