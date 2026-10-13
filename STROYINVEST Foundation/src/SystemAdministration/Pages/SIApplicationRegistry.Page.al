page 50573 "SI Application Registry"
{
    PageType = List;
    SourceTable = "SI App Registry Buffer";
    SourceTableTemporary = true;
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'Додатки та залежності';
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Applications)
            {
                field("App Name"; Rec."App Name") { ApplicationArea = All; }
                field(Publisher; Rec.Publisher) { ApplicationArea = All; }
                field("App Version"; Rec."App Version") { ApplicationArea = All; }
                field("Data Version"; Rec."Data Version") { ApplicationArea = All; }
                field("Upgrade Pending"; Rec."Upgrade Pending") { ApplicationArea = All; }
                field("Dependency Count"; Rec."Dependency Count") { ApplicationArea = All; }
                field("Missing Dependencies"; Rec."Missing Dependencies") { ApplicationArea = All; }
                field("App ID"; Rec."App ID") { ApplicationArea = All; }
                field("Package ID"; Rec."Package ID") { ApplicationArea = All; }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(RefreshRegistry)
            {
                ApplicationArea = All;
                Caption = 'Оновити';
                Image = Refresh;
                trigger OnAction()
                begin
                    RegistryMgt.LoadApplications(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(ShowDependencies)
            {
                ApplicationArea = All;
                Caption = 'Залежності';
                Image = Relationship;
                trigger OnAction()
                var
                    DependencyPage: Page "SI App Dependencies";
                begin
                    DependencyPage.SetApplication(Rec."App ID");
                    DependencyPage.RunModal();
                end;
            }
        }
    }
    trigger OnOpenPage()
    begin
        RegistryMgt.LoadApplications(Rec);
    end;
    var
        RegistryMgt: Codeunit "SI App Registry Mgt.";
}
