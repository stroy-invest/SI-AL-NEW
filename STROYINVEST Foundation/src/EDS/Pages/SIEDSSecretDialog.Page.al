page 50461 "SI EDS Secret Dialog"
{
    PageType = StandardDialog;
    Caption = 'Встановити секретне значення';
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(SecretValue; SecretValue)
                {
                    ApplicationArea = All;
                    Caption = 'Секретне значення';
                    ExtendedDatatype = Masked;
                    ToolTip = 'Введіть секретне значення. Після збереження воно не відображатиметься у Business Central.';
                }

                field(SecretConfirmation; SecretConfirmation)
                {
                    ApplicationArea = All;
                    Caption = 'Підтвердження';
                    ExtendedDatatype = Masked;
                    ToolTip = 'Повторно введіть секретне значення для підтвердження.';
                }
            }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction <> Action::OK then begin
            ClearSecretValues();
            exit(true);
        end;

        if SecretValue = '' then
            Error(
                'Введіть секретне значення.');

        if SecretValue <> SecretConfirmation then
            Error(
                'Введені значення не збігаються.');

        exit(true);
    end;

    [NonDebuggable]
    procedure GetSecretValue(): Text
    begin
        exit(SecretValue);
    end;

    procedure ClearSecretValues()
    begin
        Clear(SecretValue);
        Clear(SecretConfirmation);
    end;

    var
        SecretValue: Text[215];
        SecretConfirmation: Text[215];
}