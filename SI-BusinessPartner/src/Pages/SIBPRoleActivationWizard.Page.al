page 54082 "SI BP Role Activation Wizard"
{
    PageType = StandardDialog;
    Caption = 'Налаштувати та активувати роль';
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(Activation)
            {
                Caption = 'Параметри активації';

                field(RoleTypeDisplay; RoleTypeDisplay)
                {
                    Caption = 'Роль';
                    ApplicationArea = All;
                    Editable = false;
                }

                field(CountryRegionCode; CountryRegionCode)
                {
                    Caption = 'Країна/регіон';
                    ApplicationArea = All;
                    Editable = false;
                }

                field(VATChoice; VATChoice)
                {
                    Caption = 'Статус ПДВ';
                    ApplicationArea = All;
                    ToolTip = 'Виберіть податковий статус контрагента для визначення стандартного шаблону Business Central.';
                }
            }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction <> Action::OK then
            exit(true);

        if VATChoice = VATChoice::"Not Selected" then
            Error('Виберіть статус ПДВ: Платник ПДВ або Неплатник ПДВ.');

        exit(true);
    end;

    procedure SetRole(Role: Record "SI BP Role")
    var
        BusinessPartner: Record "SI Business Partner";
    begin
        RoleTypeDisplay := Format(Role."Role Type");

        if BusinessPartner.Get(Role."Business Partner No.") then
            CountryRegionCode := BusinessPartner."Country/Region Code";

        VATChoice := VATChoice::"Not Selected";
    end;

    procedure GetVATStatus(): Enum "SI BP VAT Status"
    var
        VATStatus: Enum "SI BP VAT Status";
    begin
        case VATChoice of
            VATChoice::VAT:
                exit(VATStatus::VAT);

            VATChoice::"Non-VAT":
                exit(VATStatus::"Non-VAT");
        end;

        Error('Статус ПДВ не вибрано.');
    end;

    var
        VATChoice: Enum "SI BP Activation VAT Choice";
        CountryRegionCode: Code[10];
        RoleTypeDisplay: Text[50];
}
