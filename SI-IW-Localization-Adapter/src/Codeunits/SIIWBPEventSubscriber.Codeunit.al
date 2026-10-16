codeunit 65001 "SI IW BP Event Subscriber"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SI BP Projection Mgt.", 'OnBeforeVendorProjectionModify', '', false, false)]
    local procedure OnBeforeVendorProjectionModify(var Vendor: Record Vendor; BusinessPartnerNo: Code[20])
    var
        Sync: Codeunit "SI IW BP Identifier Sync";
    begin
        Sync.ApplyVendor(Vendor, BusinessPartnerNo);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SI BP Projection Mgt.", 'OnBeforeCustomerProjectionModify', '', false, false)]
    local procedure OnBeforeCustomerProjectionModify(var Customer: Record Customer; BusinessPartnerNo: Code[20])
    var
        Sync: Codeunit "SI IW BP Identifier Sync";
    begin
        Sync.ApplyCustomer(Customer, BusinessPartnerNo);
    end;
}
