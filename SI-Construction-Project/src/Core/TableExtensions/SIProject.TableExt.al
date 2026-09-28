tableextension 60001 "SI Project Ext." extends Job
{
    fields
    {
        modify(Description)
        {
            trigger OnAfterValidate()
            var
                ConstructionProjectMgt: Codeunit "SI Construction Project Mgt.";
            begin
                if Rec."SI Construction Project" then
                    ConstructionProjectMgt.SyncProjectLocationName(Rec);
            end;
        }

        modify("Location Code")
        {
            trigger OnAfterValidate()
            begin
                if not Rec."SI Construction Project" then
                    exit;

                if (xRec."Location Code" <> '') and (Rec."Location Code" <> xRec."Location Code") then
                    Error(
                        'Склад будівельного проєкту створюється системою та не може бути змінений вручну.');
            end;
        }

        modify("Sell-to Customer No.")
        {
            trigger OnAfterValidate()
            var
                Customer: Record Customer;
            begin
                if not Rec."SI Construction Project" then
                    exit;
                if Rec."Sell-to Customer No." = '' then
                    exit;
                if not Customer.Get(Rec."Sell-to Customer No.") then
                    exit;

                if Customer."SI Customer Type" = Customer."SI Customer Type"::"Internal Project" then
                    Error(
                        'Внутрішній SI-клієнт %1 не може бути замовником будівельного проєкту.',
                        Customer."No.");
            end;
        }

        field(60000; "SI Construction Project"; Boolean)
        {
            Caption = 'Будівельний проєкт SI';
            DataClassification = CustomerContent;
        }
        field(60001; "SI Project Customer No."; Code[20])
        {
            Caption = 'Legacy Project Customer No.';
            DataClassification = CustomerContent;
            ObsoleteState = Pending;
            ObsoleteReason = 'Replaced by SI Internal Customer No.';

            TableRelation = Customer."No." where("SI Customer Type" = const("Internal Project"));
        }

        field(60013; "SI Internal Customer No."; Code[20])
        {
            Caption = 'Внутрішній SI-клієнт';
            DataClassification = CustomerContent;
            TableRelation = Customer."No." where("SI Customer Type" = const("Internal Project"));
        }
        field(60002; "SI Full Name"; Text[250])
        {
            Caption = 'Повна назва об''єкта';
            DataClassification = CustomerContent;
        }
        field(60003; "SI Address"; Text[100])
        {
            Caption = 'Адреса об''єкта';
            DataClassification = CustomerContent;
        }
        field(60004; "SI Address 2"; Text[50])
        {
            Caption = 'Адреса об''єкта 2';
            DataClassification = CustomerContent;
        }
        field(60005; "SI City"; Text[30])
        {
            Caption = 'Місто';
            DataClassification = CustomerContent;
        }
        field(60006; "SI Post Code"; Code[20])
        {
            Caption = 'Поштовий індекс';
            DataClassification = CustomerContent;
            TableRelation = "Post Code".Code;
        }
        field(60007; "SI County"; Text[30])
        {
            Caption = 'Область';
            DataClassification = CustomerContent;
        }
        field(60008; "SI Country/Region Code"; Code[10])
        {
            Caption = 'Код країни/регіону';
            DataClassification = CustomerContent;
            TableRelation = "Country/Region".Code;
        }
        field(60009; "SI Project Status"; Enum "SI Project Status")
        {
            Caption = 'Статус будівельного проєкту';
            DataClassification = CustomerContent;
        }
        field(60010; "SI Actual Ending Date"; Date)
        {
            Caption = 'Фактична дата завершення';
            DataClassification = CustomerContent;
        }
    }
}
