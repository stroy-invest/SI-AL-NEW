page 61016 "SI Recipe Sel. Reason Dialog"
{
    PageType = StandardDialog;
    Caption = 'Причина вибору рецептури';
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field(SelectionReason; SelectionReason)
            {
                ApplicationArea = All;
                Caption = 'Причина вибору';
                MultiLine = true;
                ToolTip = 'Необов''язково. Вкажіть причину ручного вибору цієї ревізії рецептури.';
            }
        }
    }

    procedure SetReason(NewReason: Text[250])
    begin
        SelectionReason := NewReason;
    end;

    procedure GetReason(): Text[250]
    begin
        exit(SelectionReason);
    end;

    var
        SelectionReason: Text[250];
}
