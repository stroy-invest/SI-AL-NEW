page 70991 "EDS Secret HTTP Probe"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'EDS Secret HTTP Probe (Synthetic Only)';
    SourceTable = "Integer";
    SourceTableView = where(Number = const(1));
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(Test)
            {
                Caption = 'Synthetic HTTP Test';
                field(TestPassword; TestPassword)
                {
                    ApplicationArea = All;
                    Caption = 'Synthetic password (never a real credential)';
                    ExtendedDatatype = Masked;
                    ToolTip = 'Use a made-up password only. The receiving service echoes the password in its response.';
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(SendTest)
            {
                ApplicationArea = All;
                Caption = 'Send synthetic test';
                Image = TestReport;
                trigger OnAction()
                var
                    Probe: Codeunit "EDS Secret HTTP Probe";
                    SecretPassword: SecretText;
                begin
                    if TestPassword = '' then
                        Error('Enter a made-up test password.');
                    if not Confirm('Send the made-up password to public httpbin.org? Never enter a real credential.', false) then
                        exit;
                    SecretPassword := SecretStrSubstNo('%1', TestPassword);
                    Clear(TestPassword);
                    Probe.RunProbe(SecretPassword);
                end;
            }
        }
    }
    var
        TestPassword: Text[250];
}
