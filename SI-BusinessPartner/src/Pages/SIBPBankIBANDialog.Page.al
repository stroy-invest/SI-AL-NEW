page 54050 "SI BP Bank IBAN Dialog"
{
    PageType = StandardDialog;
    Caption = 'Банківські реквізити';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'IBAN';

                field(IBANField; IBANValue)
                {
                    ApplicationArea = All;
                    Caption = 'IBAN';
                    ToolTip = 'Введіть український IBAN для перевірки та визначення банку.';
                }
            }
        }
    }

    trigger OnQueryClosePage(
        CloseAction: Action): Boolean
    var
        IBANMgt: Codeunit "SI IBAN Mgt.";
    begin
        if CloseAction <> Action::OK then
            exit(true);

        IBANMgt.ValidateUA(
            IBANValue);

        exit(true);
    end;

    procedure GetIBAN(): Text
    begin
        exit(IBANValue);
    end;

    var
        IBANValue: Text[100];
}