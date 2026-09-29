page 61063 "SI VSC Tree View"
{
    PageType = Card;
    Caption = 'Канали постачання постачальників';
    ApplicationArea = All;
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            usercontrol(VSCTree; "SI VSC Tree View AddIn")
            {
                ApplicationArea = All;

                trigger ControlReady()
                begin
                    CurrPage.VSCTree.RenderTree(BuildTreeJson());
                end;

                trigger CapabilityOpenRequested(CapabilityCode: Text)
                var
                    Capability: Record "SI Vendor Supply Capability";
                    CapabilityCodeValue: Code[20];
                begin
                    CapabilityCodeValue := CopyStr(CapabilityCode, 1, MaxStrLen(CapabilityCodeValue));
                    if not Capability.Get(CapabilityCodeValue) then
                        exit;

                    Page.Run(Page::"SI Vendor Supply Cap. Card", Capability);
                    CurrPage.VSCTree.RenderTree(BuildTreeJson());
                end;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(TreeView)
            {
                ApplicationArea = All;
                Caption = 'Дерево';
                Image = Hierarchy;
                Enabled = false;
                ToolTip = 'Поточне ієрархічне подання каналів постачання.';
            }
            action(ListView)
            {
                ApplicationArea = All;
                Caption = 'Список';
                Image = List;
                ToolTip = 'Відкрити канали постачання у вигляді списку.';

                trigger OnAction()
                begin
                    Page.Run(Page::"SI Vendor Supply Capabilities");
                    CurrPage.Close();
                end;
            }
            action(ExpandAllNodes)
            {
                ApplicationArea = All;
                Caption = 'Розгорнути все';
                Image = ExpandAll;
                ToolTip = 'Розгорнути всі рівні дерева.';

                trigger OnAction()
                begin
                    CurrPage.VSCTree.ExpandAll();
                end;
            }
            action(CollapseAllNodes)
            {
                ApplicationArea = All;
                Caption = 'Згорнути все';
                Image = CollapseAll;
                ToolTip = 'Згорнути всі рівні дерева.';

                trigger OnAction()
                begin
                    CurrPage.VSCTree.CollapseAll();
                end;
            }
            action(RefreshTree)
            {
                ApplicationArea = All;
                Caption = 'Оновити';
                Image = Refresh;
                ToolTip = 'Оновити дерево каналів постачання.';

                trigger OnAction()
                begin
                    CurrPage.VSCTree.RenderTree(BuildTreeJson());
                end;
            }
        }
    }

    local procedure BuildTreeJson(): Text
    var
        Capability: Record "SI Vendor Supply Capability";
        Vendor: Record Vendor;
        ItemCategory: Record "Item Category";
        ShipmentMethod: Record "Shipment Method";
        RootArray: JsonArray;
        VendorArray: JsonArray;
        CategoryArray: JsonArray;
        VendorNode: JsonObject;
        CategoryNode: JsonObject;
        CapabilityNode: JsonObject;
        CurrentVendorNo: Code[20];
        CurrentCategoryCode: Code[20];
    begin
        Capability.Reset();
        Capability.SetCurrentKey("Vendor No.", "Item Category Code", Status);
        Capability.SetFilter("Vendor No.", '<>%1', '');
        Capability.SetFilter("Item Category Code", '<>%1', '');
        Capability.Ascending(true);

        if Capability.FindSet() then
            repeat
                if Capability."Vendor No." <> CurrentVendorNo then begin
                    FlushCategoryNode(CategoryArray, VendorArray, CategoryNode, CurrentCategoryCode);
                    FlushVendorNode(VendorArray, RootArray, VendorNode, CurrentVendorNo);

                    Clear(VendorArray);
                    Clear(CategoryArray);
                    CurrentVendorNo := Capability."Vendor No.";
                    Clear(CurrentCategoryCode);
                    VendorNode := CreateGroupNode('vendor:' + CurrentVendorNo, 'vendor', GetVendorName(Vendor, CurrentVendorNo));
                end;

                if Capability."Item Category Code" <> CurrentCategoryCode then begin
                    FlushCategoryNode(CategoryArray, VendorArray, CategoryNode, CurrentCategoryCode);

                    Clear(CategoryArray);
                    CurrentCategoryCode := Capability."Item Category Code";
                    CategoryNode := CreateGroupNode(
                        'category:' + CurrentVendorNo + ':' + CurrentCategoryCode,
                        'category', GetCategoryName(ItemCategory, CurrentCategoryCode));
                end;

                CapabilityNode := CreateCapabilityNode(Capability, ShipmentMethod);
                CategoryArray.Add(CapabilityNode);
            until Capability.Next() = 0;

        FlushCategoryNode(CategoryArray, VendorArray, CategoryNode, CurrentCategoryCode);
        FlushVendorNode(VendorArray, RootArray, VendorNode, CurrentVendorNo);

        exit(Format(RootArray));
    end;

    local procedure CreateGroupNode(NodeKey: Text; NodeType: Text; NodeLabel: Text): JsonObject
    var
        Node: JsonObject;
    begin
        Node.Add('key', NodeKey);
        Node.Add('type', NodeType);
        Node.Add('label', NodeLabel);
        exit(Node);
    end;

    local procedure CreateCapabilityNode(Capability: Record "SI Vendor Supply Capability"; var ShipmentMethod: Record "Shipment Method"): JsonObject
    var
        Node: JsonObject;
    begin
        Node.Add('key', 'capability:' + Capability.Code);
        Node.Add('type', 'capability');
        Node.Add('label', GetShipmentMethodName(ShipmentMethod, Capability."Shipment Method Code"));
        Node.Add('code', Capability.Code);
        Node.Add('uom', Capability."UoM Code");
        Node.Add('minimumQty', FormatDecimal(Capability."Minimum Order Quantity"));
        Node.Add('orderMultiple', FormatDecimal(Capability."Order Multiple"));
        Node.Add('leadTime', Format(Capability."Lead Time Calculation"));
        exit(Node);
    end;

    local procedure FlushCategoryNode(var CategoryArray: JsonArray; var VendorArray: JsonArray; var CategoryNode: JsonObject; CategoryCode: Code[20])
    begin
        if CategoryCode = '' then
            exit;

        CategoryNode.Add('children', CategoryArray);
        VendorArray.Add(CategoryNode);
        Clear(CategoryNode);
        Clear(CategoryArray);
    end;

    local procedure FlushVendorNode(var VendorArray: JsonArray; var RootArray: JsonArray; var VendorNode: JsonObject; VendorNo: Code[20])
    begin
        if VendorNo = '' then
            exit;

        VendorNode.Add('children', VendorArray);
        RootArray.Add(VendorNode);
        Clear(VendorNode);
        Clear(VendorArray);
    end;

    local procedure GetVendorName(var Vendor: Record Vendor; VendorNo: Code[20]): Text
    begin
        if Vendor.Get(VendorNo) then
            if Vendor.Name <> '' then
                exit(Vendor.Name);
        exit(VendorNo);
    end;

    local procedure GetCategoryName(var ItemCategory: Record "Item Category"; CategoryCode: Code[20]): Text
    begin
        if ItemCategory.Get(CategoryCode) then
            if ItemCategory.Description <> '' then
                exit(ItemCategory.Description);
        exit(CategoryCode);
    end;

    local procedure GetShipmentMethodName(var ShipmentMethod: Record "Shipment Method"; ShipmentMethodCode: Code[10]): Text
    begin
        if ShipmentMethod.Get(ShipmentMethodCode) then
            if ShipmentMethod.Description <> '' then
                exit(ShipmentMethod.Description);
        exit(ShipmentMethodCode);
    end;

    local procedure FormatDecimal(Value: Decimal): Text
    begin
        if Value = 0 then
            exit('0');
        exit(Format(Value, 0, '<Precision,0:5><Standard Format,0>'));
    end;
}
