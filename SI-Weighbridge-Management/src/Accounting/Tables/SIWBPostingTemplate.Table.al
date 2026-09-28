table 59130 "SI WB Posting Template"
{
    Caption = 'Шаблон обліку вагової';
    DataClassification = CustomerContent;

    fields
    {
        field(1; Code; Code[20])
        {
            Caption = 'Код';
            NotBlank = true;
        }

        field(2; Description; Text[100])
        {
            Caption = 'Опис';
        }

        field(3; Enabled; Boolean)
        {
            Caption = 'Увімкнено';
            InitValue = true;
        }

        field(4; Priority; Integer)
        {
            Caption = 'Пріоритет';
            ToolTip = 'Явний пріоритет правила. Більше число означає вищий пріоритет. Серед усіх шаблонів, що відповідають критеріям і чинні на дату документа, пріоритет перевіряється перед специфічністю.';
        }

        // ------------------------------------------------------------
        // Routing criteria.
        // Undefined / blank means "any value" for the criterion.
        // ------------------------------------------------------------

        field(10; "Operation Type"; Enum "SI WB Operation Type")
        {
            Caption = 'Операція';
            InitValue = Receipt;

            trigger OnValidate()
            begin
                // Posting templates must always have a real physical direction.
                if "Operation Type" = "SI WB Operation Type"::Undefined then
                    Error('Операція "Не визначено" не допускається для шаблону обліку. Виберіть Надходження або Відвантаження.');

                // Keep the dependent business scenario valid at all times.
                case "Operation Type" of
                    "SI WB Operation Type"::Receipt:
                        "Shipment Scenario" := "SI WB Shipment Scenario"::Supply;
                    "SI WB Operation Type"::Shipment:
                        if not ("Shipment Scenario" in [
                            "SI WB Shipment Scenario"::Sales,
                            "SI WB Shipment Scenario"::"Internal Transfer"])
                        then
                            "Shipment Scenario" := "SI WB Shipment Scenario"::Sales;
                end;
            end;
        }

        field(11; "Shipment Scenario"; Enum "SI WB Shipment Scenario")
        {
            Caption = 'Тип операції';
            InitValue = Supply;

            trigger OnValidate()
            begin
                ValidateScenarioForOperation();
            end;
        }

        field(12; "Basis Type"; Enum "SI WB Basis Type")
        {
            Caption = 'Тип підстави';
        }

        field(13; "Item Category Code"; Code[20])
        {
            Caption = 'Категорія товару';
            TableRelation = "Item Category".Code;
        }

        field(14; "Item No."; Code[20])
        {
            Caption = 'Товар';
            TableRelation = Item."No.";
        }

        field(15; "Location Code"; Code[10])
        {
            Caption = 'Склад (критерій)';
            TableRelation = Location.Code;
            ToolTip = 'Пріоритетний склад призначення цього шаблону. Якщо заповнено, саме він використовується для прибуткування незалежно від поля "Склад за замовчуванням". Поле більше не бере участі у matching шаблону.';
        }

        field(16; "Valid From"; Date)
        {
            Caption = 'Чинний з';
            ToolTip = 'Початок періоду дії шаблону. Порожнє значення означає відсутність нижньої межі.';

            trigger OnValidate()
            begin
                ValidateValidityPeriod();
            end;
        }

        field(17; "Valid To"; Date)
        {
            Caption = 'Чинний до';
            ToolTip = 'Кінець періоду дії шаблону включно. Порожнє значення означає відсутність верхньої межі.';

            trigger OnValidate()
            begin
                ValidateValidityPeriod();
            end;
        }

        // ------------------------------------------------------------
        // Accounting defaults.
        // Blank means "do not overwrite the current BC value".
        // Actual application to Purchase/Sales documents is implemented
        // in the next stage; 1.1.1.7 resolves and stores the template.
        // ------------------------------------------------------------

        field(30; "Default Location Code"; Code[10])
        {
            Caption = 'Склад за замовчуванням';
            TableRelation = Location.Code;
            ToolTip = 'Резервний склад цього шаблону. Використовується лише коли поле "Склад (критерій)" порожнє. Якщо обидва поля порожні, склад визначається через налаштування складів за замовчуванням.';
        }

        field(31; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Заг. бізнес-група обліку';
            TableRelation = "Gen. Business Posting Group".Code;
        }

        field(32; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'Бізнес-група ПДВ';
            TableRelation = "VAT Business Posting Group".Code;
        }

        field(33; "Customer Posting Group"; Code[20])
        {
            Caption = 'Група обліку клієнта';
            TableRelation = "Customer Posting Group".Code;
        }

        field(34; "Vendor Posting Group"; Code[20])
        {
            Caption = 'Група обліку постачальника';
            TableRelation = "Vendor Posting Group".Code;
        }

        field(35; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Заг. товарна група обліку';
            TableRelation = "Gen. Product Posting Group".Code;
        }

        field(36; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'Товарна група ПДВ';
            TableRelation = "VAT Product Posting Group".Code;
        }

        field(37; "Shortcut Dimension 1 Code"; Code[20])
        {
            Caption = 'Код виміру 1';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }

        field(38; "Shortcut Dimension 2 Code"; Code[20])
        {
            Caption = 'Код виміру 2';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
    }

    keys
    {
        key(PK; Code)
        {
            Clustered = true;
        }

        key(EnabledPriority; Enabled, Priority)
        {
        }
    }

    local procedure ValidateValidityPeriod()
    begin
        if ("Valid From" <> 0D) and
           ("Valid To" <> 0D) and
           ("Valid From" > "Valid To")
        then
            Error('Дата "Чинний з" не може бути пізнішою за дату "Чинний до".');
    end;
    local procedure ValidateScenarioForOperation()
    begin
        if "Shipment Scenario" = "SI WB Shipment Scenario"::Undefined then
            Error('Тип операції "Не визначено" не допускається для шаблону обліку.');

        case "Operation Type" of
            "SI WB Operation Type"::Receipt:
                if "Shipment Scenario" <> "SI WB Shipment Scenario"::Supply then
                    Error('Для операції Надходження допустимий лише тип операції Постачання.');
            "SI WB Operation Type"::Shipment:
                if not ("Shipment Scenario" in [
                    "SI WB Shipment Scenario"::Sales,
                    "SI WB Shipment Scenario"::"Internal Transfer"])
                then
                    Error('Для операції Відвантаження допустимі лише типи операції Продаж або Внутрішнє переміщення.');
            "SI WB Operation Type"::Undefined:
                Error('Спочатку виберіть операцію Надходження або Відвантаження.');
        end;
    end;

}
