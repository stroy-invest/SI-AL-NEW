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
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                    trigger OnValidate()
                    begin
                        UpdateDescription();
                    end;
                }
                field(Description; OperationDescription)
                {
                    Caption = 'Опис';
                    ApplicationArea = All;
                    Editable = false;
                }
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
            action(OperationsDirectory)
            {
                Caption = 'Внутрішні операції';
                ApplicationArea = All;
                RunObject = page "SI Internal Operations";
            }
            action(InternalCustomers)
            {
                Caption = 'Внутрішні клієнти';
                ApplicationArea = All;
                RunObject = page "SI Internal Customers";
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        UpdateDescription();
    end;
    trigger OnAfterGetCurrRecord()
    begin
        UpdateDescription();
    end;
    local procedure UpdateDescription()
    var
        Operation: Record "SI Internal Operation";
    begin
        Clear(OperationDescription);
        if Operation.Get(Rec.Code) then
            OperationDescription := Operation.Description;
    end;
    var
        OperationDescription: Text[100];
}
