page 50486 "SI EDS Wiz Rate Lines"
{
    PageType = ListPart;
    SourceTable = "SI EDS Wiz Rate Buffer";
    Caption = 'Ліміти запитів';
    ApplicationArea = All;
    AutoSplitKey = true;
    DelayedInsert = true;
    layout { area(Content) { repeater(Lines) {
        field(Sequence; Rec.Sequence) { ApplicationArea = All; Editable = not Rec.Existing; }
        field("Window Seconds"; Rec."Window Seconds") { ApplicationArea = All; Editable = not Rec.Existing; }
        field("Max Requests"; Rec."Max Requests") { ApplicationArea = All; Editable = not Rec.Existing; }
        field("Safety Margin %"; Rec."Safety Margin %") { ApplicationArea = All; Editable = not Rec.Existing; }
        field(Description; Rec.Description) { ApplicationArea = All; Editable = not Rec.Existing; }
        field(Existing; Rec.Existing) { ApplicationArea = All; Editable = false; }
    } } }
    trigger OnNewRecord(BelowxRec: Boolean)
    begin Rec.Existing := false; if Rec."Safety Margin %" = 0 then Rec."Safety Margin %" := 80; end;
    procedure ClearLines() begin Rec.Reset(); Rec.DeleteAll(); end;
    procedure LoadExisting(ProviderCode: Code[50])
    var R: Record "SI EDS Provider Rate Limit"; EntryNo: Integer;
    begin
        ClearLines(); R.SetRange("Provider Code", ProviderCode); R.SetRange(Enabled, true);
        if R.FindSet() then repeat EntryNo += 10000; Rec.Init(); Rec."Entry No." := EntryNo; Rec.Sequence := R.Sequence;
            Rec."Window Seconds" := R."Window Seconds"; Rec."Max Requests" := R."Max Requests"; Rec."Safety Margin %" := R."Safety Margin %";
            Rec.Description := R.Description; Rec.Existing := true; Rec.Insert(); until R.Next() = 0;
    end;
    procedure ValidateLines()
    var Seen: Record "SI EDS Wiz Rate Buffer" temporary;
    begin
        Rec.Reset(); if Rec.FindSet() then repeat if not Rec.Existing then begin
            if Rec.Sequence < 1 then Error('Порядок ліміту має бути більшим за нуль.');
            if Rec."Window Seconds" < 1 then Error('Вікно ліміту має бути більшим за нуль.');
            if Rec."Max Requests" < 1 then Error('Максимальна кількість запитів має бути більшою за нуль.');
            if (Rec."Safety Margin %" < 1) or (Rec."Safety Margin %" > 100) then Error('Безпечне використання має бути від 1 до 100 %.');
            Seen.Reset(); Seen.SetRange(Sequence, Rec.Sequence); if Seen.FindFirst() then Error('Порядок ліміту %1 додано більше одного разу.', Rec.Sequence);
            Seen := Rec; Seen.Insert();
        end until Rec.Next() = 0;
    end;
    procedure FinishToEDS(ProviderCode: Code[50])
    var R: Record "SI EDS Provider Rate Limit";
    begin
        Rec.Reset(); if Rec.FindSet() then repeat if not Rec.Existing then begin
            if R.Get(ProviderCode, Rec.Sequence) then Error('Ліміт із порядком %1 уже наявний для %2.', Rec.Sequence, ProviderCode);
            R.Init(); R."Provider Code" := ProviderCode; R.Sequence := Rec.Sequence; R."Window Seconds" := Rec."Window Seconds";
            R."Max Requests" := Rec."Max Requests"; R."Safety Margin %" := Rec."Safety Margin %"; R.Description := Rec.Description; R.Enabled := true; R.Insert(true);
        end until Rec.Next() = 0;
    end;
    procedure BuildSummary(): Text
    var
        ResultText: Text;
        StateLabel: Text[30];
    begin
        Rec.Reset();
        if not Rec.FindSet() then
            exit('\\  (немає)');
        repeat
            if Rec.Existing then
                StateLabel := 'наявний'
            else
                StateLabel := 'буде створено';
            ResultText += StrSubstNo('\\  %1: %2 запитів / %3 сек., %4 % [%5]', Rec.Sequence, Rec."Max Requests", Rec."Window Seconds", Rec."Safety Margin %", StateLabel);
        until Rec.Next() = 0;
        exit(ResultText);
    end;

    procedure LineCount(): Integer begin Rec.Reset(); exit(Rec.Count()); end;
}
