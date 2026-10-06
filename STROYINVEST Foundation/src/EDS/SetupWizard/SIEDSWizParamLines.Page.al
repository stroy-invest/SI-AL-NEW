page 50485 "SI EDS Wiz Param Lines"
{
    PageType = ListPart;
    SourceTable = "SI EDS Wiz Param Buffer";
    Caption = 'Параметри операції';
    ApplicationArea = All;
    AutoSplitKey = true;
    DelayedInsert = true;

    layout { area(Content) { repeater(Lines) {
        field(Code; Rec.Code) { ApplicationArea = All; Editable = not Rec.Existing; }
        field(Sequence; Rec.Sequence) { ApplicationArea = All; Editable = not Rec.Existing; }
        field("External Name"; Rec."External Name") { ApplicationArea = All; Editable = not Rec.Existing; }
        field(Location; Rec.Location) { ApplicationArea = All; Editable = not Rec.Existing; }
        field(Source; Rec.Source) { ApplicationArea = All; Editable = not Rec.Existing; }
        field(Format; Rec.Format) { ApplicationArea = All; Editable = not Rec.Existing; }
        field("Runtime Key"; Rec."Runtime Key") { ApplicationArea = All; Editable = not Rec.Existing; }
        field(Value; Rec.Value) { ApplicationArea = All; Editable = not Rec.Existing; }
        field("Credential Code"; Rec."Credential Code") { ApplicationArea = All; Editable = not Rec.Existing; }
        field("Value Prefix"; Rec."Value Prefix") { ApplicationArea = All; Editable = not Rec.Existing; }
        field(Required; Rec.Required) { ApplicationArea = All; Editable = not Rec.Existing; }
        field(Existing; Rec.Existing) { ApplicationArea = All; Editable = false; }
    } } }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.Existing := false;
    end;

    procedure ClearLines()
    begin
        Rec.Reset(); Rec.DeleteAll();
    end;

    procedure LoadExisting(ServiceCode: Code[50]; OperationCode: Code[50]; ProviderCode: Code[50])
    var P: Record "SI EDS Parameter"; EntryNo: Integer;
    begin
        ClearLines();
        P.SetRange("Service Code", ServiceCode); P.SetRange("Operation Code", OperationCode); P.SetRange("Provider Code", ProviderCode);
        if P.FindSet() then repeat
            EntryNo += 10000; Rec.Init(); Rec."Entry No." := EntryNo; Rec.Code := P.Code; Rec.Sequence := P.Sequence;
            Rec."External Name" := P."External Name"; Rec.Location := P.Location; Rec.Source := P.Source; Rec.Format := P.Format;
            Rec."Runtime Key" := P."Runtime Key"; Rec.Value := P.Value; Rec."Credential Code" := P."Credential Code";
            Rec."Value Prefix" := P."Value Prefix"; Rec.Required := P.Required; Rec.Existing := true; Rec.Insert();
        until P.Next() = 0;
    end;

    procedure ValidateLines(ProviderCode: Code[50]; NewCredentialCode: Code[50]; HasNewCredential: Boolean)
    var Credential: Record "SI EDS Credential"; Seen: Record "SI EDS Wiz Param Buffer" temporary;
    begin
        Rec.Reset(); if Rec.FindSet() then repeat
            if not Rec.Existing then begin
                Rec.TestField(Code); if Rec."External Name" = '' then Error('Для параметра %1 вкажіть зовнішнє ім''я.', Rec.Code);
                Seen.Reset(); Seen.SetRange(Code, Rec.Code); if Seen.FindFirst() then Error('Параметр %1 додано в майстер більше одного разу.', Rec.Code);
                Seen := Rec; Seen.Insert();
                if (Rec.Source = Rec.Source::Runtime) and (Rec."Runtime Key" = '') then Error('Для runtime-параметра %1 вкажіть Runtime key.', Rec.Code);
                if Rec.Source = Rec.Source::Credential then begin
                    if Rec.Location <> Rec.Location::Header then Error('Credential-параметр %1 дозволено лише в HTTP Header.', Rec.Code);
                    if Rec."Credential Code" = '' then Error('Для credential-параметра %1 вкажіть облікові дані.', Rec.Code);
                    if not (HasNewCredential and (Rec."Credential Code" = NewCredentialCode)) then
                        if not Credential.Get(ProviderCode, Rec."Credential Code") then Error('Облікові дані %1 / %2 не знайдено.', ProviderCode, Rec."Credential Code");
                end;
                if (Rec.Location = Rec.Location::Path) and (Rec.Source <> Rec.Source::Runtime) then Error('Path-параметр %1 повинен мати джерело Runtime.', Rec.Code);
            end;
        until Rec.Next() = 0;
    end;

    procedure FinishToEDS(ServiceCode: Code[50]; OperationCode: Code[50]; ProviderCode: Code[50])
    var P: Record "SI EDS Parameter";
    begin
        Rec.Reset(); if Rec.FindSet() then repeat if not Rec.Existing then begin
            if P.Get(ServiceCode, OperationCode, ProviderCode, Rec.Code) then Error('Параметр %1 уже наявний.', Rec.Code);
            P.Init(); P."Service Code" := ServiceCode; P."Operation Code" := OperationCode; P."Provider Code" := ProviderCode;
            P.Code := Rec.Code; P.Sequence := Rec.Sequence; P."External Name" := Rec."External Name"; P.Location := Rec.Location;
            P.Validate(Source, Rec.Source); P.Format := Rec.Format; P."Runtime Key" := Rec."Runtime Key"; P.Value := Rec.Value;
            P."Credential Code" := Rec."Credential Code"; P."Value Prefix" := Rec."Value Prefix"; P.Required := Rec.Required; P.Validate(Enabled, true); P.Insert(true);
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
            ResultText += StrSubstNo('\\  %1 — %2 / %3 [%4]', Rec.Code, Format(Rec.Location), Format(Rec.Source), StateLabel);
        until Rec.Next() = 0;
        exit(ResultText);
    end;

    procedure LineCount(): Integer
    begin Rec.Reset(); exit(Rec.Count()); end;
}
