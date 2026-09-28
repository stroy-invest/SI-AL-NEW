tableextension 60000 "SI Customer Ext." extends Customer
{
    fields
    {
        field(60000; "SI Customer Type"; Enum "SI Customer Type")
        {
            Caption = 'Тип клієнта SI';
            DataClassification = CustomerContent;
        }
        field(60001; "SI Project No."; Code[20])
        {
            Caption = '№ будівельного проєкту';
            DataClassification = CustomerContent;
            TableRelation = Job."No." where("SI Construction Project" = const(true));

            trigger OnValidate()
            var
                OtherCustomer: Record Customer;
            begin
                if "SI Project No." = '' then
                    exit;

                if "SI Customer Type" <> "SI Customer Type"::"Internal Project" then
                    Error('№ будівельного проєкту можна вказувати лише для внутрішнього SI-клієнта.');

                OtherCustomer.SetRange("SI Customer Type", OtherCustomer."SI Customer Type"::"Internal Project");
                OtherCustomer.SetRange("SI Project No.", "SI Project No.");
                OtherCustomer.SetFilter("No.", '<>%1', "No.");
                if OtherCustomer.FindFirst() then
                    Error(
                        'Будівельний проєкт %1 уже пов''язаний з внутрішнім SI-клієнтом %2. Для одного проєкту дозволено лише одного внутрішнього клієнта.',
                        "SI Project No.", OtherCustomer."No.");
            end;
        }
    }

    keys
    {
        key(SIProject; "SI Project No.") { }
    }
}
