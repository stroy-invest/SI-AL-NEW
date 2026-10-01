codeunit 56101 "SI Classification Tree Mgt."
{
    procedure BuildTreeJson(
        ClassificationSystemCode: Code[20]): Text
    var
        RootNode: Record "SI Classification Node";
        RootNodesJson: JsonArray;
        TreeJsonText: Text;
    begin
        if ClassificationSystemCode = '' then
            exit('[]');

        RootNode.SetCurrentKey(
            "Classification System Code",
            "Parent Code",
            "Sort Order",
            Code);
        RootNode.SetRange(
            "Classification System Code",
            ClassificationSystemCode);
        RootNode.SetRange("Parent Code", '');

        if RootNode.FindSet() then
            repeat
                RootNodesJson.Add(BuildNodeJson(RootNode));
            until RootNode.Next() = 0;

        RootNodesJson.WriteTo(TreeJsonText);
        exit(TreeJsonText);
    end;

    local procedure BuildNodeJson(
        ClassificationNode: Record "SI Classification Node"): JsonObject
    var
        ChildNode: Record "SI Classification Node";
        NodeJson: JsonObject;
        ChildrenJson: JsonArray;
        NodeName: Text;
    begin
        NodeName := ClassificationNode.Code;

        if ClassificationNode.Description <> '' then
            NodeName :=
                ClassificationNode.Code + ' — ' +
                ClassificationNode.Description;

        NodeJson.Add(
            'systemCode',
            ClassificationNode."Classification System Code");
        NodeJson.Add('code', ClassificationNode.Code);
        NodeJson.Add('name', NodeName);
        NodeJson.Add('level', ClassificationNode.Level);
        NodeJson.Add('isLeaf', ClassificationNode."Is Leaf");
        NodeJson.Add(
            'isSelectable',
            ClassificationNode."Is Selectable");
        NodeJson.Add('isActive', ClassificationNode."Is Active");

        ChildNode.SetCurrentKey(
            "Classification System Code",
            "Parent Code",
            "Sort Order",
            Code);
        ChildNode.SetRange(
            "Classification System Code",
            ClassificationNode."Classification System Code");
        ChildNode.SetRange(
            "Parent Code",
            ClassificationNode.Code);

        if ChildNode.FindSet() then
            repeat
                ChildrenJson.Add(BuildNodeJson(ChildNode));
            until ChildNode.Next() = 0;

        NodeJson.Add('children', ChildrenJson);
        exit(NodeJson);
    end;
}
