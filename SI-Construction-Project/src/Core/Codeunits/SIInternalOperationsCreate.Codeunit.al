codeunit 60037 "SI Internal Operations Create"
{
    Permissions = tabledata Customer = rim;
    procedure CreateInteractive()
    var
        DialogPage: Page "SI Internal Customer Create";
        CustomerRec: Record Customer;
        CustomerNo: Code[20];
        CustomerName: Text[100];
    begin
        if DialogPage.RunModal() <> Action::OK then
            exit;
        DialogPage.GetValues(CustomerNo, CustomerName);
        if CustomerNo = '' then
            Error('Укажіть код внутрішнього клієнта.');
        if CustomerName = '' then
            Error('Укажіть назву внутрішнього клієнта.');
        if CustomerRec.Get(CustomerNo) then
            Error('Customer %1 уже існує.', CustomerNo);
        CustomerRec.Init();
        CustomerRec.Validate("No.", CustomerNo);
        CustomerRec.Insert(true);
        CustomerRec.Validate(Name, CustomerName);
        CustomerRec.Validate("SI Customer Type", CustomerRec."SI Customer Type"::"Internal Operations");
        CustomerRec.Modify(true);
    end;
}
