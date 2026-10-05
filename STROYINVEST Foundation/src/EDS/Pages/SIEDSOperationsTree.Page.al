page 50473 "SI EDS Operations Tree"
{
    PageType = Card;
    Caption = 'EDS: операції — дерево';
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            usercontrol(Tree; "SI EDS Tree Grid")
            {
                ApplicationArea = All;
                trigger ControlReady()
                begin
                    RenderTree();
                end;
                trigger NodeSelected(NodeType: Text; Key1: Text; Key2: Text; Key3: Text; Key4: Text)
                begin
                    SelectedNodeType := NodeType;
                    SelectedService := CopyStr(Key1, 1, MaxStrLen(SelectedService));
                    SelectedOperation := CopyStr(Key2, 1, MaxStrLen(SelectedOperation));
                end;
                trigger NodeOpenRequested(NodeType: Text; Key1: Text; Key2: Text; Key3: Text; Key4: Text)
                begin
                    SelectedNodeType := NodeType;
                    SelectedService := CopyStr(Key1, 1, MaxStrLen(SelectedService));
                    SelectedOperation := CopyStr(Key2, 1, MaxStrLen(SelectedOperation));
                    EditSelected();
                end;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(NewEntry) { ApplicationArea = All; Caption = 'Новий'; Image = New; trigger OnAction() begin Page.Run(Page::"SI EDS Operations"); end; }
            action(EditEntry) { ApplicationArea = All; Caption = 'Редагувати'; Image = EditLines; trigger OnAction() begin EditSelected(); end; }
            action(DeleteEntry) { ApplicationArea = All; Caption = 'Видалити'; Image = Delete; trigger OnAction() begin DeleteSelected(); end; }
            action(RefreshTree) { ApplicationArea = All; Caption = 'Оновити'; Image = Refresh; trigger OnAction() begin RenderTree(); end; }
            action(ListView) { ApplicationArea = All; Caption = 'Список'; Image = List; trigger OnAction() begin Page.Run(Page::"SI EDS Operations"); end; }
        }
    }

    var
        SelectedNodeType: Text;
        SelectedService: Code[50];
        SelectedOperation: Code[50];

    local procedure RenderTree()
    var
        Service: Record "SI EDS Service";
        Operation: Record "SI EDS Operation";
        Root: JsonObject;
        Columns: JsonArray;
        Nodes: JsonArray;
        ServiceNode: JsonObject;
        ServiceCells: JsonObject;
        Children: JsonArray;
        OperationNode: JsonObject;
        OperationCells: JsonObject;
        Payload: Text;
    begin
        AddColumn(Columns, 'service', 'Код сервісу', '220px');
        AddColumn(Columns, 'operation', 'Код операції', '220px');
        AddColumn(Columns, 'group', 'Група операцій', '170px');
        AddColumn(Columns, 'description', 'Опис', 'minmax(220px,1fr)');
        AddColumn(Columns, 'method', 'HTTP метод', '100px');
        AddColumn(Columns, 'path', 'Відносний шлях', 'minmax(260px,1fr)');
        AddColumn(Columns, 'enabled', 'Увімкнено', '100px');
        AddColumn(Columns, 'logBody', 'Зберігати тіло відповіді в журналі', '210px');

        if Service.FindSet() then
            repeat
                Operation.Reset();
                Operation.SetRange("Service Code", Service.Code);
                if Operation.FindSet() then begin
                    Clear(ServiceNode); Clear(ServiceCells); Clear(Children);
                    ServiceCells.Add('service', Service.Code);
                    ServiceNode.Add('nodeType', 'Service'); ServiceNode.Add('key1', Service.Code); ServiceNode.Add('cells', ServiceCells);
                    repeat
                        Clear(OperationNode); Clear(OperationCells);
                        OperationCells.Add('operation', Operation.Code);
                        OperationCells.Add('group', Operation."Operation Group Code");
                        OperationCells.Add('description', Operation.Description);
                        OperationCells.Add('method', Format(Operation."HTTP Method"));
                        OperationCells.Add('path', Operation."Relative Path");
                        OperationCells.Add('enabled', Operation.Enabled);
                        OperationCells.Add('logBody', Operation."Log Response Body");
                        OperationNode.Add('nodeType', 'Operation'); OperationNode.Add('key1', Operation."Service Code"); OperationNode.Add('key2', Operation.Code); OperationNode.Add('cells', OperationCells);
                        Children.Add(OperationNode);
                    until Operation.Next() = 0;
                    ServiceNode.Add('children', Children); Nodes.Add(ServiceNode);
                end;
            until Service.Next() = 0;
        Root.Add('columns', Columns); Root.Add('nodes', Nodes); Root.WriteTo(Payload);
        CurrPage.Tree.Render(Payload);
    end;

    local procedure EditSelected()
    var Service: Record "SI EDS Service"; Operation: Record "SI EDS Operation";
    begin
        case SelectedNodeType of
            'Service': if Service.Get(SelectedService) then Page.RunModal(Page::"SI EDS Services", Service);
            'Operation': if Operation.Get(SelectedService, SelectedOperation) then Page.RunModal(Page::"SI EDS Operations", Operation);
        end;
        RenderTree();
    end;

    local procedure DeleteSelected()
    var Operation: Record "SI EDS Operation";
    begin
        if SelectedNodeType <> 'Operation' then begin Message('Для видалення виберіть операцію.'); exit; end;
        if not Operation.Get(SelectedService, SelectedOperation) then exit;
        if Confirm('Видалити операцію %1 / %2?', false, SelectedService, SelectedOperation) then Operation.Delete(true);
        Clear(SelectedNodeType); RenderTree();
    end;

    local procedure AddColumn(var Columns: JsonArray; ColumnKey: Text; CaptionText: Text; Width: Text)
    var Column: JsonObject;
    begin Column.Add('key', ColumnKey); Column.Add('caption', CaptionText); Column.Add('width', Width); Columns.Add(Column); end;
}
