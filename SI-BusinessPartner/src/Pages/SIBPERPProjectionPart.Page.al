page 54062 "SI BP ERP Projection Part"
{
    PageType = ListPart;
    SourceTable = "SI BP Role";
    ApplicationArea = All;
    Caption = 'ERP-проєкція';

    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Projection)
            {
                field(ERPNo; ERPNo)
                {
                    ApplicationArea = All;
                    Caption = 'Код';
                    DrillDown = true;
                    ToolTip = 'Код створеного клієнта або постачальника в Business Central. Натисніть, щоб відкрити картку.';

                    trigger OnDrillDown()
                    begin
                        OpenERPCard();
                    end;
                }

                field(ERPName; ERPName)
                {
                    ApplicationArea = All;
                    Caption = 'Назва';
                    ToolTip = 'Назва створеного клієнта або постачальника.';
                }

                field(RegistrationNo; RegistrationNo)
                {
                    ApplicationArea = All;
                    Caption = 'ЄДРПОУ';
                    ToolTip = 'Реєстраційний номер контрагента.';
                }

                field(LegalAddress; LegalAddress)
                {
                    ApplicationArea = All;
                    Caption = 'Адреса';
                    ToolTip = 'Повна юридична адреса контрагента з канонічних даних Business Partner.';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        LoadProjectionSummary();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        LoadProjectionSummary();
    end;

    local procedure LoadProjectionSummary()
    var
        Projection: Record "SI BP ERP Projection";
        BPAddressMgt: Codeunit "SI BP Address Mgt.";
        BPAddress: Record "SI BP Address";
    begin
        Clear(ERPNo);
        Clear(ERPName);
        Clear(RegistrationNo);
        Clear(LegalAddress);

        if not Projection.Get(Rec.Code) then
            exit;

        if Projection.Status <> Projection.Status::Materialized then
            exit;

        ERPNo := Projection."ERP No.";
        RegistrationNo := Projection."Registration No.";

        case Rec."Role Type" of
            Rec."Role Type"::Customer:
                LoadCustomer(ERPNo);

            Rec."Role Type"::Vendor:
                LoadVendor(ERPNo);
        end;

        if BPAddressMgt.GetCurrentLegalAddress(
            Rec."Business Partner No.",
            WorkDate(),
            BPAddress)
        then
            LegalAddress := BPAddress."Raw Address";
    end;

    local procedure LoadCustomer(CustomerNo: Code[20])
    var
        Customer: Record Customer;
    begin
        if CustomerNo = '' then
            exit;

        if not Customer.Get(CustomerNo) then
            exit;

        ERPName := Customer.Name;
    end;

    local procedure LoadVendor(VendorNo: Code[20])
    var
        Vendor: Record Vendor;
    begin
        if VendorNo = '' then
            exit;

        if not Vendor.Get(VendorNo) then
            exit;

        ERPName := Vendor.Name;
    end;

    local procedure OpenERPCard()
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
    begin
        if ERPNo = '' then
            exit;

        case Rec."Role Type" of
            Rec."Role Type"::Customer:
                begin
                    if not Customer.Get(ERPNo) then
                        exit;

                    Page.Run(Page::"Customer Card", Customer);
                end;

            Rec."Role Type"::Vendor:
                begin
                    if not Vendor.Get(ERPNo) then
                        exit;

                    Page.Run(Page::"Vendor Card", Vendor);
                end;
        end;
    end;

    var
        ERPNo: Code[20];
        ERPName: Text[100];
        RegistrationNo: Text[50];
        LegalAddress: Text[500];
}
