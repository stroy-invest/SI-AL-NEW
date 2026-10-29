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
            action(RepairProject)
            {
                ApplicationArea = All;
                Caption = 'Відновити проєкт';
                Image = Reconcile;
                ToolTip = 'Створює або відновлює пов’язаного внутрішнього клієнта, склад проєкту, базовий будмайданчик і задачі проєкту.';

                trigger OnAction()
                var
                    Project: Record Job;
                    ErrorText: Text;
                begin
                    Project.Get(Rec."No.");
                    if not Codeunit.Run(Codeunit::"SI Project Repair Runner", Project) then begin
                        ErrorText := GetLastErrorText();
                        Error('Не вдалося відновити проєкт %1: %2', Rec."No.", ErrorText);
                    end;
                    CurrPage.Update(false);
                    Message('Проєкт %1 успішно відновлено.', Rec."No.");
                end;
            }
            action(RepairSelectedProjects)
            {
                ApplicationArea = All;
                Caption = 'Відновити вибрані проєкти';
                Image = Reconcile;
                ToolTip = 'Пакетно відновлює вибрані будівельні проєкти. Помилка одного проєкту не зупиняє інші.';

                trigger OnAction()
                var
                    SelectedProjects: Record Job;
                    Project: Record Job;
                    TotalCount: Integer;
                    SuccessCount: Integer;
                    FailureCount: Integer;
                    FailureDetails: Text;
                    ErrorText: Text;
                begin
                    CurrPage.SetSelectionFilter(SelectedProjects);
                    SelectedProjects.SetRange("SI Construction Project", true);
                    TotalCount := SelectedProjects.Count();
                    if TotalCount = 0 then
                        Error('Не вибрано жодного будівельного проєкту.');
                    if not Confirm('Відновити пов’язані дані для %1 вибраних проєктів?', false, TotalCount) then
                        exit;

                    if SelectedProjects.FindSet() then
                        repeat
                            Project.Get(SelectedProjects."No.");
                            ClearLastError();
                            if Codeunit.Run(Codeunit::"SI Project Repair Runner", Project) then
                                SuccessCount += 1
                            else begin
                                FailureCount += 1;
                                ErrorText := GetLastErrorText();
                                if StrLen(FailureDetails) < 1500 then
                                    FailureDetails += StrSubstNo('\%1: %2', SelectedProjects."No.", ErrorText);
                            end;
                        until SelectedProjects.Next() = 0;

                    CurrPage.Update(false);
                    if FailureCount = 0 then
                        Message('Відновлення завершено. Успішно: %1 із %2.', SuccessCount, TotalCount)
                    else
                        Message('Відновлення завершено. Успішно: %1. Помилки: %2.\Перші помилки:%3',
                            SuccessCount, FailureCount, FailureDetails);
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
