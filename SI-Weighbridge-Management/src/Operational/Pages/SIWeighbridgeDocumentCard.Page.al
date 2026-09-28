page 59101 "SI Weighbridge Document Card"
{
    PageType = Card;
    SourceTable = "SI Weighbridge Document";

    ApplicationArea = All;
    UsageCategory = None;

    Caption = 'Операційний документ вагової';

    layout
    {
        area(Content)
        {
            // =========================================================
            // GENERAL
            // Physical direction + dependent business scenario + subject
            // =========================================================
            group(General)
            {
                Caption = 'Загальне';

                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                    Caption = '№ документа';
                    Editable = false;
                }

                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    Caption = 'Статус';
                    Editable = false;
                }

                field("Operation Type"; Rec."Operation Type")
                {
                    ApplicationArea = All;
                    Caption = 'Операція';
                    Editable = false;

                    ToolTip =
                        'Фізичний напрямок зважування. Значення визначається системою з PromSoft і не редагується оператором.';
                }

                // ---------------------------------------------------------
                // 2) TYPE OF OPERATION — ALWAYS VISIBLE
                // Receipt  -> "Постачання", read-only.
                // Shipment -> user chooses exactly one of two options.
                // A page Text variable is used deliberately so BC cannot
                // suppress the control because of conditional visibility.
                // ---------------------------------------------------------
                field(OperationTypeDisplay; OperationTypeDisplay)
                {
                    ApplicationArea = All;
                    Caption = 'Тип операції';
                    Editable = ShipmentVisible and OperatorEditable;
                    Lookup = true;

                    ToolTip =
                        'Для надходження значення автоматично "Постачання". Для відвантаження виберіть "Продаж" або "Внутрішнє переміщення".';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        if not ShipmentVisible then
                            exit(false);

                        SelectShipmentOperationType();

                        Text := OperationTypeDisplay;
                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        ValidateOperationTypeText();
                    end;
                }
            }

            // =========================================================
            // COUNTERPARTY / RECIPIENT — ALWAYS VISIBLE SECTION
            // The lookup target is derived from Operation + Type:
            // Receipt/Supply -> Vendor
            // Shipment/Sales -> Customer
            // Shipment/Internal Transfer -> Project
            // =========================================================
            group(CounterpartyRecipient)
            {
                Caption = 'Контрагент / Отримувач';

                field(PartnerRecipientDisplay; PartnerRecipientDisplay)
                {
                    ApplicationArea = All;
                    Caption = 'Партнер / Отримувач';
                    Lookup = true;
                    Editable = OperatorEditable;

                    ToolTip =
                        'Відображається назва постачальника, клієнта або проєкту. Сам код зберігається у відповідному полі Vendor No. / Customer No. / Project No.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        LookupPartnerRecipient();

                        Text := PartnerRecipientDisplay;
                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        // Manual text is not persisted. Restore the display
                        // value from the selected routed entity.
                        LoadPartnerRecipientDisplay();
                    end;
                }
            }

            // =========================================================
            // MANAGER STAGE / BUSINESS BASIS
            // Basis Type is derived from Operation + Scenario.
            // Manager selects only the concrete basis document.
            // =========================================================
            group(BusinessBasis)
            {
                Caption = 'Підстава операції';

                field("Basis Type"; Rec."Basis Type")
                {
                    ApplicationArea = All;
                    Caption = 'Тип підстави';
                    Editable = false;
                }

                field("Basis No."; Rec."Basis No.")
                {
                    ApplicationArea = All;
                    Caption = 'Документ-підстава';
                    Editable = ManagerEditable;
                    Lookup = true;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        LookupBasisDocument();
                        Text := Rec."Basis No.";
                        exit(true);
                    end;
                }
            }

            // =========================================================
            // ACCOUNTING STAGE / POSTING TEMPLATE
            // 1.1.1.8: Resolver selects the template and the Applier writes
            // explicit accounting defaults to the linked Purchase/Sales Order.
            // =========================================================
            group(AccountingTemplate)
            {
                Caption = 'Облік';

                field("Posting Template Code"; Rec."Posting Template Code")
                {
                    ApplicationArea = All;
                    Caption = 'Шаблон обліку';
                    Editable = false;
                }

                field("Posting Template Resolved At"; Rec."Posting Template Resolved At")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field("Posting Template Applied At"; Rec."Posting Template Applied At")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field("Posting Template Applied By"; Rec."Posting Template Applied By")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field("Resolved Location Code"; Rec."Resolved Location Code")
                {
                    ApplicationArea = All;
                    Caption = 'Визначений склад';
                    Editable = false;
                }
            }

            // =========================================================
            // SCALE SOURCE DATA
            // =========================================================
            group(ScaleData)
            {
                Caption = 'Дані з автоваг';

                field("Weighing Entry No."; Rec."Weighing Entry No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field("Weighing Date/Time"; Rec."Weighing Date/Time")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field("Vehicle Plate"; Rec."Vehicle Plate")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field("Trailer Plate"; Rec."Trailer Plate")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field("Site Code"; Rec."Site Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field("Scale No."; Rec."Scale No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }

            // =========================================================
            // WEIGHING
            // =========================================================
            group(WeightData)
            {
                Caption = 'Дані зважування';

                field("Gross Weight"; Rec."Gross Weight")
                {
                    ApplicationArea = All;
                    Caption = 'Брутто, кг';
                    Editable = false;
                }

                field("Tare Weight"; Rec."Tare Weight")
                {
                    ApplicationArea = All;
                    Caption = 'Тара, кг';
                    Editable = false;
                }

                field("Net Weight"; Rec."Net Weight")
                {
                    ApplicationArea = All;
                    Caption = 'Нетто, кг';
                    Editable = false;
                }
            }

            // =========================================================
            // COMPACT 1:N BUSINESS LINES
            // Custom Control Add-In is used specifically to avoid the
            // standard ListPart minimum canvas / "mattress".
            // =========================================================
            group(LinesGroup)
            {
                Caption = 'Рядки';

                usercontrol(CompactLines; "SI WB Compact Lines")
                {
                    ApplicationArea = All;

                    trigger ControlReady()
                    begin
                        CompactLinesReady := true;
                        RefreshCompactLines();
                    end;

                    trigger AddLineRequested()
                    begin
                        AddCompactLine();
                    end;

                    trigger DeleteLineRequested(LineNo: Integer)
                    begin
                        DeleteCompactLine(LineNo);
                    end;

                    trigger RecalculateRequested(LineNo: Integer)
                    begin
                        RecalculateCompactLine(LineNo);
                    end;

                    trigger ItemLookupRequested(LineNo: Integer)
                    begin
                        LookupCompactLineItem(LineNo);
                    end;

                    trigger VariantLookupRequested(LineNo: Integer)
                    begin
                        LookupCompactLineVariant(LineNo);
                    end;

                    trigger AllocatedWeightChanged(
                        LineNo: Integer;
                        NewValue: Decimal)
                    begin
                        UpdateCompactAllocatedWeight(
                            LineNo,
                            NewValue);
                    end;
                }
            }

            // =========================================================
            // COMPACT CONVERSION STRIP
            // Inline parent fields instead of another ListPart.
            // This avoids the second large empty list canvas.
            // =========================================================
            group(Conversion)
            {
                Caption = 'Перерахунок';

                grid(ConversionGrid)
                {
                    GridLayout = Columns;

                    field(ConversionSource; ConversionSource)
                    {
                        ApplicationArea = All;
                        Caption = 'Джерело';
                        Editable = false;
                    }

                    field(ConversionFactor; ConversionFactor)
                    {
                        ApplicationArea = All;
                        Caption = 'Коефіцієнт';
                        Editable = false;
                    }

                    field(ConversionResult; ConversionResult)
                    {
                        ApplicationArea = All;
                        Caption = 'Результат';
                        Editable = false;
                    }

                    field(ConversionError; ConversionError)
                    {
                        ApplicationArea = All;
                        Caption = 'Помилка';
                        Editable = false;
                        Visible = ConversionErrorVisible;
                    }
                }
            }

            // =========================================================
            // COMPACT 1:N SUPPORTING DOCUMENTS
            // Custom Control Add-In removes the standard ListPart canvas.
            // =========================================================
            group(SupportingDocumentsGroup)
            {
                Caption = 'Супровідні документи';

                usercontrol(CompactDocs; "SI WB Compact Docs")
                {
                    ApplicationArea = All;

                    trigger ControlReady()
                    begin
                        CompactDocsReady := true;
                        RefreshCompactDocs();
                    end;

                    trigger AddRowRequested()
                    begin
                        AddSupportingDocumentRow();
                    end;

                    trigger DeleteRowRequested(LineNo: Integer)
                    begin
                        DeleteSupportingDocumentRow(LineNo);
                    end;

                    trigger UploadFileRequested(LineNo: Integer)
                    begin
                        UploadSupportingDocumentFile(LineNo);
                    end;

                    trigger OpenFileRequested(LineNo: Integer)
                    begin
                        OpenSupportingDocumentFile(LineNo);
                    end;

                    trigger DocumentTypeChanged(
                        LineNo: Integer;
                        NewValue: Integer)
                    begin
                        UpdateSupportingDocumentType(
                            LineNo,
                            NewValue);
                    end;

                    trigger DocumentNoChanged(
                        LineNo: Integer;
                        NewValue: Text)
                    begin
                        UpdateSupportingDocumentNo(
                            LineNo,
                            NewValue);
                    end;

                    trigger DocumentDateChanged(
                        LineNo: Integer;
                        YearValue: Integer;
                        MonthValue: Integer;
                        DayValue: Integer)
                    begin
                        UpdateSupportingDocumentDate(
                            LineNo,
                            YearValue,
                            MonthValue,
                            DayValue);
                    end;

                    trigger NoteChanged(
                        LineNo: Integer;
                        NewValue: Text)
                    begin
                        UpdateSupportingDocumentNote(
                            LineNo,
                            NewValue);
                    end;
                }
            }
        }

        area(FactBoxes)
        {
            part(Audit; "SI WB Audit FactBox")
            {
                ApplicationArea = All;

                SubPageLink =
                    "Entry No." = field("Entry No.");
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            group(RelatedDocuments)
            {
                Caption = 'Пов''язані';
                Image = Navigate;

                action(OpenBasisDocument)
                {
                    ApplicationArea = All;
                    Caption = 'Відкрити документ-підставу';
                    Image = Document;
                    Enabled = Rec."Basis No." <> '';

                    trigger OnAction()
                    begin
                        OpenBasisDocumentCard();
                    end;
                }

                action(OpenERPDocument)
                {
                    ApplicationArea = All;
                    Caption = 'Відкрити ERP-документ';
                    Image = Document;
                    Enabled = Rec."ERP Document No." <> '';

                    trigger OnAction()
                    begin
                        OpenERPDocumentCard();
                    end;
                }
            }

            action(OpenWeighing)
            {
                ApplicationArea = All;
                Caption = 'Зважування';
                Image = Navigate;

                trigger OnAction()
                var
                    WeighingRecord: Record "SI Weighing Record";
                begin
                    if not WeighingRecord.Get(
                        Rec."Weighing Entry No.")
                    then
                        Error(
                            'Зважування %1 не знайдено.',
                            Rec."Weighing Entry No.");

                    Page.Run(
                        Page::"SI Weighing Record Card",
                        WeighingRecord);
                end;
            }

            action(SubmitToManager)
            {
                ApplicationArea = All;
                Caption = 'Передати менеджеру';
                Image = SendApprovalRequest;
                Enabled = OperatorEditable;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    DocumentMgt: Codeunit "SI WB Document Mgt.";
                begin
                    DocumentMgt.SubmitToManager(Rec);
                    LoadDisplayValues();
                    CurrPage.Update(false);
                    Message(
                        'Документ %1 передано менеджеру.',
                        Rec."Document No.");
                end;
            }


            action(CreateDocuments)
            {
                ApplicationArea = All;
                Caption = 'Створити документи';
                Image = Process;
                Visible = ShipmentVisible;
                Enabled = CanCreateDocuments;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    GenerationMgt: Codeunit "SI WB Document Generation Mgt.";
                begin
                    GenerationMgt.CreateDocuments(Rec);
                    LoadDisplayValues();
                    RefreshCompactDocs();
                    CurrPage.Update(false);
                    Message(
                        'Документи для %1 створено та передано до бухгалтерії.',
                        Rec."Document No.");
                end;
            }

            action(HandoffReceiptToAccounting)
            {
                ApplicationArea = All;
                Caption = 'Передати до бухгалтерії';
                Image = SendApprovalRequest;
                Visible = ReceiptVisible;
                Enabled = CanHandoffToAccounting;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    GenerationMgt: Codeunit "SI WB Document Generation Mgt.";
                begin
                    GenerationMgt.HandoffReceiptToAccounting(Rec);
                    LoadDisplayValues();
                    RefreshCompactDocs();
                    CurrPage.Update(false);
                    Message(
                        'Документ %1 передано до бухгалтерії.',
                        Rec."Document No.");
                end;
            }

            action(ResolvePostingTemplate)
            {
                ApplicationArea = All;
                Caption = 'Визначити шаблон обліку';
                Image = Calculate;
                Enabled = CanResolvePostingTemplate;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    Resolver: Codeunit "SI WB Posting Templ. Resolver";
                    ResolvedCode: Code[20];
                begin
                    ResolvedCode := Resolver.ResolveAndAssign(Rec);
                    LoadDisplayValues();
                    CurrPage.Update(false);
                    if Rec."Resolved Location Code" <> '' then
                        Message(
                            'Для документа %1 визначено шаблон обліку %2. Визначений склад: %3.',
                            Rec."Document No.",
                            ResolvedCode,
                            Rec."Resolved Location Code")
                    else
                        Message(
                            'Для документа %1 визначено шаблон обліку %2.',
                            Rec."Document No.",
                            ResolvedCode);
                end;
            }

            action(ApplyPostingTemplate)
            {
                ApplicationArea = All;
                Caption = 'Застосувати шаблон обліку';
                Image = Apply;
                Enabled = CanApplyPostingTemplate;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    Applier: Codeunit "SI WB Posting Templ. Applier";
                begin
                    Applier.Apply(Rec);
                    LoadDisplayValues();
                    CurrPage.Update(false);
                    Message(
                        'Для документа %1 застосовано шаблон обліку %2 до %3 %4. Визначений склад: %5.',
                        Rec."Document No.",
                        Rec."Posting Template Code",
                        Rec."ERP Document Type",
                        Rec."ERP Document No.",
                        Rec."Resolved Location Code");
                end;
            }

            action(PostingTemplates)
            {
                ApplicationArea = All;
                Caption = 'Шаблони обліку';
                Image = Setup;

                trigger OnAction()
                begin
                    Page.Run(Page::"SI WB Posting Templates");
                end;
            }

            action(DocumentSetup)
            {
                ApplicationArea = All;
                Caption = 'Налаштування нумерації';
                Image = Setup;

                trigger OnAction()
                begin
                    Page.Run(Page::"SI WB Document Setup");
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        EnsureDomainDefaults();
        LoadDisplayValues();

        RefreshCompactLines();
        RefreshCompactDocs();
    end;

    local procedure EnsureDomainDefaults()
    var
        SupportingDocsMgt: Codeunit "SI WB Supporting Docs Mgt.";
    begin
        if Rec."Entry No." = 0 then
            exit;

        // Compatibility backfill for documents created before the
        // dependent Scenario contract was introduced.
        if (Rec."Operation Type" =
            "SI WB Operation Type"::Receipt) and
           (Rec."Shipment Scenario" =
            "SI WB Shipment Scenario"::Undefined)
        then begin
            Rec.Validate(
                "Shipment Scenario",
                "SI WB Shipment Scenario"::Supply);
            Rec.Modify(true);
        end;

        SupportingDocsMgt.EnsureForDocument(Rec);
    end;

    local procedure LoadDisplayValues()
    begin
        OperatorEditable :=
            Rec.Status = "SI WB Document Status"::New;

        ManagerEditable :=
            Rec.Status = "SI WB Document Status"::Submitted;


        CanCreateDocuments :=
            ManagerEditable and
            (Rec."Operation Type" = "SI WB Operation Type"::Shipment) and
            (Rec."Basis No." <> '');

        CanHandoffToAccounting :=
            ManagerEditable and
            (Rec."Operation Type" = "SI WB Operation Type"::Receipt) and
            (Rec."Shipment Scenario" = "SI WB Shipment Scenario"::Supply) and
            (Rec."Basis No." <> '');

        CanResolvePostingTemplate :=
            (Rec.Status = "SI WB Document Status"::"Documents Created") and
            (Rec."Basis No." <> '');

        CanApplyPostingTemplate :=
            (Rec.Status = "SI WB Document Status"::"Documents Created") and
            (Rec."Basis No." <> '');

        ReceiptVisible :=
            Rec."Operation Type" =
            "SI WB Operation Type"::Receipt;

        ShipmentVisible :=
            Rec."Operation Type" =
            "SI WB Operation Type"::Shipment;

        VendorVisible :=
            ReceiptVisible and
            (Rec."Shipment Scenario" =
             "SI WB Shipment Scenario"::Supply);

        CustomerVisible :=
            ShipmentVisible and
            (Rec."Shipment Scenario" =
             "SI WB Shipment Scenario"::Sales);

        ProjectVisible :=
            ShipmentVisible and
            (Rec."Shipment Scenario" =
             "SI WB Shipment Scenario"::"Internal Transfer");

        case Rec."Operation Type" of
            "SI WB Operation Type"::Receipt:
                OperationTypeDisplay := 'Постачання';

            "SI WB Operation Type"::Shipment:
                case Rec."Shipment Scenario" of
                    "SI WB Shipment Scenario"::Sales:
                        OperationTypeDisplay := 'Продаж';

                    "SI WB Shipment Scenario"::"Internal Transfer":
                        OperationTypeDisplay := 'Внутрішнє переміщення';

                    else
                        Clear(OperationTypeDisplay);
                end;

            else
                Clear(OperationTypeDisplay);
        end;

        LoadPartnerRecipientDisplay();
        LoadConversionDisplay();
    end;

    local procedure SelectShipmentOperationType()
    var
        Choice: Integer;
    begin
        EnsureOperatorEditable();
        Choice :=
            StrMenu(
                'Продаж,Внутрішнє переміщення',
                1,
                'Виберіть тип операції');

        case Choice of
            1:
                SetShipmentScenario(
                    "SI WB Shipment Scenario"::Sales);

            2:
                SetShipmentScenario(
                    "SI WB Shipment Scenario"::"Internal Transfer");
        end;
    end;

    local procedure ValidateOperationTypeText()
    begin
        EnsureOperatorEditable();
        if not ShipmentVisible then begin
            OperationTypeDisplay := 'Постачання';
            exit;
        end;

        case UpperCase(DelChr(OperationTypeDisplay, '<>', ' ')) of
            UpperCase('Продаж'):
                SetShipmentScenario(
                    "SI WB Shipment Scenario"::Sales);

            UpperCase('Внутрішнєпереміщення'):
                SetShipmentScenario(
                    "SI WB Shipment Scenario"::"Internal Transfer");

            else
                Error(
                    'Для відвантаження доступні тільки "Продаж" або "Внутрішнє переміщення".');
        end;
    end;

    local procedure SetShipmentScenario(
        Scenario: Enum "SI WB Shipment Scenario")
    var
        SupportingDocsMgt: Codeunit "SI WB Supporting Docs Mgt.";
    begin
        Rec.Validate(
            "Shipment Scenario",
            Scenario);
        Rec.Modify(true);

        SupportingDocsMgt.EnsureForDocument(Rec);

        LoadDisplayValues();
        CurrPage.Update(false);
    end;

    local procedure LoadPartnerRecipientDisplay()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        Project: Record Job;
    begin
        Clear(PartnerRecipientDisplay);

        if VendorVisible then begin
            if (Rec."Vendor No." <> '') and
               Vendor.Get(Rec."Vendor No.")
            then
                PartnerRecipientDisplay := Vendor.Name;

            exit;
        end;

        if CustomerVisible then begin
            if (Rec."Customer No." <> '') and
               Customer.Get(Rec."Customer No.")
            then
                PartnerRecipientDisplay := Customer.Name;

            exit;
        end;

        if ProjectVisible then
            if (Rec."Project No." <> '') and
               Project.Get(Rec."Project No.")
            then
                PartnerRecipientDisplay := Project.Description;
    end;

    local procedure LookupPartnerRecipient()
    begin
        EnsureOperatorEditable();
        if VendorVisible then begin
            LookupVendor();
            exit;
        end;

        if CustomerVisible then begin
            LookupCustomer();
            exit;
        end;

        if ProjectVisible then begin
            LookupProject();
            exit;
        end;

        if ShipmentVisible then
            Error(
                'Спочатку виберіть тип операції: "Продаж" або "Внутрішнє переміщення".');

        Error(
            'Не вдалося визначити тип контрагента/отримувача.');
    end;

    local procedure LookupVendor()
    var
        Vendor: Record Vendor;
        VendorList: Page "Vendor List";
    begin
        VendorList.LookupMode(true);

        if (Rec."Vendor No." <> '') and
           Vendor.Get(Rec."Vendor No.")
        then
            VendorList.SetRecord(Vendor);

        if VendorList.RunModal() <> Action::LookupOK then
            exit;

        VendorList.GetRecord(Vendor);

        Rec.Validate("Vendor No.", Vendor."No.");
        Rec.Modify(true);

        LoadPartnerRecipientDisplay();
        CurrPage.Update(false);
    end;

    local procedure LookupCustomer()
    var
        Customer: Record Customer;
        CustomerList: Page "Customer List";
    begin
        CustomerList.LookupMode(true);

        if (Rec."Customer No." <> '') and
           Customer.Get(Rec."Customer No.")
        then
            CustomerList.SetRecord(Customer);

        if CustomerList.RunModal() <> Action::LookupOK then
            exit;

        CustomerList.GetRecord(Customer);

        Rec.Validate("Customer No.", Customer."No.");
        Rec.Modify(true);

        LoadPartnerRecipientDisplay();
        CurrPage.Update(false);
    end;

    local procedure LookupProject()
    var
        Project: Record Job;
        ProjectList: Page "Job List";
    begin
        ProjectList.LookupMode(true);

        if (Rec."Project No." <> '') and
           Project.Get(Rec."Project No.")
        then
            ProjectList.SetRecord(Project);

        if ProjectList.RunModal() <> Action::LookupOK then
            exit;

        ProjectList.GetRecord(Project);

        Rec.Validate("Project No.", Project."No.");
        Rec.Modify(true);

        LoadPartnerRecipientDisplay();
        CurrPage.Update(false);
    end;

    // =============================================================
    // COMPACT LINES CONTROL ADD-IN
    // =============================================================

    local procedure RefreshCompactLines()
    begin
        if not CompactLinesReady then
            exit;

        CurrPage.CompactLines.SetData(
            BuildCompactLinesJson());
    end;

    local procedure BuildCompactLinesJson(): Text
    var
        WeighbridgeLine: Record "SI Weighbridge Document Line";
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        LinesJson: JsonArray;
        LineJson: JsonObject;
        JsonText: Text;
        ItemDisplay: Text;
        VariantDisplay: Text;
    begin
        if Rec."Entry No." = 0 then begin
            LinesJson.WriteTo(JsonText);
            exit(JsonText);
        end;

        WeighbridgeLine.Reset();
        WeighbridgeLine.SetRange(
            "Document Entry No.",
            Rec."Entry No.");

        if WeighbridgeLine.FindSet() then
            repeat
                Clear(LineJson);
                Clear(ItemDisplay);
                Clear(VariantDisplay);

                ItemDisplay := WeighbridgeLine."Item No.";

                if (WeighbridgeLine."Item No." <> '') and
                   Item.Get(WeighbridgeLine."Item No.") and
                   (Item.Description <> '')
                then
                    ItemDisplay := Item.Description;

                VariantDisplay := WeighbridgeLine."Variant Code";

                if (WeighbridgeLine."Item No." <> '') and
                   (WeighbridgeLine."Variant Code" <> '') and
                   ItemVariant.Get(
                       WeighbridgeLine."Item No.",
                       WeighbridgeLine."Variant Code") and
                   (ItemVariant.Description <> '')
                then
                    VariantDisplay := ItemVariant.Description;

                LineJson.Add(
                    'lineNo',
                    WeighbridgeLine."Line No.");

                LineJson.Add(
                    'itemNo',
                    WeighbridgeLine."Item No.");

                LineJson.Add(
                    'itemDisplay',
                    ItemDisplay);

                LineJson.Add(
                    'variantCode',
                    WeighbridgeLine."Variant Code");

                LineJson.Add(
                    'variantDisplay',
                    VariantDisplay);

                LineJson.Add(
                    'allocatedWeight',
                    WeighbridgeLine."Allocated Weight");

                LineJson.Add(
                    'weightUom',
                    WeighbridgeLine."Weight UoM Code");

                LineJson.Add(
                    'quantity',
                    WeighbridgeLine.Quantity);

                LineJson.Add(
                    'itemUom',
                    WeighbridgeLine."Unit of Measure Code");

                LinesJson.Add(LineJson);
            until WeighbridgeLine.Next() = 0;

        LinesJson.WriteTo(JsonText);
        exit(JsonText);
    end;

    local procedure AddCompactLine()
    var
        NewLine: Record "SI Weighbridge Document Line";
        ExistingLine: Record "SI Weighbridge Document Line";
        NextLineNo: Integer;
        AllocatedTotal: Decimal;
        RemainingWeight: Decimal;
    begin
        EnsureOperatorEditable();
        Rec.TestField("Entry No.");

        ExistingLine.Reset();
        ExistingLine.SetRange(
            "Document Entry No.",
            Rec."Entry No.");

        if ExistingLine.FindSet() then
            repeat
                AllocatedTotal +=
                    ExistingLine."Allocated Weight";

                if ExistingLine."Line No." > NextLineNo then
                    NextLineNo :=
                        ExistingLine."Line No.";
            until ExistingLine.Next() = 0;

        RemainingWeight :=
            Rec."Net Weight" -
            AllocatedTotal;

        if RemainingWeight <= 0 then
            Error(
                'Уся фізична вага вже розподілена між рядками. Перед додаванням нового рядка зменште розподілену вагу існуючого рядка.');

        NewLine.Init();

        NewLine."Document Entry No." :=
            Rec."Entry No.";

        NewLine."Line No." :=
            NextLineNo + 10000;

        NewLine."Allocated Weight" :=
            RemainingWeight;

        NewLine.EnsureWeightUoM();
        NewLine.Insert(true);

        RefreshAfterCompactLineChange();
    end;

    local procedure DeleteCompactLine(
        LineNo: Integer)
    var
        WeighbridgeLine: Record "SI Weighbridge Document Line";
    begin
        EnsureOperatorEditable();
        GetCompactLine(
            LineNo,
            WeighbridgeLine);

        if not Confirm(
            'Видалити рядок %1?',
            false,
            LineNo)
        then
            exit;

        WeighbridgeLine.Delete(true);

        RefreshAfterCompactLineChange();
    end;

    local procedure RecalculateCompactLine(
        LineNo: Integer)
    var
        WeighbridgeLine: Record "SI Weighbridge Document Line";
        UoMConversionMgt: Codeunit "SI WB UoM Conversion Mgt.";
    begin
        EnsureOperatorEditable();
        GetCompactLine(
            LineNo,
            WeighbridgeLine);

        UoMConversionMgt.RecalculateLine(
            WeighbridgeLine);

        WeighbridgeLine.Modify(true);

        RefreshAfterCompactLineChange();
    end;

    local procedure LookupCompactLineItem(
        LineNo: Integer)
    var
        WeighbridgeLine: Record "SI Weighbridge Document Line";
        Item: Record Item;
    begin
        EnsureOperatorEditable();
        GetCompactLine(
            LineNo,
            WeighbridgeLine);

        if WeighbridgeLine."Item No." <> '' then
            Item.SetRange(
                "No.",
                WeighbridgeLine."Item No.");

        if Page.RunModal(
            Page::"Item List",
            Item) <> Action::LookupOK
        then
            exit;

        WeighbridgeLine.Validate(
            "Item No.",
            Item."No.");

        WeighbridgeLine.Modify(true);

        RefreshAfterCompactLineChange();
    end;

    local procedure LookupCompactLineVariant(
        LineNo: Integer)
    var
        WeighbridgeLine: Record "SI Weighbridge Document Line";
        ItemVariant: Record "Item Variant";
    begin
        EnsureOperatorEditable();
        GetCompactLine(
            LineNo,
            WeighbridgeLine);

        WeighbridgeLine.TestField("Item No.");

        ItemVariant.Reset();
        ItemVariant.SetRange(
            "Item No.",
            WeighbridgeLine."Item No.");

        if Page.RunModal(
            Page::"Item Variants",
            ItemVariant) <> Action::LookupOK
        then
            exit;

        WeighbridgeLine.Validate(
            "Variant Code",
            ItemVariant.Code);

        WeighbridgeLine.Modify(true);

        RefreshAfterCompactLineChange();
    end;

    local procedure UpdateCompactAllocatedWeight(
        LineNo: Integer;
        NewValue: Decimal)
    var
        WeighbridgeLine: Record "SI Weighbridge Document Line";
    begin
        EnsureOperatorEditable();
        GetCompactLine(
            LineNo,
            WeighbridgeLine);

        WeighbridgeLine.Validate(
            "Allocated Weight",
            NewValue);

        WeighbridgeLine.Modify(true);

        RefreshAfterCompactLineChange();
    end;

    local procedure GetCompactLine(
        LineNo: Integer;
        var WeighbridgeLine: Record "SI Weighbridge Document Line")
    begin
        Rec.TestField("Entry No.");

        if not WeighbridgeLine.Get(
            Rec."Entry No.",
            LineNo)
        then
            Error(
                'Рядок %1 операційного документа не знайдено.',
                LineNo);
    end;

    local procedure RefreshAfterCompactLineChange()
    begin
        LoadDisplayValues();
        CurrPage.Update(false);

        RefreshCompactLines();
    end;

    // =============================================================
    // COMPACT SUPPORTING DOCUMENTS CONTROL ADD-IN
    // =============================================================

    local procedure RefreshCompactDocs()
    begin
        if not CompactDocsReady then
            exit;

        CurrPage.CompactDocs.SetData(
            BuildCompactDocsJson());
    end;

    local procedure BuildCompactDocsJson(): Text
    var
        SupportingDoc: Record "SI WB Supporting Document";
        DocsJson: JsonArray;
        DocJson: JsonObject;
        JsonText: Text;
    begin
        if Rec."Entry No." = 0 then begin
            DocsJson.WriteTo(JsonText);
            exit(JsonText);
        end;

        SupportingDoc.Reset();
        SupportingDoc.SetRange(
            "Document Entry No.",
            Rec."Entry No.");

        if SupportingDoc.FindSet() then
            repeat
                Clear(DocJson);

                DocJson.Add(
                    'lineNo',
                    SupportingDoc."Line No.");

                DocJson.Add(
                    'typeValue',
                    SupportingDoc."Document Type".AsInteger());

                DocJson.Add(
                    'typeCaption',
                    Format(SupportingDoc."Document Type"));

                DocJson.Add(
                    'documentNo',
                    SupportingDoc."Document No.");

                if SupportingDoc."Document Date" = 0D then
                    DocJson.Add(
                        'documentDate',
                        '')
                else
                    DocJson.Add(
                        'documentDate',
                        Format(
                            SupportingDoc."Document Date",
                            0,
                            '<Year4>-<Month,2>-<Day,2>'));

                DocJson.Add(
                    'fileName',
                    SupportingDoc."File Name");

                DocJson.Add(
                    'hasAttachment',
                    SupportingDoc.HasAttachment());

                DocJson.Add(
                    'note',
                    SupportingDoc.Note);

                DocsJson.Add(DocJson);
            until SupportingDoc.Next() = 0;

        DocsJson.WriteTo(JsonText);
        exit(JsonText);
    end;

    local procedure AddSupportingDocumentRow()
    var
        SupportingDoc: Record "SI WB Supporting Document";
        LastDoc: Record "SI WB Supporting Document";
        NextLineNo: Integer;
    begin
        EnsureSupportingDocsEditable();
        Rec.TestField("Entry No.");

        LastDoc.Reset();
        LastDoc.SetRange(
            "Document Entry No.",
            Rec."Entry No.");

        if LastDoc.FindLast() then
            NextLineNo :=
                LastDoc."Line No." + 10000
        else
            NextLineNo :=
                10000;

        SupportingDoc.Init();

        SupportingDoc."Document Entry No." :=
            Rec."Entry No.";

        SupportingDoc."Line No." :=
            NextLineNo;

        SupportingDoc."Document Type" :=
            "SI WB Supporting Doc Type"::Undefined;

        SupportingDoc.Insert(true);

        RefreshCompactDocs();
    end;

    local procedure DeleteSupportingDocumentRow(
        LineNo: Integer)
    var
        SupportingDoc: Record "SI WB Supporting Document";
    begin
        EnsureSupportingDocsEditable();
        GetSupportingDocument(
            LineNo,
            SupportingDoc);

        if not Confirm(
            'Видалити супровідний документ "%1"?',
            false,
            Format(SupportingDoc."Document Type"))
        then
            exit;

        SupportingDoc.Delete(true);

        RefreshCompactDocs();
    end;

    local procedure UploadSupportingDocumentFile(
        LineNo: Integer)
    var
        SupportingDoc: Record "SI WB Supporting Document";
        InStr: InStream;
        OutStr: OutStream;
        FileName: Text;
    begin
        EnsureSupportingDocsEditable();
        GetSupportingDocument(
            LineNo,
            SupportingDoc);

        if not UploadIntoStream(
            'Виберіть файл',
            '',
            'Усі файли (*.*)|*.*',
            FileName,
            InStr)
        then
            exit;

        SupportingDoc.Attachment.CreateOutStream(
            OutStr);

        CopyStream(
            OutStr,
            InStr);

        SupportingDoc."File Name" :=
            CopyStr(
                FileName,
                1,
                MaxStrLen(SupportingDoc."File Name"));

        SupportingDoc.Modify(true);

        RefreshCompactDocs();
    end;

    local procedure OpenSupportingDocumentFile(
        LineNo: Integer)
    var
        SupportingDoc: Record "SI WB Supporting Document";
        InStr: InStream;
        FileName: Text;
    begin
        GetSupportingDocument(
            LineNo,
            SupportingDoc);

        SupportingDoc.CalcFields(
            Attachment);

        if not SupportingDoc.Attachment.HasValue() then
            Error(
                'Для цього документа файл не додано.');

        SupportingDoc.Attachment.CreateInStream(
            InStr);

        FileName :=
            SupportingDoc."File Name";

        if FileName = '' then
            FileName :=
                'attachment';

        DownloadFromStream(
            InStr,
            '',
            '',
            '',
            FileName);
    end;

    local procedure UpdateSupportingDocumentType(
        LineNo: Integer;
        NewValue: Integer)
    var
        SupportingDoc: Record "SI WB Supporting Document";
    begin
        EnsureSupportingDocsEditable();
        GetSupportingDocument(
            LineNo,
            SupportingDoc);

        case NewValue of
            0:
                SupportingDoc."Document Type" :=
                    "SI WB Supporting Doc Type"::Undefined;

            10:
                SupportingDoc."Document Type" :=
                    "SI WB Supporting Doc Type"::TTN;

            20:
                SupportingDoc."Document Type" :=
                    "SI WB Supporting Doc Type"::"Vendor Delivery Note";

            30:
                SupportingDoc."Document Type" :=
                    "SI WB Supporting Doc Type"::"Delivery Note";

            35:
                SupportingDoc."Document Type" :=
                    "SI WB Supporting Doc Type"::"Internal Transfer Document";

            40:
                SupportingDoc."Document Type" :=
                    "SI WB Supporting Doc Type"::"Product Passport";

            90:
                SupportingDoc."Document Type" :=
                    "SI WB Supporting Doc Type"::Other;

            else
                Error(
                    'Непідтримуваний тип супровідного документа: %1.',
                    NewValue);
        end;

        SupportingDoc.Modify(true);
        SupportingDoc.SyncLegacyHeader();

        RefreshCompactDocs();
    end;

    local procedure UpdateSupportingDocumentNo(
        LineNo: Integer;
        NewValue: Text)
    var
        SupportingDoc: Record "SI WB Supporting Document";
    begin
        EnsureSupportingDocsEditable();
        GetSupportingDocument(
            LineNo,
            SupportingDoc);

        SupportingDoc.Validate(
            "Document No.",
            CopyStr(
                NewValue,
                1,
                MaxStrLen(SupportingDoc."Document No.")));

        SupportingDoc.Modify(true);

        RefreshCompactDocs();
    end;

    local procedure UpdateSupportingDocumentDate(
        LineNo: Integer;
        YearValue: Integer;
        MonthValue: Integer;
        DayValue: Integer)
    var
        SupportingDoc: Record "SI WB Supporting Document";
    begin
        EnsureSupportingDocsEditable();
        GetSupportingDocument(
            LineNo,
            SupportingDoc);

        SupportingDoc."Document Date" :=
            DMY2Date(
                DayValue,
                MonthValue,
                YearValue);

        SupportingDoc.Modify(true);

        RefreshCompactDocs();
    end;

    local procedure UpdateSupportingDocumentNote(
        LineNo: Integer;
        NewValue: Text)
    var
        SupportingDoc: Record "SI WB Supporting Document";
    begin
        EnsureSupportingDocsEditable();
        GetSupportingDocument(
            LineNo,
            SupportingDoc);

        SupportingDoc.Note :=
            CopyStr(
                NewValue,
                1,
                MaxStrLen(SupportingDoc.Note));

        SupportingDoc.Modify(true);

        RefreshCompactDocs();
    end;

    local procedure GetSupportingDocument(
        LineNo: Integer;
        var SupportingDoc: Record "SI WB Supporting Document")
    begin
        Rec.TestField("Entry No.");

        if not SupportingDoc.Get(
            Rec."Entry No.",
            LineNo)
        then
            Error(
                'Супровідний документ, рядок %1, не знайдено.',
                LineNo);
    end;

    local procedure LoadConversionDisplay()
    var
        WeighbridgeLine: Record "SI Weighbridge Document Line";
    begin
        Clear(ConversionSource);
        Clear(ConversionFactor);
        Clear(ConversionResult);
        Clear(ConversionError);
        ConversionErrorVisible := false;

        if Rec."Entry No." = 0 then
            exit;

        WeighbridgeLine.Reset();
        WeighbridgeLine.SetRange(
            "Document Entry No.",
            Rec."Entry No.");

        if not WeighbridgeLine.FindFirst() then
            exit;

        ConversionSource :=
            GetConversionSourceDisplay(
                WeighbridgeLine."Conversion Source Type");

        if WeighbridgeLine."Conversion Factor" <> 0 then
            ConversionFactor :=
                CopyStr(
                    StrSubstNo(
                        '%1 %2',
                        Format(WeighbridgeLine."Conversion Factor"),
                        WeighbridgeLine."Conversion Factor UoM Code"),
                    1,
                    MaxStrLen(ConversionFactor));

        if WeighbridgeLine."Unit of Measure Code" <> '' then
            ConversionResult :=
                CopyStr(
                    StrSubstNo(
                        '%1 %2 → %3 %4',
                        Format(WeighbridgeLine."Allocated Weight"),
                        WeighbridgeLine."Weight UoM Code",
                        Format(WeighbridgeLine.Quantity),
                        WeighbridgeLine."Unit of Measure Code"),
                    1,
                    MaxStrLen(ConversionResult));

        ConversionError :=
            CopyStr(
                WeighbridgeLine."UoM Error Text",
                1,
                MaxStrLen(ConversionError));

        ConversionErrorVisible :=
            ConversionError <> '';
    end;

    local procedure OpenBasisDocumentCard()
    var
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
    begin
        Rec.TestField("Basis No.");

        case Rec."Basis Type" of
            "SI WB Basis Type"::"Purchase Order":
                begin
                    if not PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, Rec."Basis No.") then
                        Error('Purchase Order %1 не знайдено.', Rec."Basis No.");
                    Page.Run(Page::"Purchase Order", PurchaseHeader);
                end;

            "SI WB Basis Type"::"Sales Order":
                begin
                    if not SalesHeader.Get(SalesHeader."Document Type"::Order, Rec."Basis No.") then
                        Error('Sales Order %1 не знайдено.', Rec."Basis No.");
                    Page.Run(Page::"Sales Order", SalesHeader);
                end;

            "SI WB Basis Type"::Request:
                Error('Заявки для внутрішнього переміщення ще не підключені в поточному MVP.');

            else
                Error('Для документа %1 не визначено тип документа-підстави.', Rec."Document No.");
        end;
    end;

    local procedure OpenERPDocumentCard()
    var
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
    begin
        Rec.TestField("ERP Document No.");

        case Rec."ERP Document Type" of
            'Purchase Order':
                begin
                    if not PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, Rec."ERP Document No.") then
                        Error('Purchase Order %1 не знайдено.', Rec."ERP Document No.");
                    Page.Run(Page::"Purchase Order", PurchaseHeader);
                end;

            'Sales Order':
                begin
                    if not SalesHeader.Get(SalesHeader."Document Type"::Order, Rec."ERP Document No.") then
                        Error('Sales Order %1 не знайдено.', Rec."ERP Document No.");
                    Page.Run(Page::"Sales Order", SalesHeader);
                end;

            else
                Error(
                    'Тип ERP-документа %1 для навігації ще не підтримується.',
                    Rec."ERP Document Type");
        end;
    end;

    local procedure LookupBasisDocument()
    var
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
    begin
        if not ManagerEditable then
            Error('Документ-підставу можна вибирати тільки на стадії менеджера.');

        case Rec."Basis Type" of
            "SI WB Basis Type"::"Purchase Order":
                begin
                    Rec.TestField("Vendor No.");
                    PurchaseHeader.Reset();
                    PurchaseHeader.SetRange(
                        "Document Type",
                        PurchaseHeader."Document Type"::Order);
                    PurchaseHeader.SetRange(
                        "Buy-from Vendor No.",
                        Rec."Vendor No.");

                    if Page.RunModal(
                        Page::"Purchase Order List",
                        PurchaseHeader) = Action::LookupOK
                    then begin
                        Rec.Validate("Basis No.", PurchaseHeader."No.");
                        Rec.Modify(true);
                    end;
                end;

            "SI WB Basis Type"::"Sales Order":
                begin
                    Rec.TestField("Customer No.");
                    SalesHeader.Reset();
                    SalesHeader.SetRange(
                        "Document Type",
                        SalesHeader."Document Type"::Order);
                    SalesHeader.SetRange(
                        "Sell-to Customer No.",
                        Rec."Customer No.");

                    if Page.RunModal(
                        Page::"Sales Order List",
                        SalesHeader) = Action::LookupOK
                    then begin
                        Rec.Validate("Basis No.", SalesHeader."No.");
                        Rec.Modify(true);
                    end;
                end;

            "SI WB Basis Type"::Request:
                Error(
                    'Заявки для внутрішнього переміщення ще не підключені в поточному MVP.');

            else
                Error('Для документа не визначено тип підстави.');
        end;

        CurrPage.Update(false);
    end;

    local procedure EnsureSupportingDocsEditable()
    begin
        if Rec.Status = "SI WB Document Status"::New then
            exit;

        if (Rec.Status = "SI WB Document Status"::Submitted) and
           (Rec."Operation Type" = "SI WB Operation Type"::Receipt) and
           (Rec."Shipment Scenario" = "SI WB Shipment Scenario"::Supply)
        then
            exit;

        Error(
            'Супровідні документи можна редагувати оператору у статусі "Новий" або менеджеру для надходження/постачання у статусі "Передано менеджеру".');
    end;

    local procedure EnsureOperatorEditable()
    var
        DocumentMgt: Codeunit "SI WB Document Mgt.";
    begin
        DocumentMgt.EnsureOperatorEditable(Rec);
    end;

    local procedure GetConversionSourceDisplay(
        SourceType: Code[30]): Text[100]
    begin
        case SourceType of
            'DIRECT_SCALED':
                exit('Прямий / масштабований');

            'ITEM_ATTRIBUTE':
                exit('Атрибут товару');

            'PRODUCT_CONFIG':
                exit('Конфігурація товару');

            '':
                exit('');

            else
                exit(SourceType);
        end;
    end;

    var
        ReceiptVisible: Boolean;
        ShipmentVisible: Boolean;
        VendorVisible: Boolean;
        CustomerVisible: Boolean;
        ProjectVisible: Boolean;
        OperatorEditable: Boolean;
        ManagerEditable: Boolean;
        CanCreateDocuments: Boolean;
        CanHandoffToAccounting: Boolean;
        CanResolvePostingTemplate: Boolean;
        CanApplyPostingTemplate: Boolean;

        OperationTypeDisplay: Text[50];
        PartnerRecipientDisplay: Text[100];

        CompactLinesReady: Boolean;
        CompactDocsReady: Boolean;

        ConversionSource: Text[100];
        ConversionFactor: Text[100];
        ConversionResult: Text[150];
        ConversionError: Text[250];
        ConversionErrorVisible: Boolean;
}
