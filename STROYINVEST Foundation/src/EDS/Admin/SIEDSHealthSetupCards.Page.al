page 50477 "SI EDS Service Card"
{
    PageType = Card; SourceTable = "SI EDS Service"; Caption = 'EDS: сервіс'; ApplicationArea = All;
    layout { area(Content) { group(General) { field(Code; Rec.Code) { ApplicationArea = All; } field(Description; Rec.Description) { ApplicationArea = All; } field(Enabled; Rec.Enabled) { ApplicationArea = All; } } } }
}

page 50478 "SI EDS Operation Card"
{
    PageType = Card; SourceTable = "SI EDS Operation"; Caption = 'EDS: операція'; ApplicationArea = All;
    layout { area(Content) { group(General) {
        field("Service Code"; Rec."Service Code") { ApplicationArea = All; }
        field(Code; Rec.Code) { ApplicationArea = All; }
        field("Operation Group Code"; Rec."Operation Group Code") { ApplicationArea = All; }
        field(Description; Rec.Description) { ApplicationArea = All; }
        field("HTTP Method"; Rec."HTTP Method") { ApplicationArea = All; }
        field("Relative Path"; Rec."Relative Path") { ApplicationArea = All; }
        field(Enabled; Rec.Enabled) { ApplicationArea = All; }
        field("Log Response Body"; Rec."Log Response Body") { ApplicationArea = All; }
    } } }
}

page 50479 "SI EDS Provider Card"
{
    PageType = Card; SourceTable = "SI EDS Provider"; Caption = 'EDS: провайдер'; ApplicationArea = All;
    layout { area(Content) { group(General) { field(Code; Rec.Code) { ApplicationArea = All; } field(Description; Rec.Description) { ApplicationArea = All; } field(Enabled; Rec.Enabled) { ApplicationArea = All; } } } }
}

page 50480 "SI EDS Endpoint Card"
{
    PageType = Card; SourceTable = "SI EDS Endpoint"; Caption = 'EDS: точка підключення'; ApplicationArea = All;
    layout { area(Content) { group(General) {
        field("Provider Code"; Rec."Provider Code") { ApplicationArea = All; }
        field(Code; Rec.Code) { ApplicationArea = All; }
        field(Description; Rec.Description) { ApplicationArea = All; }
        field("Base URL"; Rec."Base URL") { ApplicationArea = All; }
        field(Priority; Rec.Priority) { ApplicationArea = All; }
        field(Enabled; Rec.Enabled) { ApplicationArea = All; }
    } } }
}

page 50481 "SI EDS Credential Card"
{
    PageType = Card; SourceTable = "SI EDS Credential"; Caption = 'EDS: облікові дані'; ApplicationArea = All;
    layout { area(Content) { group(General) {
        field("Provider Code"; Rec."Provider Code") { ApplicationArea = All; }
        field(Code; Rec.Code) { ApplicationArea = All; }
        field(Description; Rec.Description) { ApplicationArea = All; }
        field("Credential Type"; Rec."Credential Type") { ApplicationArea = All; }
        field(Enabled; Rec.Enabled) { ApplicationArea = All; }
        field(Configured; Configured) { ApplicationArea = All; Caption = 'Налаштовано'; Editable = false; }
        field("Last Changed At"; Rec."Last Changed At") { ApplicationArea = All; }
        field("Last Changed By"; Rec."Last Changed By") { ApplicationArea = All; }
    } } }
    actions { area(Processing) {
        action(SetSecret) { ApplicationArea = All; Caption = 'Встановити / змінити секрет'; Image = Edit; Promoted = true; PromotedCategory = Process;
            trigger OnAction()
            var SecretDialog: Page "SI EDS Secret Dialog"; SecretValue: Text;
            begin
                Rec.TestField("Provider Code"); Rec.TestField(Code);
                if SecretDialog.RunModal() <> Action::OK then exit;
                SecretValue := SecretDialog.GetSecretValue();
                CredentialMgt.SetSecretText(Rec."Provider Code", Rec.Code, SecretValue); Clear(SecretValue);
                UpdateCredentialAudit(); CurrPage.Update(false);
            end;
        }
        action(DeleteSecret) { ApplicationArea = All; Caption = 'Видалити секрет'; Image = Delete;
            trigger OnAction()
            begin
                if not Configured then exit;
                if not Confirm('Видалити секретне значення для %1 / %2?', false, Rec."Provider Code", Rec.Code) then exit;
                CredentialMgt.DeleteSecretText(Rec."Provider Code", Rec.Code); UpdateCredentialAudit(); CurrPage.Update(false);
            end;
        }
    } }
    trigger OnAfterGetRecord() begin Configured := CredentialMgt.HasSecret(Rec."Provider Code", Rec.Code); end;
    local procedure UpdateCredentialAudit()
    begin
        Rec."Last Changed At" := CurrentDateTime; Rec."Last Changed By" := CopyStr(UserId(), 1, MaxStrLen(Rec."Last Changed By")); Rec.Modify(false);
        Configured := CredentialMgt.HasSecret(Rec."Provider Code", Rec.Code);
    end;
    var CredentialMgt: Codeunit "SI EDS Credential Mgt."; Configured: Boolean;
}

page 50482 "SI EDS Provider Route Card"
{
    PageType = Card; SourceTable = "SI EDS Provider Route"; Caption = 'EDS: маршрут провайдера'; ApplicationArea = All;
    layout { area(Content) { group(General) {
        field("Service Code"; Rec."Service Code") { ApplicationArea = All; }
        field("Operation Code"; Rec."Operation Code") { ApplicationArea = All; }
        field(Priority; Rec.Priority) { ApplicationArea = All; }
        field("Provider Code"; Rec."Provider Code") { ApplicationArea = All; }
        field(Enabled; Rec.Enabled) { ApplicationArea = All; }
    } } }
}

page 50483 "SI EDS Parameter Card"
{
    PageType = Card; SourceTable = "SI EDS Parameter"; Caption = 'EDS: параметр'; ApplicationArea = All;
    layout { area(Content) { group(General) {
        field("Service Code"; Rec."Service Code") { ApplicationArea = All; }
        field("Operation Code"; Rec."Operation Code") { ApplicationArea = All; }
        field("Provider Code"; Rec."Provider Code") { ApplicationArea = All; }
        field(Sequence; Rec.Sequence) { ApplicationArea = All; }
        field(Code; Rec.Code) { ApplicationArea = All; }
        field("External Name"; Rec."External Name") { ApplicationArea = All; }
        field(Location; Rec.Location) { ApplicationArea = All; }
        field(Source; Rec.Source) { ApplicationArea = All; }
        field(Format; Rec.Format) { ApplicationArea = All; }
        field("Runtime Key"; Rec."Runtime Key") { ApplicationArea = All; }
        field(Value; Rec.Value) { ApplicationArea = All; }
        field("Credential Code"; Rec."Credential Code") { ApplicationArea = All; }
        field("Value Prefix"; Rec."Value Prefix") { ApplicationArea = All; }
        field(Required; Rec.Required) { ApplicationArea = All; }
        field(Enabled; Rec.Enabled) { ApplicationArea = All; }
    } } }
}
