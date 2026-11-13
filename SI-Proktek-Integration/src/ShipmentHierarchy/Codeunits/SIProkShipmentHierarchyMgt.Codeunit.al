codeunit 57195 "SI Prok Shipment Hier Mgt"
{
    procedure BuildTree(DateFrom: Date; DateTo: Date; RequestFilter: Text; StatusFilter: Option All,Open,Closed; MixerFilter: Text; DriverFilter: Text): Text
    var
        Shipment: Record "SI Prok Shipment";
        AllShipment: Record "SI Prok Shipment";
        ProdRequest: Record "SI Concrete Prod Request";
        Root: JsonObject;
        Groups: JsonArray;
        Children: JsonArray;
        GroupObj: JsonObject;
        ChildObj: JsonObject;
        SeenRequests: Dictionary of [Text, Boolean];
        GroupKey: Text;
        ReqEntry: Integer;
        OrderedQty: Decimal;
        ShippedQty: Decimal;
        OpenCount: Integer;
        ClosedCount: Integer;
        GroupName: Text;
        ProductName: Text;
        RequestStatus: Text;
        HasRequest: Boolean;
        BatchNo: Integer;
    begin
        if (DateFrom <> 0D) and (DateTo <> 0D) and (DateFrom > DateTo) then
            Error('Дата «від» не може бути пізнішою за дату «до».');

        Shipment.SetCurrentKey("Entry No.");
        if Shipment.FindSet() then
            repeat
                if MatchesFilters(Shipment, DateFrom, DateTo, RequestFilter, StatusFilter, MixerFilter, DriverFilter) then begin
                    ReqEntry := Shipment."Prod. Request Entry No.";
                    GroupKey := Format(ReqEntry);
                    if ReqEntry = 0 then
                        GroupKey := 'ORPHAN:' + Shipment."Source Order No." + ':' + Shipment."Item No." + ':' + Shipment."Variant Code";
                    if not SeenRequests.ContainsKey(GroupKey) then begin
                        SeenRequests.Add(GroupKey, true);
                        Clear(Children);
                        Clear(OrderedQty);
                        Clear(ShippedQty);
                        Clear(OpenCount);
                        Clear(ClosedCount);
                        Clear(BatchNo);
                        HasRequest := (ReqEntry <> 0) and ProdRequest.Get(ReqEntry);
                        if HasRequest then begin
                            GroupName := ProdRequest."Source No.";
                            if GroupName = '' then
                                GroupName := StrSubstNo('Заявка #%1', ReqEntry);
                            ProductName := ProdRequest.GetProductDescription();
                            OrderedQty := ProdRequest.Quantity;
                        end else begin
                            GroupName := Shipment."Source Order No.";
                            if GroupName = '' then
                                GroupName := StrSubstNo('Без заявки (#%1)', ReqEntry);
                            ProductName := Shipment."Item No.";
                            if Shipment."Variant Code" <> '' then
                                ProductName += ' / ' + Shipment."Variant Code";
                        end;

                        // Full totals: deliberately independent of UI filters.
                        AllShipment.SetRange("Prod. Request Entry No.", ReqEntry);
                        if ReqEntry = 0 then begin
                            AllShipment.SetRange("Source Order No.", Shipment."Source Order No.");
                            AllShipment.SetRange("Item No.", Shipment."Item No.");
                            AllShipment.SetRange("Variant Code", Shipment."Variant Code");
                        end;
                        if AllShipment.FindSet() then
                            repeat
                                BatchNo += 1;
                                ShippedQty += AllShipment."Quantity M3";
                                if AllShipment.Status = AllShipment.Status::Closed then
                                    ClosedCount += 1
                                else
                                    OpenCount += 1;
                                if MatchesFilters(AllShipment, DateFrom, DateTo, RequestFilter, StatusFilter, MixerFilter, DriverFilter) then begin
                                    Clear(ChildObj);
                                    ChildObj.Add('entryNo', AllShipment."Entry No.");
                                    ChildObj.Add('batchNo', BatchNo);
                                    ChildObj.Add('quantity', AllShipment."Quantity M3");
                                    ChildObj.Add('mixer', AllShipment."Truck Plate");
                                    ChildObj.Add('driver', AllShipment."Driver Name");
                                    ChildObj.Add('dateTime', Format(AllShipment."Shipment Date/Time", 0, '<Day,2>.<Month,2>.<Year4> <Hours24,2>:<Minutes,2>'));
                                    ChildObj.Add('status', Format(AllShipment.Status));
                                    Children.Add(ChildObj);
                                end;
                            until AllShipment.Next() = 0;
                        AllShipment.Reset();

                        if OpenCount > 0 then
                            RequestStatus := 'Відкриті'
                        else
                            if ClosedCount > 0 then
                                RequestStatus := 'Закриті'
                            else
                                RequestStatus := 'Без відвантажень';
                        Clear(GroupObj);
                        GroupObj.Add('groupKey', GroupKey);
                        GroupObj.Add('requestEntryNo', ReqEntry);
                        GroupObj.Add('request', GroupName);
                        GroupObj.Add('product', ProductName);
                        GroupObj.Add('ordered', OrderedQty);
                        GroupObj.Add('shipped', ShippedQty);
                        GroupObj.Add('remaining', OrderedQty - ShippedQty);
                        GroupObj.Add('status', RequestStatus);
                        GroupObj.Add('hasRequest', HasRequest);
                        GroupObj.Add('children', Children);
                        Groups.Add(GroupObj);
                    end;
                end;
            until Shipment.Next() = 0;
        Root.Add('groups', Groups);
        exit(Format(Root));
    end;

    local procedure MatchesFilters(Shipment: Record "SI Prok Shipment"; DateFrom: Date; DateTo: Date; RequestFilter: Text; StatusFilter: Option All,Open,Closed; MixerFilter: Text; DriverFilter: Text): Boolean
    var
        ShipDate: Date;
        Req: Record "SI Concrete Prod Request";
        SourceNo: Text;
    begin
        ShipDate := DT2Date(Shipment."Shipment Date/Time");
        if (DateFrom <> 0D) and (ShipDate < DateFrom) then
            exit(false);
        if (DateTo <> 0D) and (ShipDate > DateTo) then
            exit(false);
        if (StatusFilter = StatusFilter::Open) and (Shipment.Status <> Shipment.Status::Open) then
            exit(false);
        if (StatusFilter = StatusFilter::Closed) and (Shipment.Status <> Shipment.Status::Closed) then
            exit(false);
        if RequestFilter <> '' then begin
            SourceNo := Shipment."Source Order No.";
            if (Shipment."Prod. Request Entry No." <> 0) and Req.Get(Shipment."Prod. Request Entry No.") then
                SourceNo := Req."Source No.";
            if StrPos(UpperCase(SourceNo), UpperCase(RequestFilter)) = 0 then
                exit(false);
        end;
        if (MixerFilter <> '') and (StrPos(UpperCase(Shipment."Truck Plate"), UpperCase(MixerFilter)) = 0) then
            exit(false);
        if (DriverFilter <> '') and (StrPos(UpperCase(Shipment."Driver Name"), UpperCase(DriverFilter)) = 0) then
            exit(false);
        exit(true);
    end;
}
