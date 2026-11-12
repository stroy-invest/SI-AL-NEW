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
                field(BatchPlanView; BatchPlanView) { ApplicationArea = All; Caption = 'План, м³'; ToolTip = 'Не заповнюється, якщо джерело не передало план конкретної партії.'; }
                field(BatchActualView; BatchActualView) { ApplicationArea = All; Caption = 'Факт, м³'; DecimalPlaces = 0 : 5; }
                field(BatchVarianceView; BatchVarianceView) { ApplicationArea = All; Caption = 'Відхилення, м³'; ToolTip = 'Не обчислюється без плану конкретної партії.'; }
            }
            part(Materials; "SI Prok Prod Fact Materials")
            {
                ApplicationArea = All;
                Caption = 'Матеріали';
                SubPageLink = "Production Fact Entry No." = field("Entry No.");
            }
        }
    }
    actions
    {
        area(Processing)
        {
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
