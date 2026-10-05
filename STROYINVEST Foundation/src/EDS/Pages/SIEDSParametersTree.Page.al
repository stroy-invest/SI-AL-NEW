page 50475 "SI EDS Parameters Tree"
{
    PageType = Card;
    Caption = 'EDS: параметри — дерево';
    ApplicationArea = All;
    UsageCategory = Administration;

    layout { area(Content) { usercontrol(Tree; "SI EDS Tree Grid") { ApplicationArea = All;
        trigger ControlReady() begin RenderTree(); end;
        trigger NodeSelected(NodeType: Text; Key1: Text; Key2: Text; Key3: Text; Key4: Text) begin SetSelection(NodeType,Key1,Key2,Key3,Key4); end;
        trigger NodeOpenRequested(NodeType: Text; Key1: Text; Key2: Text; Key3: Text; Key4: Text) begin SetSelection(NodeType,Key1,Key2,Key3,Key4); EditSelected(); end;
    } } }

    actions { area(Processing) {
        action(NewEntry) { ApplicationArea = All; Caption = 'Новий'; Image = New; trigger OnAction() begin Page.Run(Page::"SI EDS Parameters"); end; }
        action(EditEntry) { ApplicationArea = All; Caption = 'Редагувати'; Image = EditLines; trigger OnAction() begin EditSelected(); end; }
        action(DeleteEntry) { ApplicationArea = All; Caption = 'Видалити'; Image = Delete; trigger OnAction() begin DeleteSelected(); end; }
        action(RefreshTree) { ApplicationArea = All; Caption = 'Оновити'; Image = Refresh; trigger OnAction() begin RenderTree(); end; }
        action(ListView) { ApplicationArea = All; Caption = 'Список'; Image = List; trigger OnAction() begin Page.Run(Page::"SI EDS Parameters"); end; }
    } }

    var SelectedNodeType: Text; SelectedService: Code[50]; SelectedOperation: Code[50]; SelectedProvider: Code[50]; SelectedParameter: Code[50];
    local procedure SetSelection(NodeType: Text; Key1: Text; Key2: Text; Key3: Text; Key4: Text)
    begin SelectedNodeType:=NodeType; SelectedService:=CopyStr(Key1,1,MaxStrLen(SelectedService)); SelectedOperation:=CopyStr(Key2,1,MaxStrLen(SelectedOperation)); SelectedProvider:=CopyStr(Key3,1,MaxStrLen(SelectedProvider)); SelectedParameter:=CopyStr(Key4,1,MaxStrLen(SelectedParameter)); end;

    local procedure RenderTree()
    var Service: Record "SI EDS Service"; Operation: Record "SI EDS Operation"; Param, ProviderParam: Record "SI EDS Parameter"; Root: JsonObject; Columns, Nodes, OpChildren, ProviderChildren, ParamChildren: JsonArray; ServiceNode, OpNode, ProviderNode, ParamNode, Cells: JsonObject; ProviderCode: Code[50]; ProviderCodes: List of [Code[50]]; Payload: Text;
    begin
        AddColumn(Columns,'service','Код сервісу','220px'); AddColumn(Columns,'operation','Код операції','220px'); AddColumn(Columns,'provider','Код провайдера','200px'); AddColumn(Columns,'sequence','Послідовність','105px'); AddColumn(Columns,'code','Код метаданих','170px'); AddColumn(Columns,'external','Зовнішнє ім''я','170px'); AddColumn(Columns,'location','Розташування','130px'); AddColumn(Columns,'runtime','Runtime key','150px'); AddColumn(Columns,'value','Фіксоване значення','180px'); AddColumn(Columns,'source','Джерело значення','150px'); AddColumn(Columns,'format','Формат','130px'); AddColumn(Columns,'credential','Код облікових даних','190px'); AddColumn(Columns,'prefix','Префікс значення','150px'); AddColumn(Columns,'required','Обов''язковий','110px'); AddColumn(Columns,'enabled','Увімкнено','100px');
        if Service.FindSet() then repeat
            Param.Reset(); Param.SetRange("Service Code",Service.Code);
            if not Param.IsEmpty() then begin
                Clear(ServiceNode); Clear(Cells); Clear(OpChildren); Cells.Add('service',Service.Code); ServiceNode.Add('nodeType','Service'); ServiceNode.Add('key1',Service.Code); ServiceNode.Add('cells',Cells);
                Operation.Reset(); Operation.SetRange("Service Code",Service.Code);
                if Operation.FindSet() then repeat
                    Param.Reset(); Param.SetRange("Service Code",Service.Code); Param.SetRange("Operation Code",Operation.Code);
                    if not Param.IsEmpty() then begin
                        Clear(OpNode); Clear(Cells); Clear(ProviderChildren); Cells.Add('operation',Operation.Code); OpNode.Add('nodeType','Operation'); OpNode.Add('key1',Service.Code); OpNode.Add('key2',Operation.Code); OpNode.Add('cells',Cells);
                        Clear(ProviderCodes);
                        if Param.FindSet() then
                            repeat
                                if not ProviderCodes.Contains(Param."Provider Code") then
                                    ProviderCodes.Add(Param."Provider Code");
                            until Param.Next() = 0;
                        foreach ProviderCode in ProviderCodes do begin
                            Clear(ProviderNode); Clear(Cells); Clear(ParamChildren); Cells.Add('provider',ProviderCode); ProviderNode.Add('nodeType','Provider'); ProviderNode.Add('key1',Service.Code); ProviderNode.Add('key2',Operation.Code); ProviderNode.Add('key3',ProviderCode); ProviderNode.Add('cells',Cells);
                            ProviderParam.Reset(); ProviderParam.SetRange("Service Code",Service.Code); ProviderParam.SetRange("Operation Code",Operation.Code); ProviderParam.SetRange("Provider Code",ProviderCode); ProviderParam.SetCurrentKey("Service Code","Operation Code","Provider Code",Enabled,Sequence);
                            if ProviderParam.FindSet() then repeat
                                Clear(ParamNode); Clear(Cells); Cells.Add('sequence',ProviderParam.Sequence); Cells.Add('code',ProviderParam.Code); Cells.Add('external',ProviderParam."External Name"); Cells.Add('location',Format(ProviderParam.Location)); Cells.Add('runtime',ProviderParam."Runtime Key"); Cells.Add('value',ProviderParam.Value); Cells.Add('source',Format(ProviderParam.Source)); Cells.Add('format',Format(ProviderParam.Format)); Cells.Add('credential',ProviderParam."Credential Code"); Cells.Add('prefix',ProviderParam."Value Prefix"); Cells.Add('required',ProviderParam.Required); Cells.Add('enabled',ProviderParam.Enabled);
                                ParamNode.Add('nodeType','Parameter'); ParamNode.Add('key1',Service.Code); ParamNode.Add('key2',Operation.Code); ParamNode.Add('key3',ProviderCode); ParamNode.Add('key4',ProviderParam.Code); ParamNode.Add('cells',Cells); ParamChildren.Add(ParamNode);
                            until ProviderParam.Next()=0;
                            ProviderNode.Add('children',ParamChildren); ProviderChildren.Add(ProviderNode);
                        end;
                        OpNode.Add('children',ProviderChildren); OpChildren.Add(OpNode);
                    end;
                until Operation.Next()=0;
                ServiceNode.Add('children',OpChildren); Nodes.Add(ServiceNode);
            end;
        until Service.Next()=0;
        Root.Add('columns',Columns); Root.Add('nodes',Nodes); Root.WriteTo(Payload); CurrPage.Tree.Render(Payload);
    end;

    local procedure EditSelected()
    var Service: Record "SI EDS Service"; Operation: Record "SI EDS Operation"; Param: Record "SI EDS Parameter";
    begin case SelectedNodeType of 'Service': if Service.Get(SelectedService) then Page.RunModal(Page::"SI EDS Services",Service); 'Operation': if Operation.Get(SelectedService,SelectedOperation) then Page.RunModal(Page::"SI EDS Operations",Operation); 'Parameter': if Param.Get(SelectedService,SelectedOperation,SelectedProvider,SelectedParameter) then Page.RunModal(Page::"SI EDS Parameters",Param); end; RenderTree(); end;
    local procedure DeleteSelected()
    var Param: Record "SI EDS Parameter";
    begin if SelectedNodeType <> 'Parameter' then begin Message('Для видалення виберіть параметр.'); exit; end; if not Param.Get(SelectedService,SelectedOperation,SelectedProvider,SelectedParameter) then exit; if Confirm('Видалити параметр %1 / %2 / %3 / %4?',false,SelectedService,SelectedOperation,SelectedProvider,SelectedParameter) then Param.Delete(true); Clear(SelectedNodeType); RenderTree(); end;
    local procedure AddColumn(var Columns: JsonArray; ColumnKey: Text; CaptionText: Text; Width: Text)
    var Column: JsonObject;
    begin Column.Add('key',ColumnKey); Column.Add('caption',CaptionText); Column.Add('width',Width); Columns.Add(Column); end;
}
