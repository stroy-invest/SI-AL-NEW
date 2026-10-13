codeunit 54084 "SI BP Contact Insert Guard"
{
    SingleInstance = true;

    // Scoped, one-shot suppression of standard auto-contact creation ONLY
    // when an existing opposite-role Company Contact has been verified.
    procedure Prepare(BPNo: Code[60]; NewRoleType: Text)
    var
        Role: Record "SI BP Role";
        Relation: Record "Contact Business Relation";
        Contact: Record Contact;
        OppositeERPNo: Code[20];
        OppositeContactNo: Code[20];
        CandidateNo: Code[20];
    begin
        ClearPending();
        Role.SetRange("Business Partner No.", BPNo);
        if Role.FindSet() then
            repeat
                CandidateNo := '';
                if (NewRoleType = 'Customer') and (Role."Vendor No." <> '') then
                    CandidateNo := Relation.GetContactNo(Enum::"Contact Business Relation Link To Table"::Vendor, Role."Vendor No.");
                if (NewRoleType = 'Vendor') and (Role."Customer No." <> '') then
                    CandidateNo := Relation.GetContactNo(Enum::"Contact Business Relation Link To Table"::Customer, Role."Customer No.");
                if CandidateNo <> '' then begin
                    if (OppositeContactNo <> '') and (OppositeContactNo <> CandidateNo) then
                        Error('У контрагента %1 кілька різних Contact. Потрібна ручна перевірка.', BPNo);
                    OppositeContactNo := CandidateNo;
                end;
            until Role.Next() = 0;

        if OppositeContactNo = '' then
            exit;
        if not Contact.Get(OppositeContactNo) then
            Error('Contact %1 не знайдено.', OppositeContactNo);
        if Contact.Type <> Contact.Type::Company then
            Error('Contact %1 не є Company Contact.', OppositeContactNo);
        PendingRoleType := NewRoleType;
    end;

    procedure ClearPending()
    begin
        PendingRoleType := '';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CustCont-Update", 'OnBeforeOnInsert', '', false, false)]
    local procedure SuppressCustomerAutoContact(var Customer: Record Customer; var IsHandled: Boolean)
    begin
        if PendingRoleType <> 'Customer' then
            exit;
        ClearPending();
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"VendCont-Update", 'OnBeforeOnInsert', '', false, false)]
    local procedure SuppressVendorAutoContact(var Vendor: Record Vendor; var IsHandled: Boolean)
    begin
        if PendingRoleType <> 'Vendor' then
            exit;
        ClearPending();
        IsHandled := true;
    end;

    var
        PendingRoleType: Text;
}
