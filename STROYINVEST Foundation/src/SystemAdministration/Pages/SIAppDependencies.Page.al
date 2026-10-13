page 50574 "SI App Dependencies"
{
    PageType = List;
    SourceTable = "SI App Dependency Buffer";
    SourceTableTemporary = true;
    ApplicationArea = All;
    Caption = 'Залежності додатка';
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    layout
    {
        area(Content)
        {
            repeater(Dependencies)
            {
                field("Dependency Name"; Rec."Dependency Name") { ApplicationArea = All; }
                field(Publisher; Rec.Publisher) { ApplicationArea = All; }
                field(Installed; Rec.Installed) { ApplicationArea = All; }
                field("Installed Version"; Rec."Installed Version") { ApplicationArea = All; }
                field(Status; Rec.Status) { ApplicationArea = All; }
                field("Dependency App ID"; Rec."Dependency App ID") { ApplicationArea = All; }
            }
        }
    }
    procedure SetApplication(AppId: Guid)
    begin
        SelectedAppId := AppId;
    end;
    trigger OnOpenPage()
    var
        RegistryMgt: Codeunit "SI App Registry Mgt.";
    begin
        RegistryMgt.LoadDependencies(SelectedAppId, Rec);
    end;
    var
        SelectedAppId: Guid;
}
