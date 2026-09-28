page 60010 "SI Construction Projects"
{
    PageType = List;
    SourceTable = Job;
    SourceTableView = where("SI Construction Project" = const(true));
    CardPageId = "SI Construction Project Card";
    ApplicationArea = All;
    UsageCategory = Lists;
    Caption = 'Будівельні проєкти';
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
                    Caption = 'Коротка назва';
                }
                field("SI Project Status"; Rec."SI Project Status")
                {
                    ApplicationArea = All;
                    Caption = 'Статус';
                }
                field(CustomerDisplayName; CustomerDisplayName)
                {
                    ApplicationArea = All;
                    Caption = 'Замовник';
                    Editable = false;
                    ToolTip = 'Визначає зовнішнього замовника будівельного проєкту.';
                }
                field(LocationDisplayName; LocationDisplayName)
                {
                    ApplicationArea = All;
                    Caption = 'Склад проєкту';
                    Editable = false;
                    ToolTip = 'Визначає склад/майданчик будівельного проєкту.';
                }
                field(ProjectManagerDisplayName; ProjectManagerDisplayName)
                {
                    ApplicationArea = All;
                    Caption = 'Керівник проєкту';
                    Editable = false;
                    ToolTip = 'Визначає чинного основного працівника в ролі керівника проєкту.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = All;
                    Caption = 'Дата початку';
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = All;
                    Caption = 'Планове завершення';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        RefreshDisplayValues();
    end;

    local procedure RefreshDisplayValues()
    var
        Customer: Record Customer;
        Location: Record Location;
        ProjectManager: Record Employee;
        AssignmentMgt: Codeunit "SI Project Assignment Mgt.";
    begin
        Clear(CustomerDisplayName);
        Clear(LocationDisplayName);
        Clear(ProjectManagerDisplayName);

        if (Rec."Sell-to Customer No." <> '') and Customer.Get(Rec."Sell-to Customer No.") then
            CustomerDisplayName := Customer.Name;

        if (Rec."Location Code" <> '') and Location.Get(Rec."Location Code") then
            LocationDisplayName := Location.Name;

        if AssignmentMgt.TryGetPrimaryEmployee(Rec."No.", 'PROJECT_MANAGER', WorkDate(), ProjectManager) then
            ProjectManagerDisplayName := ProjectManager.FullName();
    end;

    var
        CustomerDisplayName: Text[100];
        LocationDisplayName: Text[100];
        ProjectManagerDisplayName: Text[100];
}
