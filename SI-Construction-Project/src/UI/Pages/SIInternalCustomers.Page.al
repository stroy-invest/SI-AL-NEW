page 60037 "SI Internal Customers"
{
    Caption = 'Внутрішні клієнти';
    PageType = List;
    SourceTable = Customer;
    SourceTableView = where("SI Customer Type" = filter("Internal Project" | "Internal Operations"));
    ApplicationArea = All;
    UsageCategory = None;
    CardPageId = "SI Internal Customer Card";
    InsertAllowed = false;
    DeleteAllowed = false;
    layout
    {
        area(Content)
        {
            repeater(Customers)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
                field("SI Customer Type"; Rec."SI Customer Type") { ApplicationArea = All; Editable = false; }
                field("SI Project No."; Rec."SI Project No.") { ApplicationArea = All; Editable = false; }
                field(Blocked; Rec.Blocked) { ApplicationArea = All; }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(CreateOperations)
            {
                Caption = 'Створити внутрішнього клієнта';
                ApplicationArea = All;
                Image = NewCustomer;
                trigger OnAction()
                var
                    Creator: Codeunit "SI Internal Operations Create";
                begin
                    Creator.CreateInteractive();
                    CurrPage.Update(false);
                end;
            }
            action(OpenSetup)
            {
                Caption = 'Налаштування операцій';
                ApplicationArea = All;
                RunObject = page "SI Internal Operations Setup";
            }
        }
    }
}
