page 60014 "SI Project System FactBox"
{
    PageType = CardPart;
    SourceTable = Job;
    ApplicationArea = All;
    Caption = 'Системна інформація';

    layout
    {
        area(Content)
        {
            group(Projection)
            {
                Caption = 'Внутрішня SI-проєкція';

                field("SI Internal Customer No."; Rec."SI Internal Customer No.")
                {
                    ApplicationArea = All;
                    Caption = 'Внутрішній SI-клієнт';
                    Editable = false;
                    ToolTip = 'Системний Customer, який є технічною проєкцією будівельного проєкту для інтеграцій.';
                }
                field(ProjectionState; ProjectionState)
                {
                    ApplicationArea = All;
                    Caption = 'Стан проєкції';
                    Editable = false;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    Caption = 'BC Project';
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OpenInternalSICustomer)
            {
                ApplicationArea = All;
                Caption = 'Відкрити внутрішнього SI-клієнта';
                Image = Customer;
                Enabled = Rec."SI Internal Customer No." <> '';

                trigger OnAction()
                var
                    InternalCustomer: Record Customer;
                begin
                    if InternalCustomer.Get(Rec."SI Internal Customer No.") then
                        Page.Run(Page::"Customer Card", InternalCustomer);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        ProjectionState := InternalCustomerMgt.GetProjectionState(Rec);
    end;

    var
        InternalCustomerMgt: Codeunit "SI Internal Customer Mgt.";
        ProjectionState: Text[50];
}
