page 50474 "SI EDS Provider Routes Tree"
{
    PageType = Card;
    Caption = 'EDS: маршрути провайдерів — дерево';
    ApplicationArea = All;
    UsageCategory = Administration;

    layout { area(Content) { usercontrol(Tree; "SI EDS Tree Grid") { ApplicationArea = All;
        trigger ControlReady() begin RenderTree(); end;
        trigger NodeSelected(NodeType: Text; Key1: Text; Key2: Text; Key3: Text; Key4: Text) begin SetSelection(NodeType, Key1, Key2, Key3, Key4); end;
        trigger NodeOpenRequested(NodeType: Text; Key1: Text; Key2: Text; Key3: Text; Key4: Text) begin SetSelection(NodeType, Key1, Key2, Key3, Key4); EditSelected(); end;
    } } }

    actions { area(Processing) {
        action(NewEntry) { ApplicationArea = All; Caption = 'Новий'; Image = New; trigger OnAction() begin Page.Run(Page::"SI EDS Provider Routes"); end; }
        action(EditEntry) { ApplicationArea = All; Caption = 'Редагувати'; Image = EditLines; trigger OnAction() begin EditSelected(); end; }
        action(DeleteEntry) { ApplicationArea = All; Caption = 'Видалити'; Image = Delete; trigger OnAction() begin DeleteSelected(); end; }
        action(RefreshTree) { ApplicationArea = All; Caption = 'Оновити'; Image = Refresh; trigger OnAction() begin RenderTree(); end; }
        action(ListView) { ApplicationArea = All; Caption = 'Список'; Image = List; trigger OnAction() begin Page.Run(Page::"SI EDS Provider Routes"); end; }
    } }

    var SelectedNodeType: Text; SelectedService: Code[50]; SelectedOperation: Code[50]; SelectedProvider: Code[50]; SelectedPriority: Integer;

    local procedure SetSelection(NodeType: Text; Key1: Text; Key2: Text; Key3: Text; Key4: Text)
    begin SelectedNodeType := NodeType; SelectedService := CopyStr(Key1,1,MaxStrLen(SelectedService)); SelectedOperation := CopyStr(Key2,1,MaxStrLen(SelectedOperation)); SelectedProvider := CopyStr(Key3,1,MaxStrLen(SelectedProvider)); SelectedPriority := 0; if Key4 <> '' then Evaluate(SelectedPriority, Key4); end;

    local procedure RenderTree()
    var Service: Record "SI EDS Service"; Route: Record "SI EDS Provider Route"; Root: JsonObject; Columns, Nodes, Children: JsonArray; ServiceNode, RouteNode, Cells: JsonObject; Payload: Text;
    begin
        AddColumn(Columns,'service','Код сервісу','240px'); AddColumn(Columns,'operation','Код операції','260px'); AddColumn(Columns,'priority','Пріоритет','100px'); AddColumn(Columns,'provider','Код провайдера','220px'); AddColumn(Columns,'enabled','Увімкнено','100px');
        if Service.FindSet() then repeat
            Route.Reset(); Route.SetRange("Service Code", Service.Code);
            if Route.FindSet() then begin
                Clear(ServiceNode); Clear(Cells); Clear(Children); Cells.Add('service',Service.Code); ServiceNode.Add('nodeType','Service'); ServiceNode.Add('key1',Service.Code); ServiceNode.Add('cells',Cells);
                repeat
                    Clear(RouteNode); Clear(Cells); Cells.Add('operation',Route."Operation Code"); Cells.Add('priority',Route.Priority); Cells.Add('provider',Route."Provider Code"); Cells.Add('enabled',Route.Enabled);
                    RouteNode.Add('nodeType','Route'); RouteNode.Add('key1',Route."Service Code"); RouteNode.Add('key2',Route."Operation Code"); RouteNode.Add('key3',Route."Provider Code"); RouteNode.Add('key4',Format(Route.Priority)); RouteNode.Add('cells',Cells); Children.Add(RouteNode);
                until Route.Next()=0;
                ServiceNode.Add('children',Children); Nodes.Add(ServiceNode);
            end;
        until Service.Next()=0;
        Root.Add('columns',Columns); Root.Add('nodes',Nodes); Root.WriteTo(Payload); CurrPage.Tree.Render(Payload);
    end;

    local procedure EditSelected()
    var Service: Record "SI EDS Service"; Route: Record "SI EDS Provider Route";
    begin case SelectedNodeType of 'Service': if Service.Get(SelectedService) then Page.RunModal(Page::"SI EDS Services",Service); 'Route': if Route.Get(SelectedService,SelectedOperation,SelectedPriority,SelectedProvider) then Page.RunModal(Page::"SI EDS Provider Routes",Route); end; RenderTree(); end;

    local procedure DeleteSelected()
    var Route: Record "SI EDS Provider Route";
    begin if SelectedNodeType <> 'Route' then begin Message('Для видалення виберіть маршрут.'); exit; end; if not Route.Get(SelectedService,SelectedOperation,SelectedPriority,SelectedProvider) then exit; if Confirm('Видалити маршрут %1 / %2 → %3?',false,SelectedService,SelectedOperation,SelectedProvider) then Route.Delete(true); Clear(SelectedNodeType); RenderTree(); end;

    local procedure AddColumn(var Columns: JsonArray; ColumnKey: Text; CaptionText: Text; Width: Text)
    var Column: JsonObject;
    begin Column.Add('key',ColumnKey); Column.Add('caption',CaptionText); Column.Add('width',Width); Columns.Add(Column); end;
}
