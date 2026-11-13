page 57195 "SI Prok Shipment Hierarchy"
{
    PageType = Card;
    Caption = 'Відвантаження бетону за заявками';
    ApplicationArea = All;
    UsageCategory = Lists;
    Editable = true;

    layout
    {
        area(Content)
        {
            group(Filters)
            {
                Caption = 'Фільтри відвантажень';
                field(DateFrom; DateFrom) { ApplicationArea = All; Caption = 'Дата від'; }
                field(DateTo; DateTo) { ApplicationArea = All; Caption = 'Дата до'; }
                field(RequestFilter; RequestFilter) { ApplicationArea = All; Caption = 'Заявка (містить)'; }
                field(StatusFilter; StatusFilter) { ApplicationArea = All; Caption = 'Статус'; OptionCaption = 'Всі,Відкриті,Закриті'; }
                field(MixerFilter; MixerFilter) { ApplicationArea = All; Caption = 'Міксер (містить)'; }
                field(DriverFilter; DriverFilter) { ApplicationArea = All; Caption = 'Водій (містить)'; }
            }
            usercontrol(ShipmentTree; "SI Prok Shipment Tree")
            {
                ApplicationArea = All;
                trigger Ready()
                begin
                    TreeReady := true;
                    RefreshTree();
                end;

                trigger RowOpened(RowType: Text; EntryNo: Integer)
                var
                    ProdRequest: Record "SI Concrete Prod Request";
                    Shipment: Record "SI Prok Shipment";
                begin
                    case RowType of
                        'request':
                            if (EntryNo <> 0) and ProdRequest.Get(EntryNo) then
                                Page.Run(Page::"SI Concrete Prod Req Card", ProdRequest);
                        'shipment':
                            if Shipment.Get(EntryNo) then
                                Page.Run(Page::"SI Prok Shipment Card", Shipment);
                    end;
                end;
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(ApplyFilters)
            {
                Caption = 'Застосувати фільтри';
                ApplicationArea = All;
                Image = Filter;
                trigger OnAction()
                begin
                    RefreshTree();
                end;
            }
            action(ClearFilters)
            {
                Caption = 'Очистити фільтри';
                ApplicationArea = All;
                Image = ClearFilter;
                trigger OnAction()
                begin
                    Clear(DateFrom);
                    Clear(DateTo);
                    Clear(RequestFilter);
                    StatusFilter := StatusFilter::All;
                    Clear(MixerFilter);
                    Clear(DriverFilter);
                    RefreshTree();
                end;
            }
            action(OpenStandardList)
            {
                Caption = 'Стандартний список відвантажень';
                ApplicationArea = All;
                Image = List;
                trigger OnAction()
                begin
                    Page.Run(Page::"SI Prok Shipments");
                end;
            }
        }
        area(Promoted)
        {
            actionref(ApplyFiltersPromoted; ApplyFilters) { }
            actionref(ClearFiltersPromoted; ClearFilters) { }
        }
    }
    local procedure RefreshTree()
    var
        Builder: Codeunit "SI Prok Shipment Hier Mgt";
    begin
        if TreeReady then
            CurrPage.ShipmentTree.RenderTree(Builder.BuildTree(DateFrom, DateTo, RequestFilter, StatusFilter, MixerFilter, DriverFilter));
    end;

    var
        TreeReady: Boolean;
        DateFrom: Date;
        DateTo: Date;
        RequestFilter: Text[100];
        StatusFilter: Option All,Open,Closed;
        MixerFilter: Text[100];
        DriverFilter: Text[100];
}
