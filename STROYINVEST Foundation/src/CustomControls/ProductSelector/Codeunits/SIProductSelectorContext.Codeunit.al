codeunit 50195 "SI Product Selector Context"
{
    SingleInstance = true;

    var
        AcceptedItemNo: Code[20];
        AcceptedVariantCode: Code[10];
        SelectionAccepted: Boolean;

    procedure Reset()
    begin
        Clear(AcceptedItemNo);
        Clear(AcceptedVariantCode);
        SelectionAccepted := false;
    end;

    procedure Accept(ItemNo: Code[20]; VariantCode: Code[10])
    begin
        AcceptedItemNo := ItemNo;
        AcceptedVariantCode := VariantCode;
        SelectionAccepted := ItemNo <> '';
    end;

    procedure TryGetSelection(var ItemNo: Code[20]; var VariantCode: Code[10]): Boolean
    begin
        if not SelectionAccepted then
            exit(false);

        ItemNo := AcceptedItemNo;
        VariantCode := AcceptedVariantCode;
        exit(true);
    end;

    procedure HasSelection(): Boolean
    begin
        exit(SelectionAccepted);
    end;
}
