page 63259 "SI Vehicle Model Tree"
{
    PageType = Card;
    Caption = 'Моделі транспорту (дерево)';
    ApplicationArea = All;
    UsageCategory = Lists;
    layout
    {
        area(Content)
        {
            usercontrol(VehicleTree; "SI Vehicle Model Tree")
            {
                ApplicationArea = All;
                trigger ControlReady()
                begin
                    CurrPage.VehicleTree.RenderTree(BuildTreeJson());
                end;

                trigger ModelOpenRequested(BrandCode: Text; ModelCode: Text)
                var
                    Model: Record "SI Vehicle Model";
                begin
                    if Model.Get(CopyStr(BrandCode, 1, MaxStrLen(Model."Brand Code")), CopyStr(ModelCode, 1, MaxStrLen(Model.Code))) then
                        Page.RunModal(Page::"SI Vehicle Model Card", Model);
                    CurrPage.VehicleTree.RenderTree(BuildTreeJson());
                end;

                trigger ModelSelected(BrandCode: Text; ModelCode: Text)
                begin
                    CurrPage.ModelCharacteristics.Page.SetModelContext(CopyStr(BrandCode, 1, 20), CopyStr(ModelCode, 1, 20));
                end;

                trigger SelectionCleared()
                begin
                    CurrPage.ModelCharacteristics.Page.SetModelContext('', '');
                end;

                trigger AddRequested(Kind: Text; TypeCode: Text; BrandCode: Text; ModelCode: Text)
                begin
                    AddNode(Kind, TypeCode, BrandCode);
                    CurrPage.VehicleTree.RenderTree(BuildTreeJson());
                end;

                trigger DeleteRequested(Kind: Text; TypeCode: Text; BrandCode: Text; ModelCode: Text)
                begin
                    DeleteNode(Kind, BrandCode, ModelCode);
                    CurrPage.ModelCharacteristics.Page.SetModelContext('', '');
                    CurrPage.VehicleTree.RenderTree(BuildTreeJson());
                end;
            }
        }
        area(FactBoxes)
        {
            part(ModelCharacteristics; "SI Vehicle Model Char FactBox")
            {
                ApplicationArea = All;
                Caption = 'Характеристики моделі';
            }
        }
    }
    local procedure AddNode(Kind: Text; TypeCode: Text; BrandCode: Text)
    var
        Brand: Record "SI Vehicle Brand";
        Model: Record "SI Vehicle Model";
        BrandDialog: Page "SI Vehicle Tree New Brand";
        ModelDialog: Page "SI Vehicle Tree New Model";
        NewCode: Code[20];
        NewName: Text[100];
    begin
        case Kind of
            'type':
                begin
                    if BrandDialog.RunModal() <> Action::OK then exit;
                    BrandDialog.GetValues(NewCode, NewName);
                    if (NewCode = '') or (NewName = '') then Error('Заповніть код і назву бренду.');
                    if Brand.Get(NewCode) then Error('Бренд %1 уже існує. Виберіть його в дереві та додайте модель.', NewCode);
                    Brand.Init();
                    Brand.Validate(Code, NewCode);
                    Brand.Validate(Name, NewName);
                    Brand.Insert(true);
                    Message('Бренд створено. Щоб він з’явився у гілці типу %1, створіть для нього модель.', TypeCode);
                end;
            'brand', 'model':
                begin
                    if not Brand.Get(CopyStr(BrandCode, 1, 20)) then Error('Бренд %1 не знайдено.', BrandCode);
                    Brand.TestField(Blocked, false);
                    ModelDialog.SetContext(Brand.Code, CopyStr(TypeCode, 1, 20));
                    if ModelDialog.RunModal() <> Action::OK then exit;
                    ModelDialog.GetValues(NewCode, NewName);
                    if (NewCode = '') or (NewName = '') then Error('Заповніть код і назву моделі.');
                    if Model.Get(Brand.Code, NewCode) then Error('Модель %1 / %2 уже існує.', Brand.Code, NewCode);
                    Model.Init();
                    Model.Validate("Brand Code", Brand.Code);
                    Model.Validate(Code, NewCode);
                    Model.Validate(Name, NewName);
                    Model.Validate("Vehicle Type Code", CopyStr(TypeCode, 1, 20));
                    Model.Insert(true);
                end;
            else
                Message('Виберіть тип транспорту, бренд або модель.');
        end;
    end;

    local procedure DeleteNode(Kind: Text; BrandCode: Text; ModelCode: Text)
    var
        Brand: Record "SI Vehicle Brand";
        Model: Record "SI Vehicle Model";
        Capacity: Record "SI Vehicle Model Capacity";
    begin
        case Kind of
            'model':
                begin
                    if not Model.Get(CopyStr(BrandCode, 1, 20), CopyStr(ModelCode, 1, 20)) then exit;
                    if not Confirm('Видалити модель %1 / %2?', false, BrandCode, ModelCode) then exit;
                    // Check dependencies BEFORE removing characteristics.
                    Model.Delete(true);
                    Capacity.SetRange("Brand Code", CopyStr(BrandCode, 1, 20));
                    Capacity.SetRange("Model Code", CopyStr(ModelCode, 1, 20));
                    Capacity.DeleteAll(true);
                end;
            'brand':
                begin
                    if not Brand.Get(CopyStr(BrandCode, 1, 20)) then exit;
                    if not Confirm('Видалити бренд %1? Перевірятимуться всі його залежності.', false, BrandCode) then exit;
                    Brand.Delete(true);
                end;
            else
                Message('Корінь і типи транспорту тут не видаляються.');
        end;
    end;

    local procedure BuildTreeJson(): Text
    var
        VehicleType: Record "SI Vehicle Type";
        Brand: Record "SI Vehicle Brand";
        Model: Record "SI Vehicle Model";
        Root: JsonArray;
        RootNode: JsonObject;
        RootChildren: JsonArray;
        TypeNode: JsonObject;
        BrandNode: JsonObject;
        ModelNode: JsonObject;
        BrandChildren: JsonArray;
        TypeChildren: JsonArray;
        ResultJson: Text;
        LabelText: Text;
    begin
        if VehicleType.FindSet() then
            repeat
                Clear(TypeChildren);
                if Brand.FindSet() then
                    repeat
                        Clear(BrandChildren);
                        Model.Reset();
                        Model.SetRange("Vehicle Type Code", VehicleType.Code);
                        Model.SetRange("Brand Code", Brand.Code);
                        if Model.FindSet() then
                            repeat
                                Clear(ModelNode);
                                LabelText := Model.Name;
                                if LabelText = '' then LabelText := Model.Code;
                                ModelNode.Add('key', StrSubstNo('M|%1|%2', Brand.Code, Model.Code));
                                ModelNode.Add('kind', 'model');
                                ModelNode.Add('label', LabelText);
                                ModelNode.Add('code', Model.Code);
                                ModelNode.Add('type', VehicleType.Code);
                                ModelNode.Add('brand', Brand.Code);
                                ModelNode.Add('model', Model.Code);
                                BrandChildren.Add(ModelNode);
                            until Model.Next() = 0;
                        if BrandChildren.Count() > 0 then begin
                            Clear(BrandNode);
                            LabelText := Brand.Name;
                            if LabelText = '' then LabelText := Brand.Code;
                            BrandNode.Add('key', StrSubstNo('B|%1|%2', VehicleType.Code, Brand.Code));
                            BrandNode.Add('kind', 'brand');
                            BrandNode.Add('label', LabelText);
                            BrandNode.Add('code', Brand.Code);
                            BrandNode.Add('type', VehicleType.Code);
                            BrandNode.Add('brand', Brand.Code);
                            BrandNode.Add('children', BrandChildren);
                            TypeChildren.Add(BrandNode);
                        end;
                    until Brand.Next() = 0;
                Clear(TypeNode);
                LabelText := VehicleType.Description;
                if LabelText = '' then LabelText := VehicleType.Code;
                TypeNode.Add('key', StrSubstNo('T|%1', VehicleType.Code));
                TypeNode.Add('kind', 'type');
                TypeNode.Add('label', LabelText);
                TypeNode.Add('code', VehicleType.Code);
                TypeNode.Add('type', VehicleType.Code);
                TypeNode.Add('children', TypeChildren);
                RootChildren.Add(TypeNode);
            until VehicleType.Next() = 0;
        RootNode.Add('key', 'ROOT');
        RootNode.Add('kind', 'root');
        RootNode.Add('label', 'Транспортні засоби');
        RootNode.Add('children', RootChildren);
        Root.Add(RootNode);
        Root.WriteTo(ResultJson);
        exit(ResultJson);
    end;
}
