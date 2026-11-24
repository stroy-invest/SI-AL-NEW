table 60036 "SI Internal Operation Purpose"
{
    Caption = 'Призначення внутрішньої операції';
    DataClassification = CustomerContent;
    LookupPageId = "SI Internal Operations Setup";

    fields
    {
        field(1; Code; Code[30]) { Caption = 'Код'; NotBlank = true; }
        field(2; Description; Text[100]) { Caption = 'Опис'; }
        field(3; "Customer No."; Code[20])
        {
            Caption = '№ внутрішнього клієнта';
            TableRelation = Customer."No." where("SI Customer Type" = const("Internal Operations"));
            trigger OnValidate()
            var
                CustomerRec: Record Customer;
            begin
                if "Customer No." = '' then
                    exit;
                CustomerRec.Get("Customer No.");
                if CustomerRec."SI Customer Type" <> CustomerRec."SI Customer Type"::"Internal Operations" then
                    Error('Customer %1 повинен мати тип Internal Operations.', "Customer No.");
                if CustomerRec."SI Project No." <> '' then
                    Error('Customer %1 пов’язаний з проєктом %2.', "Customer No.", CustomerRec."SI Project No.");
            end;
        }
        field(4; Enabled; Boolean) { Caption = 'Активне'; InitValue = true; }
    }
    keys { key(PK; Code) { Clustered = true; } }
}
