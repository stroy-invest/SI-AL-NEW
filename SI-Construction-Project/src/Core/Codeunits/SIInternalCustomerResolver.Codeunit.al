codeunit 60035 "SI Internal Customer Resolver"
{
    procedure ResolveCustomer(Purpose: Code[30]): Code[20]
    var
        CustomerNo: Code[20];
    begin
        if not TryResolveCustomer(Purpose, CustomerNo) then
            Error('Не налаштовано активного внутрішнього Customer для призначення %1 або його дані некоректні.', Purpose);
        exit(CustomerNo);
    end;

    procedure TryResolveCustomer(Purpose: Code[30]; var CustomerNo: Code[20]): Boolean
    var
        PurposeSetup: Record "SI Internal Operation Purpose";
        CustomerRec: Record Customer;
    begin
        Clear(CustomerNo);
        if Purpose = '' then
            exit(false);
        if not PurposeSetup.Get(Purpose) then
            exit(false);
        if not PurposeSetup.Enabled then
            exit(false);
        if PurposeSetup."Customer No." = '' then
            exit(false);
        if not CustomerRec.Get(PurposeSetup."Customer No.") then
            exit(false);
        if not (CustomerRec."SI Customer Type" in [CustomerRec."SI Customer Type"::"Internal Operations", CustomerRec."SI Customer Type"::"Internal Project"]) then
            exit(false);
        CustomerNo := CustomerRec."No.";
        exit(true);
    end;

    procedure ValidateSetup()
    var
        PurposeSetup: Record "SI Internal Operation Purpose";
        CustomerNo: Code[20];
    begin
        PurposeSetup.SetRange(Enabled, true);
        if PurposeSetup.FindSet() then
            repeat
                if not TryResolveCustomer(PurposeSetup.Code, CustomerNo) then
                    Error('Некоректне налаштування внутрішньої операції %1.', PurposeSetup.Code);
            until PurposeSetup.Next() = 0;
    end;
}
