page 65006 "SI IW Setup Check Results"
{
    PageType = List;
    SourceTable = "SI IW Setup Check Result";
    SourceTableTemporary = true;
    Caption = 'SI IW: Перевірка налаштувань';
    ApplicationArea = All;
    UsageCategory = Administration;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Checks)
            {
                field(CheckArea; Rec."Check Area") { ApplicationArea = All; }
                field(ObjectCode; Rec."Object Code") { ApplicationArea = All; }
                field(Result; Rec.Result) { ApplicationArea = All; }
                field(Details; Rec.Details) { ApplicationArea = All; }
                field(RecommendedAction; Rec."Recommended Action") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RunChecks)
            {
                ApplicationArea = All;
                Caption = 'Повторити перевірку';
                Image = Refresh;
                trigger OnAction()
                begin
                    RefreshChecks();
                end;
            }
            action(OpenMappings)
            {
                ApplicationArea = All;
                Caption = 'Налаштувати Mapping';
                Image = Setup;
                trigger OnAction()
                begin
                    Page.Run(Page::"SI IW Vehicle Type Mappings");
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        RefreshChecks();
    end;

    local procedure RefreshChecks()
    var
        Checker: Codeunit "SI IW Integration Setup Check";
    begin
        Checker.RunChecks(Rec);
        CurrPage.Update(false);
    end;
}
