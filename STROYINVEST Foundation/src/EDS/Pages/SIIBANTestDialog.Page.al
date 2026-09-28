page 50446 "SI IBAN Test Dialog"
{
    PageType = StandardDialog;
    Caption = 'Перевірка IBAN';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'IBAN';

                field(IBAN; IBANValue)
                {
                    ApplicationArea = All;
                    Caption = 'IBAN';
                    ToolTip = 'Введіть український IBAN для перевірки та визначення банку.';
                }
            }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        IBANMgt: Codeunit "SI IBAN Mgt.";
    begin
        if CloseAction = Action::OK then
            IBANMgt.ValidateUA(IBANValue);

        exit(true);
    end;

    procedure GetIBAN(): Text[100]
    begin
        exit(IBANValue);
    end;

    var
        IBANValue: Text[100];
}
