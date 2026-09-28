table 59100 "SI Weighbridge Document"
{
    Caption = 'Операційний документ вагової';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; BigInteger)
        {
            Caption = '№ запису';
            AutoIncrement = true;
        }

        field(2; "Document No."; Code[20])
        {
            Caption = '№ документа';
        }

        // ------------------------------------------------------------
        // Physical weighing fact
        // Immutable snapshot from SI Weighing Record
        // ------------------------------------------------------------

        field(10; "Weighing Entry No."; BigInteger)
        {
            Caption = '№ зважування';
            TableRelation = "SI Weighing Record"."Entry No.";
        }

        field(11; "Weighing Date/Time"; DateTime)
        {
            Caption = 'Дата/час зважування';
            Editable = false;
        }

        field(12; "Gross Weight"; Decimal)
        {
            Caption = 'Брутто, кг';
            DecimalPlaces = 0 : 3;
            Editable = false;
        }

        field(13; "Tare Weight"; Decimal)
        {
            Caption = 'Тара, кг';
            DecimalPlaces = 0 : 3;
            Editable = false;
        }

        field(14; "Net Weight"; Decimal)
        {
            Caption = 'Нетто, кг';
            DecimalPlaces = 0 : 3;
            Editable = false;
        }

        field(15; "Vehicle Plate"; Text[50])
        {
            Caption = 'Номер авто';
            Editable = false;
        }

        field(16; "Trailer Plate"; Text[50])
        {
            Caption = 'Номер причепа';
            Editable = false;
        }

        field(17; "Site Code"; Code[50])
        {
            Caption = 'Майданчик';
            Editable = false;
        }

        field(18; "Scale No."; Integer)
        {
            Caption = '№ ваг';
            Editable = false;
        }

        // ------------------------------------------------------------
        // Business classification
        // ------------------------------------------------------------

        field(20; "Operation Type"; Enum "SI WB Operation Type")
        {
            Caption = 'Операція';

            trigger OnValidate()
            begin
                if "Operation Type" = xRec."Operation Type" then
                    exit;

                ClearBasis();

                case "Operation Type" of
                    "SI WB Operation Type"::Receipt:
                        begin
                            "Shipment Scenario" :=
                                "SI WB Shipment Scenario"::Supply;

                            Clear("Customer No.");
                            Clear("Project No.");
                        end;

                    "SI WB Operation Type"::Shipment:
                        begin
                            if "Shipment Scenario" =
                               "SI WB Shipment Scenario"::Supply
                            then
                                "Shipment Scenario" :=
                                    "SI WB Shipment Scenario"::Undefined;

                            Clear("Vendor No.");
                        end;

                    else begin
                        "Shipment Scenario" :=
                            "SI WB Shipment Scenario"::Undefined;

                        Clear("Vendor No.");
                        Clear("Customer No.");
                        Clear("Project No.");
                    end;
                end;
            end;
        }

        field(21; Status; Enum "SI WB Document Status")
        {
            Caption = 'Статус';
            Editable = false;
        }

        // IMPORTANT:
        // Field ID and physical AL field name are intentionally preserved
        // for schema compatibility with already deployed versions.
        //
        // Domain semantics are now broader than "shipment":
        // Receipt  -> Supply
        // Shipment -> Sales / Internal Transfer
        field(22; "Shipment Scenario"; Enum "SI WB Shipment Scenario")
        {
            Caption = 'Сценарій';

            trigger OnValidate()
            begin
                ClearBasis();

                case "Operation Type" of
                    "SI WB Operation Type"::Receipt:
                        begin
                            if "Shipment Scenario" <>
                               "SI WB Shipment Scenario"::Supply
                            then
                                Error(
                                    'Для операції "Надходження" доступний тільки сценарій "Постачання".');

                            Clear("Customer No.");
                            Clear("Project No.");
                        end;

                    "SI WB Operation Type"::Shipment:
                        begin
                            case "Shipment Scenario" of
                                "SI WB Shipment Scenario"::Undefined:
                                    begin
                                        Clear("Customer No.");
                                        Clear("Project No.");
                                    end;

                                "SI WB Shipment Scenario"::Sales:
                                    begin
                                        Clear("Vendor No.");
                                        Clear("Project No.");
                                    end;

                                "SI WB Shipment Scenario"::"Internal Transfer":
                                    begin
                                        Clear("Vendor No.");
                                        Clear("Customer No.");
                                    end;

                                else
                                    Error(
                                        'Для операції "Відвантаження" доступні тільки сценарії "Продаж" або "Внутрішнє переміщення".');
                            end;
                        end;

                    else begin
                        if "Shipment Scenario" <>
                           "SI WB Shipment Scenario"::Undefined
                        then
                            Error(
                                'Сценарій не може бути визначений, доки не визначено операцію.');

                        Clear("Vendor No.");
                        Clear("Customer No.");
                        Clear("Project No.");
                    end;
                end;
            end;
        }

        // ------------------------------------------------------------
        // Receipt context
        // ------------------------------------------------------------

        field(40; "Vendor No."; Code[20])
        {
            Caption = 'Постачальник';
            TableRelation = Vendor."No.";

            trigger OnValidate()
            begin
                Clear("Basis No.");
            end;
        }

        field(41; "Vendor Shipment No."; Code[35])
        {
            Caption = '№ видаткової постачальника';
        }

        // Technical / downstream accounting context.
        // Not exposed on operator card.
        field(51; "Destination Location Code"; Code[10])
        {
            Caption = 'Склад оприбуткування';
            TableRelation = Location.Code;
        }

        // ------------------------------------------------------------
        // Shipment context
        // ------------------------------------------------------------

        field(50; "Customer No."; Code[20])
        {
            Caption = 'Клієнт';
            TableRelation = Customer."No.";

            trigger OnValidate()
            begin
                Clear("Basis No.");
            end;
        }

        field(52; "Production Order No."; Code[20])
        {
            Caption = 'Виробниче замовлення';

            TableRelation =
                "Production Order"."No."
                where(Status = const(Released));
        }

        // ------------------------------------------------------------
        // TEMPORARY Project integration point.
        //
        // Standard BC Project is still backed by table Job.
        // If target Project architecture changes later, this field
        // will be deprecated and replaced rather than reused with
        // different semantics.
        // ------------------------------------------------------------

        field(53; "Project No."; Code[20])
        {
            Caption = 'Проект';
            TableRelation = Job."No.";

            trigger OnValidate()
            begin
                Clear("Basis No.");
            end;
        }

        // ------------------------------------------------------------
        // Transport / accompanying documents
        // ------------------------------------------------------------

        field(60; "TTN No."; Code[50])
        {
            Caption = '№ ТТН';
        }

        field(61; "Product Passport No."; Code[50])
        {
            Caption = '№ паспорта продукції';
        }

        // Compatibility/traceability field.
        // Operator UI uses the 1:N SI WB Supporting Document table.
        field(62; "Delivery Note No."; Code[50])
        {
            Caption = '№ видаткової накладної';
        }

        // ------------------------------------------------------------
        // Resulting BC document
        // Stored for downstream traceability, not operator UX.
        // ------------------------------------------------------------

        field(70; "ERP Document Type"; Text[50])
        {
            Caption = 'Тип документа BC';
            Editable = false;
        }

        field(71; "ERP Document No."; Code[20])
        {
            Caption = '№ документа BC';
            Editable = false;
        }

        // ------------------------------------------------------------
        // Audit
        // ------------------------------------------------------------

        field(80; "Created At"; DateTime)
        {
            Caption = 'Створено';
            Editable = false;
        }

        field(81; "Created By"; Guid)
        {
            Caption = 'Створено користувачем';
            Editable = false;
        }

        field(82; "Modified At"; DateTime)
        {
            Caption = 'Змінено';
            Editable = false;
        }

        field(83; "Modified By"; Guid)
        {
            Caption = 'Змінено користувачем';
            Editable = false;
        }

        // ------------------------------------------------------------
        // Manager stage / business basis
        // ------------------------------------------------------------

        field(90; "Basis Type"; Enum "SI WB Basis Type")
        {
            Caption = 'Тип підстави';
            Editable = false;
        }

        field(91; "Basis No."; Code[20])
        {
            Caption = 'Документ-підстава';

            trigger OnValidate()
            var
                PurchaseHeader: Record "Purchase Header";
                SalesHeader: Record "Sales Header";
            begin
                if "Basis No." = '' then
                    exit;

                case "Basis Type" of
                    "SI WB Basis Type"::"Purchase Order":
                        begin
                            TestField("Vendor No.");

                            if not PurchaseHeader.Get(
                                PurchaseHeader."Document Type"::Order,
                                "Basis No.")
                            then
                                Error(
                                    'Purchase Order %1 не знайдено.',
                                    "Basis No.");

                            if PurchaseHeader."Buy-from Vendor No." <>
                               "Vendor No."
                            then
                                Error(
                                    'Purchase Order %1 належить постачальнику %2, а в документі вагової вибрано постачальника %3.',
                                    "Basis No.",
                                    PurchaseHeader."Buy-from Vendor No.",
                                    "Vendor No.");
                        end;

                    "SI WB Basis Type"::"Sales Order":
                        begin
                            TestField("Customer No.");

                            if not SalesHeader.Get(
                                SalesHeader."Document Type"::Order,
                                "Basis No.")
                            then
                                Error(
                                    'Sales Order %1 не знайдено.',
                                    "Basis No.");

                            if SalesHeader."Sell-to Customer No." <>
                               "Customer No."
                            then
                                Error(
                                    'Sales Order %1 належить клієнту %2, а в документі вагової вибрано клієнта %3.',
                                    "Basis No.",
                                    SalesHeader."Sell-to Customer No.",
                                    "Customer No.");
                        end;

                    "SI WB Basis Type"::Request:
                        Error(
                            'Заявки ще не підключені в поточному MVP.');

                    else
                        Error(
                            'Спочатку має бути визначено тип підстави.');
                end;
            end;
        }

        field(92; "Submitted At"; DateTime)
        {
            Caption = 'Передано менеджеру';
            Editable = false;
        }

        field(93; "Submitted By"; Guid)
        {
            Caption = 'Передано користувачем';
            Editable = false;
        }


        field(94; "Documents Created At"; DateTime)
        {
            Caption = 'Документи створено';
            Editable = false;
        }

        field(95; "Documents Created By"; Guid)
        {
            Caption = 'Документи створено користувачем';
            Editable = false;
        }

        field(96; "Accounting Handoff At"; DateTime)
        {
            Caption = 'Передано бухгалтерії';
            Editable = false;
        }

        field(97; "Accounting Handoff By"; Guid)
        {
            Caption = 'Передано бухгалтерії користувачем';
            Editable = false;
        }

        // ------------------------------------------------------------
        // Accounting stage / Posting Template Resolver
        // ------------------------------------------------------------

        field(100; "Posting Template Code"; Code[20])
        {
            Caption = 'Шаблон обліку';
            TableRelation = "SI WB Posting Template".Code;
            Editable = false;
        }

        field(101; "Posting Template Resolved At"; DateTime)
        {
            Caption = 'Шаблон обліку визначено';
            Editable = false;
        }

        field(102; "Posting Template Applied At"; DateTime)
        {
            Caption = 'Шаблон обліку застосовано';
            Editable = false;
        }

        field(103; "Posting Template Applied By"; Guid)
        {
            Caption = 'Шаблон застосовано користувачем';
            Editable = false;
        }

        field(104; "Resolved Location Code"; Code[10])
        {
            Caption = 'Визначений склад';
            TableRelation = Location.Code;
            DataClassification = CustomerContent;
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }

        key(DocumentNo; "Document No.")
        {
            Unique = true;
        }

        key(WeighingEntry; "Weighing Entry No.")
        {
            Unique = true;
        }

        key(StatusKey; Status, "Created At")
        {
        }

        key(OperationKey; "Operation Type", Status)
        {
        }
    }

    trigger OnInsert()
    var
        EmptyGuid: Guid;
    begin
        TestField("Weighing Entry No.");

        if "Document No." = '' then
            "Document No." := BuildDocumentNo();

        if "Created At" = 0DT then
            "Created At" := CurrentDateTime();

        if "Created By" = EmptyGuid then
            "Created By" := UserSecurityId();

        "Modified At" := "Created At";
        "Modified By" := "Created By";
    end;

    trigger OnModify()
    begin
        "Modified At" := CurrentDateTime();
        "Modified By" := UserSecurityId();
    end;

    local procedure ClearBasis()
    begin
        "Basis Type" := "SI WB Basis Type"::Undefined;
        Clear("Basis No.");
    end;

    local procedure BuildDocumentNo(): Code[20]
    begin
        exit(
            CopyStr(
                StrSubstNo(
                    'WB-%1',
                    "Weighing Entry No."),
                1,
                MaxStrLen("Document No.")));
    end;
}