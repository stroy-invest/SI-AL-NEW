page 60017 "SI Project Admin Console"
{
    PageType = List;
    SourceTable = Job;
    SourceTableView = where("SI Construction Project" = const(true));
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'SI Project Admin Console';
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Projects)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    Caption = '№ проєкту';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Назва проєкту';
                }
                field(InternalCustomerName; InternalCustomerName)
                {
                    ApplicationArea = All;
                    Caption = 'Внутрішній SI-клієнт';
                }
                field("SI Internal Customer No."; Rec."SI Internal Customer No.")
                {
                    ApplicationArea = All;
                    Caption = 'Код внутрішнього SI-клієнта';
                }
                field(ProjectionState; ProjectionState)
                {
                    ApplicationArea = All;
                    Caption = 'Стан проєкції';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SyncProjection)
            {
                ApplicationArea = All;
                Caption = 'Синхронізувати';
                Image = Refresh;

                trigger OnAction()
                var
                    InternalCustomer: Record Customer;
                begin
                    InternalCustomerMgt.EnsureInternalSICustomer(Rec, InternalCustomer);
                    CurrPage.Update(false);
                end;
            }
            action(RepairProjection)
            {
                ApplicationArea = All;
                Caption = 'Відновити проєкцію';
                Image = Reconcile;

                trigger OnAction()
                var
                    InternalCustomer: Record Customer;
                begin
                    InternalCustomerMgt.RepairInternalSICustomer(Rec, InternalCustomer);
                    CurrPage.Update(false);
                end;
            }
        }
        area(Navigation)
        {
            action(OpenProject)
            {
                ApplicationArea = All;
                Caption = 'Відкрити проєкт';

                trigger OnAction()
                begin
                    Page.Run(Page::"SI Construction Project Card", Rec);
                end;
            }
            action(OpenInternalCustomer)
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
    var
        InternalCustomer: Record Customer;
    begin
        Clear(InternalCustomerName);
        if InternalCustomerMgt.FindInternalSICustomer(Rec, InternalCustomer) then
            InternalCustomerName := InternalCustomer.Name;
        ProjectionState := InternalCustomerMgt.GetProjectionState(Rec);
    end;

    var
        InternalCustomerMgt: Codeunit "SI Internal Customer Mgt.";
        InternalCustomerName: Text[100];
        ProjectionState: Text[50];
}
