page 57134 "SI Prok Fact Control FactBox"
{
    PageType = CardPart;
    SourceTable = "SI Prok Production Fact";
    Caption = 'Контроль даних';
    ApplicationArea = All;
    Editable = false;
    layout
    {
        area(Content)
        {
            group(Control)
            {
                ShowCaption = false;
                field("Technical Validation"; Rec."Technical Validation") { ApplicationArea = All; StyleExpr = StatusStyle; }
                field(ErrorCount; ErrorCount) { ApplicationArea = All; Caption = 'Помилки'; }
                field(WarningCount; WarningCount) { ApplicationArea = All; Caption = 'Попередження'; }
                field(MaterialCount; MaterialCount) { ApplicationArea = All; Caption = 'Матеріали'; }
                field(UnresolvedCount; UnresolvedCount) { ApplicationArea = All; Caption = 'Невизначені матеріали'; }
                field(UoMErrorCount; UoMErrorCount) { ApplicationArea = All; Caption = 'Помилки нормалізації UoM'; }
            }
        }
    }
    trigger OnAfterGetRecord()
    var
        Diagnostic: Record "SI Prok Fact Validation Entry";
        Material: Record "SI Prok Prod Fact Material";
    begin
        Clear(ErrorCount); Clear(WarningCount); Clear(MaterialCount); Clear(UnresolvedCount); Clear(UoMErrorCount);
        Diagnostic.SetRange("Production Fact Entry No.", Rec."Entry No.");
        Diagnostic.SetRange(Severity, Diagnostic.Severity::Error);
        ErrorCount := Diagnostic.Count();
        Diagnostic.SetRange(Severity, Diagnostic.Severity::Warning);
        WarningCount := Diagnostic.Count();
        Material.SetRange("Production Fact Entry No.", Rec."Entry No.");
        if Material.FindSet() then
            repeat
                MaterialCount += 1;
                if not Material."BC Material Resolved" then UnresolvedCount += 1;
                if not Material."UoM Normalized" then UoMErrorCount += 1;
            until Material.Next() = 0;
        StatusStyle := 'Standard';
        case Rec."Technical Validation" of
            Rec."Technical Validation"::Complete: StatusStyle := 'Favorable';
            Rec."Technical Validation"::Incomplete, Rec."Technical Validation"::Inconsistent: StatusStyle := 'Unfavorable';
            Rec."Technical Validation"::CompleteWithWarnings: StatusStyle := 'Attention';
        end;
    end;
    var
        ErrorCount: Integer;
        WarningCount: Integer;
        MaterialCount: Integer;
        UnresolvedCount: Integer;
        UoMErrorCount: Integer;
        StatusStyle: Text;
}
