page 57141 "SI Prok Driver Mappings"
{
    PageType = List;
    SourceTable = "SI Prok Driver Mapping";
    Caption = 'Зіставлення водіїв Proktek';
    ApplicationArea = All;
    UsageCategory = Lists;
    InsertAllowed = false;
    DeleteAllowed = false;
    layout
    {
        area(Content)
        {
            repeater(Drivers)
            {
                field("Connection Code"; Rec."Connection Code") { ApplicationArea = All; Editable = false; }
                field("Driver UUID"; Rec."Driver UUID") { ApplicationArea = All; Editable = false; }
                field("External Driver ID"; Rec."External Driver ID") { ApplicationArea = All; Editable = false; }
                field("Employee No."; Rec."Employee No.") { ApplicationArea = All; Editable = false; }
                field("Driver Name"; Rec."Driver Name") { ApplicationArea = All; Editable = false; }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(SyncAllDrivers)
            {
                Caption = 'Синхронізувати всіх водіїв';
                ApplicationArea = All;
                Image = Refresh;
                trigger OnAction()
                var
                    Sync: Codeunit "SI Prok Driver Sync Manager";
                begin
                    Sync.SyncAll(Rec."Connection Code");
                    CurrPage.Update(false);
                end;
            }
            action(SyncOneDriver)
            {
                Caption = 'Синхронізувати водія';
                ApplicationArea = All;
                Image = RefreshLines;
                trigger OnAction()
                var
                    Sync: Codeunit "SI Prok Driver Sync Manager";
                begin
                    Sync.SyncOne(Rec."Connection Code", Rec."Employee No.");
                    CurrPage.Update(false);
                end;
            }
        }
    }
}
