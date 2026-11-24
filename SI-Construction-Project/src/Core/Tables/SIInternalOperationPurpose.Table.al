table 60036 "SI Internal Operation Purpose"
{
    Caption = 'Призначення внутрішньої операції';
    DataClassification = CustomerContent;
    LookupPageId = "SI Internal Operations Setup";

    fields
    {
        field(1; Code; Code[30]) { Caption = 'Код'; NotBlank = true;
            TableRelation = "SI Internal Operation".Code;
            trigger OnValidate()
            var
                Operation: Record "SI Internal Operation";
            begin
                if Operation.Get(Code) then
                    Description := Operation.Description;
            end;
        }
        field(2; Description; Text[100]) { Caption = 'Опис'; }
        field(3; "Customer No."; Code[20])
        {
            Caption = '№ внутрішнього клієнта';
            TableRelation = Customer."No." where("SI Customer Type" = filter("Internal Operations" | "Internal Project"));
            trigger OnValidate()
            var
                CustomerRec: Record Customer;
            begin
                if "Customer No." = '' then
                    exit;
                CustomerRec.Get("Customer No.");
                if not (CustomerRec."SI Customer Type" in [CustomerRec."SI Customer Type"::"Internal Operations", CustomerRec."SI Customer Type"::"Internal Project"]) then
                    Error('Клієнт %1 повинен бути внутрішнім.', "Customer No.");
            end;
        }
        field(4; Enabled; Boolean) { Caption = 'Активне'; InitValue = true; }
    }
    keys { key(PK; Code) { Clustered = true; } }
}
