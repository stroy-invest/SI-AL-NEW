codeunit 54014 "SI BP Role Setup Mgt."
{
    procedure SynchronizeRoleSetups(var BusinessPartner: Record "SI Business Partner")
    begin
        if BusinessPartner."Is Customer" then
            EnsureCustomerSetup(BusinessPartner."No.")
        else
            DeactivateCustomerSetup(BusinessPartner."No.");

        if BusinessPartner."Is Vendor" then
            EnsureVendorSetup(BusinessPartner."No.")
        else
            DeactivateVendorSetup(BusinessPartner."No.");
    end;

    procedure EnsureCustomerSetup(BusinessPartnerNo: Code[20])
    var
        CustomerSetup: Record "SI BP Customer Setup";
        BusinessPartner: Record "SI Business Partner";
        IsChanged: Boolean;
    begin
        BusinessPartner.Get(BusinessPartnerNo);

        if CustomerSetup.Get(BusinessPartnerNo) then begin
            if CustomerSetup."Is Inactive" then begin
                CustomerSetup."Is Inactive" := false;
                IsChanged := true;
            end;

            if CustomerSetup."Currency Code" = '' then begin
                CustomerSetup.Validate(
                    "Currency Code",
                    BusinessPartner."Currency Code");
                IsChanged := true;
            end;

            if IsChanged then
                CustomerSetup.Modify(true);

            exit;
        end;

        CustomerSetup.Init();
        CustomerSetup.Validate("Business Partner No.", BusinessPartnerNo);
        CustomerSetup.Validate(
            "Currency Code",
            BusinessPartner."Currency Code");
        CustomerSetup."Is Inactive" := false;
        CustomerSetup.Insert(true);
    end;

    procedure EnsureVendorSetup(BusinessPartnerNo: Code[20])
    var
        VendorSetup: Record "SI BP Vendor Setup";
        BusinessPartner: Record "SI Business Partner";
        IsChanged: Boolean;
    begin
        BusinessPartner.Get(BusinessPartnerNo);

        if VendorSetup.Get(BusinessPartnerNo) then begin
            if VendorSetup."Is Inactive" then begin
                VendorSetup."Is Inactive" := false;
                IsChanged := true;
            end;

            if VendorSetup."Currency Code" = '' then begin
                VendorSetup.Validate(
                    "Currency Code",
                    BusinessPartner."Currency Code");
                IsChanged := true;
            end;

            if IsChanged then
                VendorSetup.Modify(true);

            exit;
        end;

        VendorSetup.Init();
        VendorSetup.Validate("Business Partner No.", BusinessPartnerNo);
        VendorSetup.Validate(
            "Currency Code",
            BusinessPartner."Currency Code");
        VendorSetup."Is Inactive" := false;
        VendorSetup.Insert(true);
    end;

    local procedure DeactivateCustomerSetup(BusinessPartnerNo: Code[20])
    var
        CustomerSetup: Record "SI BP Customer Setup";
    begin
        if not CustomerSetup.Get(BusinessPartnerNo) then
            exit;

        if CustomerSetup."Is Inactive" then
            exit;

        CustomerSetup."Is Inactive" := true;
        CustomerSetup.Modify(true);
    end;

    local procedure DeactivateVendorSetup(BusinessPartnerNo: Code[20])
    var
        VendorSetup: Record "SI BP Vendor Setup";
    begin
        if not VendorSetup.Get(BusinessPartnerNo) then
            exit;

        if VendorSetup."Is Inactive" then
            exit;

        VendorSetup."Is Inactive" := true;
        VendorSetup.Modify(true);
    end;

    local procedure CreateCustomerSetup(
        BusinessPartner: Record "SI Business Partner")
    var
        CustomerSetup: Record "SI BP Customer Setup";
    begin
        if CustomerSetup.Get(BusinessPartner."No.") then
            exit;

        CustomerSetup.Init();
        CustomerSetup.Validate(
            "Business Partner No.",
            BusinessPartner."No.");

        CustomerSetup.Validate(
            "Currency Code",
            BusinessPartner."Currency Code");

        CustomerSetup.Insert(true);
    end;

    local procedure CreateVendorSetup(
        BusinessPartner: Record "SI Business Partner")
    var
        VendorSetup: Record "SI BP Vendor Setup";
    begin
        if VendorSetup.Get(BusinessPartner."No.") then
            exit;

        VendorSetup.Init();
        VendorSetup.Validate(
            "Business Partner No.",
            BusinessPartner."No.");

        VendorSetup.Validate(
            "Currency Code",
            BusinessPartner."Currency Code");

        VendorSetup.Insert(true);
    end;
}