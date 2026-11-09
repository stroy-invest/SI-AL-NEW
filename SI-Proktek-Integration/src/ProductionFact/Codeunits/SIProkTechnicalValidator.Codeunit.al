codeunit 57131 "SI Prok Technical Validator"
{
    // Technical completeness only. No production execution inference, no accounting actions.
    procedure Assess(var Fact: Record "SI Prok Production Fact")
    var
        Line: Record "SI Prok Prod Fact Material";
        Item: Record Item;
        Variant: Record "Item Variant";
        BOMVersion: Record "Production BOM Version";
        Recipe: Record "SI Concrete Recipe";
        Incomplete: Boolean;
        Inconsistent: Boolean;
        Warnings: Boolean;
        Diagnostics: Text;
        LineCount: Integer;
    begin
        CurrentFactEntryNo := Fact."Entry No.";
        NextDiagnosticEntryNo := 0;
        DiagnosticEntry.Reset();
        DiagnosticEntry.SetRange("Production Fact Entry No.", CurrentFactEntryNo);
        DiagnosticEntry.DeleteAll();
        if IsNullGuid(Fact."Production UUID") then
            AddIssue('V01', 'Production UUID відсутній', Incomplete, Diagnostics);
        if (Fact."Production ID" = 0) or (Fact."Production Date/Time" = 0DT) then
            AddIssue('V02', 'Production ID або дата/час відсутні', Incomplete, Diagnostics);
        if IsNullGuid(Fact."Formula UUID") and (Fact."Formula ID" = 0) and (Fact."Formula Code" = '') then
            AddIssue('V03', 'Формулу Proktek не ідентифіковано', Incomplete, Diagnostics);
        if (Fact."Production BOM No." = '') or (Fact."Production BOM Version Code" = '') then
            AddIssue('V04', 'Не визначено BOM та його версію', Incomplete, Diagnostics)
        else
            if not BOMVersion.Get(Fact."Production BOM No.", Fact."Production BOM Version Code") then
                AddIssue('V04', 'Версія BOM відсутня у BC', Incomplete, Diagnostics);
        if (Fact."Recipe No." = '') or (Fact."Recipe Revision No." = 0) then
            AddIssue('V05', 'Не визначено рецептуру або ревізію', Incomplete, Diagnostics)
        else
            if not Recipe.Get(Fact."Recipe No.") then
                AddIssue('V05', 'Коренева рецептура відсутня', Incomplete, Diagnostics)
            else begin
                if (Recipe."Item No." <> Fact."Item No.") or (Recipe."Variant Code" <> Fact."Variant Code") then
                    AddIssue('V11', 'Item/Variant не збігається з кореневою рецептурою', Inconsistent, Diagnostics);
            end;
        if (Fact."Item No." = '') or (not Item.Get(Fact."Item No.")) then
            AddIssue('V06', 'Товар готової продукції не визначено', Incomplete, Diagnostics);
        if Fact."Variant Code" <> '' then
            if not Variant.Get(Fact."Item No.", Fact."Variant Code") then
                AddIssue('V07', 'Варіант готової продукції не знайдено', Incomplete, Diagnostics);
        if Fact."Reported Quantity Present" and (Fact."Reported Quantity M3" < 0) then
            AddIssue('V10', 'Від’ємний заявлений обсяг MES', Inconsistent, Diagnostics);
        if Fact."Execution Evidence" = Fact."Execution Evidence"::Inconsistent then
            AddIssue('V12', 'Суперечливі показники бункерів', Inconsistent, Diagnostics);
        Line.SetRange("Production Fact Entry No.", Fact."Entry No.");
        if Line.FindSet() then
            repeat
                LineCount += 1;
                if (not Line."BC Material Resolved") or (Line."Item No." = '') then
                    AddIssue('V08', StrSubstNo('Рядок %1: матеріал не зіставлено', Line."Line No."), Incomplete, Diagnostics)
                else begin
                    if not Item.Get(Line."Item No.") then
                        AddIssue('V08', StrSubstNo('Рядок %1: Item не існує', Line."Line No."), Incomplete, Diagnostics);
                    if Line."Variant Code" <> '' then
                        if not Variant.Get(Line."Item No.", Line."Variant Code") then
                            AddIssue('V08', StrSubstNo('Рядок %1: Variant не існує', Line."Line No."), Incomplete, Diagnostics);
                end;
                if not Line."UoM Normalized" then
                    AddIssue('V09', StrSubstNo('Рядок %1: UoM не нормалізовано: %2', Line."Line No.", Line."UoM Diagnostic"), Incomplete, Diagnostics);
                if (Line."Requested Kg" < 0) or (Line."Adjusted Kg" < 0) or (Line."Actual Kg" < 0) then
                    AddIssue('V10', StrSubstNo('Рядок %1: від’ємна кількість матеріалу', Line."Line No."), Inconsistent, Diagnostics);
                // Zero actual is valid. It does not prove Not Produced.
            until Line.Next() = 0;
        if LineCount = 0 then
            AddIssue('V08', 'Матеріальні рядки відсутні', Incomplete, Diagnostics);
        // Existing evidence is informational; no inference of physical production outcome.
        if (Fact."Truck Code" = '') and (Fact."Truck Plate" = '') then begin
            Warnings := true;
            AddDiagnostic('W03', 'Не вказано автоміксер', Diagnostics);
        end;
        if Inconsistent then
            Fact."Technical Validation" := Fact."Technical Validation"::Inconsistent
        else if Incomplete then
            Fact."Technical Validation" := Fact."Technical Validation"::Incomplete
        else if Warnings then
            Fact."Technical Validation" := Fact."Technical Validation"::CompleteWithWarnings
        else
            Fact."Technical Validation" := Fact."Technical Validation"::Complete;
        Fact."Technical Diagnostics" := CopyStr(Diagnostics, 1, MaxStrLen(Fact."Technical Diagnostics"));
        Fact.Modify(true);
    end;

    local procedure AddIssue(Code: Text; Message: Text; var Flag: Boolean; var Diagnostics: Text)
    begin
        Flag := true;
        AddDiagnostic(Code, Message, Diagnostics);
    end;

    local procedure AddDiagnostic(Code: Text; Message: Text; var Diagnostics: Text)
    var
        LineNo: Integer;
    begin
        NextDiagnosticEntryNo += 1;
        DiagnosticEntry.Init();
        DiagnosticEntry."Production Fact Entry No." := CurrentFactEntryNo;
        DiagnosticEntry."Entry No." := NextDiagnosticEntryNo;
        DiagnosticEntry."Rule Code" := CopyStr(Code, 1, MaxStrLen(DiagnosticEntry."Rule Code"));
        if CopyStr(Code, 1, 1) = 'W' then
            DiagnosticEntry.Severity := DiagnosticEntry.Severity::Warning
        else
            DiagnosticEntry.Severity := DiagnosticEntry.Severity::Error;
        if (CopyStr(Message, 1, 12) = 'Рядок ') then begin
            if Evaluate(LineNo, SelectStr(1, CopyStr(Message, 7).Replace(':', ','))) then
                DiagnosticEntry."Material Line No." := LineNo;
        end;
        DiagnosticEntry."Object Type" := GetObjectType(Code);
        DiagnosticEntry."Diagnostic Message" := CopyStr(Message, 1, MaxStrLen(DiagnosticEntry."Diagnostic Message"));
        DiagnosticEntry."Checked At" := CurrentDateTime();
        DiagnosticEntry.Insert();
        if Diagnostics <> '' then
            Diagnostics += ' | ';
        Diagnostics += StrSubstNo('%1: %2', Code, Message);
    end;
    local procedure GetObjectType(RuleCode: Text): Text[50]
    begin
        case RuleCode of
            'V01', 'V02': exit('Production Fact');
            'V03': exit('Proktek Formula');
            'V04': exit('BOM Version');
            'V05', 'V11': exit('Recipe / Item');
            'V06', 'V07': exit('Finished Product');
            'V08', 'V09', 'V10', 'V12': exit('Materials / UoM');
            'W03': exit('Truck');
        end;
        exit('Production Fact');
    end;

    var
        DiagnosticEntry: Record "SI Prok Fact Validation Entry";
        CurrentFactEntryNo: Integer;
        NextDiagnosticEntryNo: Integer;
}
