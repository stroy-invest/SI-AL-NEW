codeunit 50196 "SI Category Selector Context"
{
    SingleInstance = true;

    var
        SelectedCategoryCode: Code[20];
        SelectionAccepted: Boolean;

    procedure Reset()
    begin
        Clear(SelectedCategoryCode);
        SelectionAccepted := false;
    end;

    procedure Accept(CategoryCode: Code[20])
    begin
        SelectedCategoryCode := CategoryCode;
        SelectionAccepted := true;
    end;

    procedure TryGetSelection(var CategoryCode: Code[20]): Boolean
    begin
        if not SelectionAccepted then
            exit(false);
        CategoryCode := SelectedCategoryCode;
        exit(true);
    end;

    procedure HasSelection(): Boolean
    begin
        exit(SelectionAccepted);
    end;
}
