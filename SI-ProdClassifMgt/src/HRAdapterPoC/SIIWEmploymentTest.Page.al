page 56200 "SI IW Employment Test"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'SI IW HR Adapter - Employment Test';
    SourceTable = "SI Employment Context";
    SourceTableTemporary = true;
    Editable = true;

    layout
    {
        area(Content)
        {
            group(TestParameters)
            {
                Caption = 'Test Parameters';
                field(EmployeeNo; EmployeeNo)
                {
                    ApplicationArea = All;
                    Caption = 'BC Employee No.';
                    TableRelation = Employee."No.";
                    Editable = true;

                    trigger OnValidate()
                    begin
                        LoadEmployments();
                    end;
                }
                field(ContextDate; ContextDate)
                {
                    ApplicationArea = All;
                    Caption = 'Context Date';
                    Editable = true;
                }
            }
            repeater(Employments)
            {
                field("Person No."; Rec."Person No.") { ApplicationArea = All; }
                field("Person Name"; Rec."Person Name") { ApplicationArea = All; }
                field("Employment Context ID"; Rec."Employment Context ID") { ApplicationArea = All; }
                field("Employment Status"; Rec."Employment Status") { ApplicationArea = All; }
                field("Employment Type"; Rec."Employment Type") { ApplicationArea = All; }
                field(Blocked; Rec.Blocked) { ApplicationArea = All; }
                field("Employment Date"; Rec."Employment Date") { ApplicationArea = All; }
                field("Has Actual Context"; Rec."Has Actual Context") { ApplicationArea = All; }
                field("Ledger Entry No."; Rec."Ledger Entry No.") { ApplicationArea = All; }
                field("Context Posting Date"; Rec."Context Posting Date") { ApplicationArea = All; }
                field("Context Ending Date"; Rec."Context Ending Date") { ApplicationArea = All; }
                field("Department Code"; Rec."Department Code") { ApplicationArea = All; }
                field("Department Name"; Rec."Department Name") { ApplicationArea = All; }
                field("Unit No."; Rec."Unit No.") { ApplicationArea = All; }
                field("Unit Name"; Rec."Unit Name") { ApplicationArea = All; }
                field("Position Code"; Rec."Position Code") { ApplicationArea = All; }
                field("Position Name"; Rec."Position Name") { ApplicationArea = All; }
                field("Ledger Entry Type"; Rec."Ledger Entry Type") { ApplicationArea = All; }
                field("Resolved for Date"; Rec."Resolved for Date") { ApplicationArea = All; }
                field("Is Active on Context Date"; Rec."Is Active on Context Date") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Load)
            {
                ApplicationArea = All;
                Caption = 'Load Employment Context';
                Image = Refresh;

                trigger OnAction()
                begin
                    LoadEmployments();
                end;
            }
            action(ResolveOnDate)
            {
                ApplicationArea = All;
                Caption = 'Resolve on Context Date';
                Image = Calculate;

                trigger OnAction()
                begin
                    ResolveOnContextDate();
                end;
            }
            action(ClearResult)
            {
                ApplicationArea = All;
                Caption = 'Clear';
                Image = ClearLog;

                trigger OnAction()
                begin
                    Rec.Reset();
                    Rec.DeleteAll();
                    CurrPage.Update(false);
                end;
            }
            action(DeleteBadManningImport)
            {
                ApplicationArea = All;
                Caption = 'Delete bad Manning import';
                Image = Delete;

                trigger OnAction()
                var
                    ManningTable: Record "IWSP Manning Table";
                    DeletedCount: Integer;
                    RecordCount: Integer;
                begin
                    ManningTable.SetRange(
                        "Unit No.",
                        'ШТАТОД0014',
                        'ШТАТОД0027');

                    RecordCount := ManningTable.Count();

                    if RecordCount = 0 then begin
                        Message(
                            'No Manning Table records found in range ШТАТОД0014..ШТАТОД0027.');
                        exit;
                    end;

                    if not Confirm(
                        'Delete %1 IWSP Manning Table records in range ШТАТОД0014..ШТАТОД0027?',
                        false,
                        RecordCount)
                    then
                        exit;

                    if ManningTable.FindSet(true) then
                        repeat
                            ManningTable.Delete(true);
                            DeletedCount += 1;
                        until ManningTable.Next() = 0;

                    Message(
                        'Deleted %1 Manning Table records.',
                        DeletedCount);
                end;
            }

        }
    }

    trigger OnOpenPage()
    begin
        ContextDate := WorkDate();
    end;

    local procedure ResolveOnContextDate()
    var
        ProviderType: Enum "SI Workforce Provider Type";
        Provider: Interface "SI Workforce Provider";
    begin
        // The page itself is bound to the temporary Rec instance.  A provider call
        // that returns zero rows can leave the page cursor positioned on the row
        // displayed by the previous resolution.  Clear the page buffer first so
        // a zero-result resolution cannot display stale data.
        Rec.Reset();
        Rec.DeleteAll();
        Rec.Init();

        ProviderType := ProviderType::IW;
        Provider := ProviderType;
        Provider.ResolveEmploymentContexts(EmployeeNo, ContextDate, Rec);

        Rec.Reset();
        if Rec.FindFirst() then begin
            CurrPage.Update(false);
            exit;
        end;

        Clear(Rec);
        CurrPage.Update(false);
        Message('No active employment context was resolved for %1 on %2.', EmployeeNo, ContextDate);
    end;

    local procedure LoadEmployments()
    var
        ProviderType: Enum "SI Workforce Provider Type";
        Provider: Interface "SI Workforce Provider";
    begin
        ProviderType := ProviderType::IW;
        Provider := ProviderType;
        Provider.GetEmployments(EmployeeNo, Rec);
        CurrPage.Update(false);
    end;

    var
        EmployeeNo: Code[20];
        ContextDate: Date;
}
