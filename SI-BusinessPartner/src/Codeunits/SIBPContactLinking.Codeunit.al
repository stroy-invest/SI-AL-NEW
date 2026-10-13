codeunit 54083 "SI BP Contact Linking"
{
    // Uses standard BC Contact and Contact Business Relation only.
    Permissions = tabledata Contact = rimd,
                  tabledata "Contact Business Relation" = rimd;

    procedure EnsureLinks(BPNo: Code[60]): Text
    var
        BP: Record "SI Business Partner";
        Role: Record "SI BP Role";
        Relation: Record "Contact Business Relation";
        Contact: Record Contact;
        MarketingSetup: Record "Marketing Setup";
        CustomerNo: Code[20];
        VendorNo: Code[20];
        CustomerContactNo: Code[20];
        VendorContactNo: Code[20];
        TargetContactNo: Code[20];
        Changes: Integer;
    begin
        BP.Get(BPNo);
        Role.SetRange("Business Partner No.", BPNo);
        if Role.FindSet() then
            repeat
                // Only roles which are currently linked to an ERP entity are relevant.
                if Role."Customer No." <> '' then begin
                    if (CustomerNo <> '') and (CustomerNo <> Role."Customer No.") then
                        Error('Контрагент %1 має декілька матеріалізованих ролей покупця. Потрібна ручна перевірка.', BPNo);
                    CustomerNo := Role."Customer No.";
                end;
                if Role."Vendor No." <> '' then begin
                    if (VendorNo <> '') and (VendorNo <> Role."Vendor No.") then
                        Error('Контрагент %1 має декілька матеріалізованих ролей постачальника. Потрібна ручна перевірка.', BPNo);
                    VendorNo := Role."Vendor No.";
                end;
            until Role.Next() = 0;

        if (CustomerNo = '') and (VendorNo = '') then
            exit('Немає матеріалізованих ролей. Змін не виконано.');

        MarketingSetup.Get();
        if (MarketingSetup."Bus. Rel. Code for Customers" = '') or
           (MarketingSetup."Bus. Rel. Code for Vendors" = '') then
            Error('У налаштуваннях маркетингу не заповнено коди бізнес-відносин для покупців і постачальників.');

        if CustomerNo <> '' then begin
            if not CustomerExists(CustomerNo) then
                Error('Покупця %1 не знайдено.', CustomerNo);
            CustomerContactNo := Relation.GetContactNo(Enum::"Contact Business Relation Link To Table"::Customer, CustomerNo);
        end;
        if VendorNo <> '' then begin
            if not VendorExists(VendorNo) then
                Error('Постачальника %1 не знайдено.', VendorNo);
            VendorContactNo := Relation.GetContactNo(Enum::"Contact Business Relation Link To Table"::Vendor, VendorNo);
        end;

        if (CustomerContactNo <> '') and (VendorContactNo <> '') and
           (CustomerContactNo <> VendorContactNo) then
            Error('Конфлікт Contact: покупець %1 пов''язаний із %2, постачальник %3 — із %4. Автоматичне об''єднання заборонено.',
                CustomerNo, CustomerContactNo, VendorNo, VendorContactNo);

        TargetContactNo := CustomerContactNo;
        if TargetContactNo = '' then
            TargetContactNo := VendorContactNo;

        if TargetContactNo = '' then begin
            MarketingSetup.TestField("Contact Nos.");
            Contact.Init();
            Contact.Type := Contact.Type::Company;
            Contact.Insert(true);
            Contact.Validate(Name, BP.Name);
            Contact.Modify(true);
            TargetContactNo := Contact."No.";
            Changes += 1;
        end else begin
            if not Contact.Get(TargetContactNo) then
                Error('Пов''язаний Contact %1 не існує. Потрібна ручна перевірка.', TargetContactNo);
            if Contact.Type <> Contact.Type::Company then
                Error('Contact %1 не є Company Contact.', TargetContactNo);
        end;

        if (CustomerNo <> '') and (CustomerContactNo = '') then begin
            Clear(Relation);
            Relation.CreateRelation(TargetContactNo, CustomerNo, Enum::"Contact Business Relation Link To Table"::Customer);
            Changes += 1;
        end;
        if (VendorNo <> '') and (VendorContactNo = '') then begin
            Clear(Relation);
            Relation.CreateRelation(TargetContactNo, VendorNo, Enum::"Contact Business Relation Link To Table"::Vendor);
            Changes += 1;
        end;

        if Changes = 0 then
            exit(StrSubstNo('Коректно: обидві ERP-ролі використовують Contact %1. Змін немає.', TargetContactNo));
        exit(StrSubstNo('Виправлено: Contact %1; створено записів/зв''язків: %2.', TargetContactNo, Changes));
    end;

    local procedure CustomerExists(No: Code[20]): Boolean
    var C: Record Customer;
    begin
        exit(C.Get(No));
    end;

    local procedure VendorExists(No: Code[20]): Boolean
    var V: Record Vendor;
    begin
        exit(V.Get(No));
    end;
}
