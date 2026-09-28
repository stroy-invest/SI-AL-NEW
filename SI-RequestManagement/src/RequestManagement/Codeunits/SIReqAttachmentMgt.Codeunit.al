codeunit 52030 "SI Req. Attachment Mgt."
{
    [EventSubscriber(ObjectType::Page, Page::"Doc. Attachment List Factbox", 'OnAfterGetRecRefFail', '', false, false)]
    local procedure OnAfterGetRecRefFail(
        var Sender: Page "Doc. Attachment List Factbox";
        DocumentAttachment: Record "Document Attachment";
        var RecRef: RecordRef)
    var
        SIRequestHeader: Record "SI Request Header";
    begin
        if DocumentAttachment."Table ID" <> Database::"SI Request Header" then
            exit;

        if SIRequestHeader.Get(DocumentAttachment."No.") then
            RecRef.GetTable(SIRequestHeader);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Document Attachment", 'OnAfterInitFieldsFromRecRef', '', false, false)]
    local procedure OnAfterInitFieldsFromRecRef(
        var DocumentAttachment: Record "Document Attachment";
        var RecRef: RecordRef)
    var
        FieldRef: FieldRef;
        RequestNo: Code[20];
    begin
        if RecRef.Number <> Database::"SI Request Header" then
            exit;

        FieldRef := RecRef.Field(1); // SI Request Header."No."
        RequestNo := FieldRef.Value();

        DocumentAttachment.Validate("Table ID", Database::"SI Request Header");
        DocumentAttachment.Validate("No.", RequestNo);
    end;
}