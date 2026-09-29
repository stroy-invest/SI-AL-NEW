codeunit 53038 "SI Product Tree Context"
{
    SingleInstance = true;

    [EventSubscriber(ObjectType::Page, Page::"SI Item Class. Workspace", 'OnProductContextChanged', '', false, false)]
    local procedure OnProductContextChanged(NodeType: Text; ItemNo: Code[20]; VariantCode: Code[10])
    begin
        CurrentNodeType := CopyStr(NodeType, 1, MaxStrLen(CurrentNodeType));
        CurrentItemNo := ItemNo;
        CurrentVariantCode := VariantCode;
    end;

    procedure GetContext(var NodeType: Text[20]; var ItemNo: Code[20]; var VariantCode: Code[10])
    begin
        NodeType := CurrentNodeType;
        ItemNo := CurrentItemNo;
        VariantCode := CurrentVariantCode;
    end;

    var
        CurrentNodeType: Text[20];
        CurrentItemNo: Code[20];
        CurrentVariantCode: Code[10];
}
