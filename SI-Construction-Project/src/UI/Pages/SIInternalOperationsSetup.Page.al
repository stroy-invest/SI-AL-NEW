page 60030 "SI Internal Operations Setup"
{
    PageType = List;
    SourceTable = "SI Internal Operation Purpose";
    Caption = 'Налаштування внутрішніх операцій';
    ApplicationArea = All;
    UsageCategory = Administration;
    Editable = true;
    layout
    {
        area(Content)
        {
            repeater(Purposes)
            {
                field(Code; Rec.Code) { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
                field("Customer No."; Rec."Customer No.") { ApplicationArea = All; }
                field(Enabled; Rec.Enabled) { ApplicationArea = All; }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(ValidateConfiguration)
            {
                Caption = 'Перевірити налаштування';
                ApplicationArea = All;
                trigger OnAction()
                var
                    Resolver: Codeunit "SI Internal Customer Resolver";
                begin
                    Resolver.ValidateSetup();
                    Message('Активні налаштування перевірено.');
                end;
            }
            action(InternalCustomers)
            {
                Caption = 'Внутрішні клієнти';
                ApplicationArea = All;
                RunObject = page "SI Internal Customers";
            }
        }
    }

}
