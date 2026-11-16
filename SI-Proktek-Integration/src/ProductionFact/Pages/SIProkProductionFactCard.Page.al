page 57093 "SI Prok Production Fact Card"
{
    PageType = Card;
    SourceTable = "SI Prok Production Fact";
    Caption = 'Факт виробництва бетону';
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(Content)
        {
            group(OrderInformation)
            {
                Caption = 'Загальна інформація по замовленню';
                field(RequestNoView; RequestNoView) { ApplicationArea = All; Caption = 'Заявка №'; }
                field(RequestTypeView; RequestTypeView) { ApplicationArea = All; Caption = 'Тип заявки'; }
                field(ProjectView; ProjectView) { ApplicationArea = All; Caption = 'Проєкт'; }
                field(ConcreteView; ConcreteView) { ApplicationArea = All; Caption = 'Бетон'; }
                field(RecipeView; RecipeView) { ApplicationArea = All; Caption = 'Рецептура'; }
                field(RequiredAtView; RequiredAtView) { ApplicationArea = All; Caption = 'Дата/час потреби'; }
                field(UnloadingView; UnloadingView) { ApplicationArea = All; Caption = 'Точка розвантаження'; ToolTip = 'Показується, коли точка розвантаження доступна в даних заявки.'; }
                field(RequestedByView; RequestedByView) { ApplicationArea = All; Caption = 'Замовив'; }
                field(OrderQuantityView; OrderQuantityView) { ApplicationArea = All; Caption = 'Замовлена кількість всього, м³'; DecimalPlaces = 0 : 5; }
                field(TotalProducedView; TotalProducedView) { ApplicationArea = All; Caption = 'Вироблена кількість всього, м³'; DecimalPlaces = 0 : 5; ToolTip = 'Поточна сума унікальних фактів за заявкою. Оновлюється при відкритті або оновленні картки.'; }
            }
            group(BatchInformation)
            {
                Caption = 'Інформація про партію';
                field(MixerView; MixerView) { ApplicationArea = All; Caption = 'Автоміксер'; }
                field("Truck Plate"; Rec."Truck Plate") { ApplicationArea = All; Caption = 'Номер автоміксера'; }
                field(DriverView; DriverView) { ApplicationArea = All; Caption = 'Водій'; }
                field("Production Date/Time"; Rec."Production Date/Time") { ApplicationArea = All; Caption = 'Дата/час виробництва'; }
            }
            group(BatchOutput)
            {
                Caption = 'Випуск бетону в партії, м³';
                field(BatchPlanView; BatchPlanView) { ApplicationArea = All; Caption = 'План, м³'; ToolTip = 'План конкретної партії; порожньо, якщо план не підтверджено.'; }
                field(BatchActualView; BatchActualView) { ApplicationArea = All; Caption = 'Факт, м³'; DecimalPlaces = 0 : 5; }
                field(BatchVarianceView; BatchVarianceView) { ApplicationArea = All; Caption = 'Відхилення, м³'; ToolTip = 'Факт мінус план; порожньо, якщо план партії відсутній.'; }
            }
            part(Materials; "SI Prok Prod Fact Materials")
            {
                ApplicationArea = All;
                Caption = 'Матеріали';
                SubPageLink = "Production Fact Entry No." = field("Entry No.");
            }
            group(AccountingControl)
            {
                Caption = 'Контроль виробничого обліку';
                field("Production UUID"; Rec."Production UUID") { ApplicationArea = All; }
                field("BC Prod. Order No."; Rec."BC Prod. Order No.") { ApplicationArea = All; }
                field("BC Prod. Order Line No."; Rec."BC Prod. Order Line No.") { ApplicationArea = All; }
                field("Verification Status"; Rec."Verification Status") { ApplicationArea = All; }
                field("Technical Validation"; Rec."Technical Validation") { ApplicationArea = All; }
                field("BC Binding Status"; Rec."BC Binding Status") { ApplicationArea = All; }
                field("Accounting Readiness"; Rec."Accounting Readiness") { ApplicationArea = All; }
                field("Accounting Posting Model"; Rec."Accounting Posting Model") { ApplicationArea = All; }
                field("Accounting Output Qty"; Rec."Accounting Output Qty") { ApplicationArea = All; }
                field("Accounting Document No."; Rec."Accounting Document No.") { ApplicationArea = All; }
                field("Accounting Material Lines"; Rec."Accounting Material Lines") { ApplicationArea = All; }
                field("Accounting Diagnostics"; Rec."Accounting Diagnostics") { ApplicationArea = All; MultiLine = true; }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            group(ProductionAccounting)
            {
                Caption = 'Виробничий облік';
                action(CheckAccounting)
                {
                    ApplicationArea = All;
                    Caption = 'Перевірити готовність';
                    Image = Check;
                    trigger OnAction()
                    var
                        Prep: Codeunit "SI Prok Accounting Prep Mgt.";
                    begin
                        Prep.CheckFact(Rec);
                        CurrPage.Update(false);
                        Message('Accounting Readiness: %1. %2', Rec."Accounting Readiness", Rec."Accounting Diagnostics");
                    end;
                }
                action(PrepareAccountingJournals)
                {
                    ApplicationArea = All;
                    Caption = 'Підготувати журнали (без проведення)';
                    Image = Create;
                    trigger OnAction()
                    var
                        Prepare: Codeunit "SI Prok Journal Preparation";
                    begin
                        Prepare.Prepare(Rec);
                        CurrPage.Update(false);
                    end;
                }
                action(PrepareProcessAdjustments)
                {
                    ApplicationArea = All;
                    Caption = 'SI Process: підготувати товарний журнал (Sandbox)';
                    Image = Create;
                    ToolTip = 'Формує тільки НЕПРОВЕДЕНІ Negative/Positive Adjustment за фактом Proktek. Не змінює MES-факт, Production Order та не виконує проведення.';
                    trigger OnAction()
                    var
                        ProcessPrep: Codeunit "SI Prok Process Journal Prep";
                    begin
                        ProcessPrep.PrepareSandbox(Rec);
                        CurrPage.Update(false);
                    end;
                }
                group(SIProcessStage2)
                {
                    Caption = 'SI Process Production — Stage 2';
                    action(CheckProcessJournal)
                    {
                        ApplicationArea = All;
                        Caption = 'SI Process: перевірити журнал (без змін)';
                        Image = Check;
                        ToolTip = 'Перевіряє сім або більше непроведених рядків, Journal Links, складські та облікові групи. Не змінює дані та не проводить.';
                        trigger OnAction()
                        var
                            Control: Codeunit "SI Prok Process Control";
                        begin
                            Control.CheckReady(Rec);
                        end;
                    }
                    action(ReviewProcessPosting)
                    {
                        ApplicationArea = All;
                        Caption = 'SI Process: аудит проведення (без змін)';
                        Image = ViewDetails;
                        ToolTip = 'Перевіряє Item Ledger Entries за документом і знімками Journal Links. 0 — немає, 1 — повністю, 2 — частково. Нічого не змінює.';
                        trigger OnAction()
                        var
                            Control: Codeunit "SI Prok Process Control";
                        begin
                            Control.Review(Rec);
                        end;
                    }
                    action(PostProcessControlled)
                    {
                        ApplicationArea = All;
                        Caption = 'SI Process: провести товарний журнал (Sandbox)';
                        Image = Post;
                        ToolTip = 'РЕАЛЬНЕ проведення Negative/Positive Adjustment стандартним BC. Створює durable Started-спробу до проведення; автоматичний повтор заборонений.';
                        trigger OnAction()
                        var
                            Posting: Codeunit "SI Prok Process Posting";
                        begin
                            Posting.PostSandbox(Rec);
                            CurrPage.Update(false);
                        end;
                    }
                    action(RecoverProcessControlled)
                    {
                        ApplicationArea = All;
                        Caption = 'SI Process: відновити Started (Sandbox)';
                        Image = Refresh;
                        ToolTip = 'Тільки після 10 хв: якщо 0 проведено і журнал цілий — дозволяє контрольований повтор; якщо 1 — завершує спробу без повтору; часткове проведення блокує.';
                        trigger OnAction()
                        var
                            Posting: Codeunit "SI Prok Process Posting";
                        begin
                            Posting.RecoverSandbox(Rec);
                            CurrPage.Update(false);
                        end;
                    }
                }
                action(RenumberPreparedAccountingJournals)
                {
                    ApplicationArea = All;
                    Caption = 'Призначити номер підготовленим журналам (Sandbox)';
                    Image = Refresh;
                    ToolTip = 'Одноразово призначає номер із налаштованої No. Series існуючим непроведеним рядкам та їхнім Journal Links. Не створює і не проводить журнали.';
                    trigger OnAction()
                    var
                        Prepare: Codeunit "SI Prok Journal Preparation";
                    begin
                        Prepare.RenumberPreparedSandbox(Rec);
                        CurrPage.Update(false);
                    end;
                }
                action(ResetAccountingOrderSandbox)
                {
                    ApplicationArea = All;
                    Caption = 'Очистити облікову підготовку замовлення (Sandbox)';
                    Image = Delete;
                    ToolTip = 'Очищає ТІЛЬКИ непроведені Item Journal Lines, SI Prok Journal Link, Started Posting Attempt та номер облікового документа всіх фактів цього BC Production Order. Факти, матеріали, JSON, замовлення та компоненти не змінює.';
                    trigger OnAction()
                    var
                        ResetMgt: Codeunit "SI Prok Accounting Reset";
                    begin
                        ResetMgt.ResetOrderSandbox(Rec);
                        CurrPage.Update(false);
                    end;
                }
                action(RedatePreparedAccountingJournals)
                {
                    ApplicationArea = All;
                    Caption = 'Змінити дату підготовлених журналів (Sandbox)';
                    Image = Refresh;
                    ToolTip = 'Застосовує політику Posting Date до непроведених журналів факту. Дозволено для Started лише за відсутності проведених Consumption та Output. Не змінює дату виробництва і не проводить журнали.';
                    trigger OnAction()
                    var
                        Prepare: Codeunit "SI Prok Journal Preparation";
                    begin
                        Prepare.RedatePreparedSandbox(Rec);
                        CurrPage.Update(false);
                    end;
                }
                action(ReconcileAccountingJournals)
                {
                    ApplicationArea = All;
                    Caption = 'Звірити журнали';
                    Image = Calculate;
                    trigger OnAction()
                    var
                        Recon: Codeunit "SI Prok Journal Reconciliation";
                    begin
                        Recon.ReconcileFact(Rec);
                        CurrPage.Update(false);
                    end;
                }
                action(ReviewAccountingPosting)
                {
                    ApplicationArea = All;
                    Caption = 'Перевірити проведені записи';
                    Image = ViewDetails;
                    trigger OnAction()
                    var
                        Audit: Codeunit "SI Prok Posting Audit";
                    begin
                        Audit.Review(Rec);
                    end;
                }
                action(DiagnosePostingGroups)
                {
                    ApplicationArea = All;
                    Caption = 'Діагностика облікових груп журналів (без змін)';
                    Image = ViewDetails;
                    ToolTip = 'Показує фактичну Inventory Posting Group кожного рядка Item Journal, групу картки Item та наявність Inventory Posting Setup. Нічого не змінює і не проводить.';
                    trigger OnAction()
                    var
                        Audit: Codeunit "SI Prok Posting Audit";
                    begin
                        Audit.DiagnosePostingGroups(Rec);
                    end;
                }
                action(PostFactControlled)
                {
                    ApplicationArea = All;
                    Caption = 'Провести Output / Consumption (Sandbox)';
                    Image = Post;
                    trigger OnAction()
                    var
                        Posting: Codeunit "SI Prok Controlled Posting";
                    begin
                        Posting.PostSandbox(Rec);
                        CurrPage.Update(false);
                    end;
                }
                action(RecoverOutputControlled)
                {
                    ApplicationArea = All;
                    Caption = 'Відновити лише Output (Sandbox)';
                    Image = Refresh;
                    trigger OnAction()
                    var
                        Posting: Codeunit "SI Prok Controlled Posting";
                    begin
                        Posting.RecoverOutputSandbox(Rec);
                        CurrPage.Update(false);
                    end;
                }
                action(RecoverUnpostedControlled)
                {
                    ApplicationArea = All;
                    Caption = 'Відновити непроведену спробу (Sandbox)';
                    Image = Refresh;
                    trigger OnAction()
                    var
                        Posting: Codeunit "SI Prok Controlled Posting";
                    begin
                        Posting.RecoverUnpostedSandbox(Rec);
                        CurrPage.Update(false);
                    end;
                }
                action(OpenAccountingSetup)
                {
                    ApplicationArea = All;
                    Caption = 'Налаштування виробничих журналів Proktek';
                    Image = Setup;
                    RunObject = page "SI Prok Journal Setup";
                }
            }
            action(OpenShipment)
            {
                Caption = 'Документ відвантаження';
                ApplicationArea = All;
                Image = Shipment;
                trigger OnAction()
                var
                    Shipment: Record "SI Prok Shipment";
                begin
                    Shipment.SetRange("Production UUID", Rec."Production UUID");
                    if not Shipment.FindFirst() then
                        Error('Для цього факту документ відвантаження ще не створено.');
                    Page.Run(Page::"SI Prok Shipment Card", Shipment);
                end;
            }
            action(ViewProkJournalLinks)
            {
                ApplicationArea = All;
                Caption = 'Перейти до журналів';
                Image = List;
                trigger OnAction()
                var
                    Link: Record "SI Prok Journal Link";
                begin
                    Link.SetRange("Fact Entry No.", Rec."Entry No.");
                    Page.Run(Page::"SI Prok Journal Links", Link);
                end;
            }
            action(OpenBCProductionOrder)
            {
                ApplicationArea = All;
                Caption = 'Відкрити виробниче замовлення';
                Image = View;
                trigger OnAction()
                var
                    ProdOrder: Record "Production Order";
                begin
                    Rec.TestField("BC Prod. Order No.");
                    if not ProdOrder.Get(Rec."BC Prod. Order Status", Rec."BC Prod. Order No.") then
                        Error('Виробниче замовлення %1 не знайдено.', Rec."BC Prod. Order No.");
                    case ProdOrder.Status of
                        ProdOrder.Status::"Firm Planned": Page.Run(Page::"Firm Planned Prod. Order", ProdOrder);
                        ProdOrder.Status::Released: Page.Run(Page::"Released Production Order", ProdOrder);
                        else Error('Цей статус виробничого замовлення не підтримується.');
                    end;
                end;
            }
        }
    }
    trigger OnAfterGetRecord()
    begin
        LoadBusinessContext();
    end;

    local procedure LoadBusinessContext()
    var
        Request: Record "SI Concrete Prod Request";
        Fact: Record "SI Prok Production Fact";
        Shipment: Record "SI Prok Shipment";
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        Job: Record Job;
    begin
        Clear(RequestNoView);
        Clear(RequestTypeView);
        Clear(ProjectView);
        Clear(ConcreteView);
        Clear(RecipeView);
        Clear(RequiredAtView);
        Clear(UnloadingView);
        Clear(RequestedByView);
        Clear(OrderQuantityView);
        Clear(TotalProducedView);
        Clear(MixerView);
        Clear(DriverView);
        Clear(BatchPlanView);
        Clear(BatchVarianceView);
        BatchActualView := Rec."Produced Quantity M3";
        if Rec."Planned Quantity M3" > 0 then begin
            BatchPlanView := Format(Rec."Planned Quantity M3");
            BatchVarianceView := Format(Rec."Produced Quantity M3" - Rec."Planned Quantity M3");
        end;

        if Item.Get(Rec."Item No.") then
            ConcreteView := Item.Description;
        if (Rec."Variant Code" <> '') and ItemVariant.Get(Rec."Item No.", Rec."Variant Code") then
            if ItemVariant.Description <> '' then
                ConcreteView := ItemVariant.Description;

        RecipeView := Rec."Formula Name";
        if Request.Get(Rec."Prod. Request Entry No.") then begin
            RequestNoView := Request."Source No.";
            RequestTypeView := Format(Request."Request Type");
            RequiredAtView := Request."Required Date/Time";
            RequestedByView := Request."Created By";
            OrderQuantityView := Request.Quantity;
            if Job.Get(Request."Project No.") then
                ProjectView := Job.Description
            else
                ProjectView := Request."Project No.";
            if Request."Formula Description" <> '' then
                RecipeView := Request."Formula Description";

            // Only actual, uniquely stored production facts linked to this request.
            Fact.SetRange("Prod. Request Entry No.", Request."Entry No.");
            if Fact.FindSet() then
                repeat
                    if (Fact."Produced Quantity M3" > 0) and not IsNullGuid(Fact."Production UUID") then
                        TotalProducedView += Fact."Produced Quantity M3";
                until Fact.Next() = 0;
        end else begin
            RequestNoView := Rec."Order No.";
            ProjectView := Rec."Project No.";
            OrderQuantityView := Rec."Ordered Quantity M3";
        end;

        MixerView := Rec."Truck Code";
        Shipment.SetRange("Production UUID", Rec."Production UUID");
        if Shipment.FindFirst() then begin
            DriverView := Shipment."Driver Name";
            if Shipment."Recipe Name" <> '' then
                RecipeView := Shipment."Recipe Name";
        end;
        // Batch planned quantity and unloading point require a verified source mapping.
        // Deliberately blank instead of showing order totals as batch plans.
    end;

    local procedure IsNullGuid(Value: Guid): Boolean
    begin
        exit(Value = '00000000-0000-0000-0000-000000000000');
    end;

    var
        RequestNoView: Code[30];
        RequestTypeView: Text[100];
        ProjectView: Text[150];
        ConcreteView: Text[150];
        RecipeView: Text[150];
        RequiredAtView: DateTime;
        UnloadingView: Text[150];
        RequestedByView: Text[100];
        OrderQuantityView: Decimal;
        TotalProducedView: Decimal;
        MixerView: Text[100];
        DriverView: Text[100];
        BatchPlanView: Text[30];
        BatchActualView: Decimal;
        BatchVarianceView: Text[30];
}
