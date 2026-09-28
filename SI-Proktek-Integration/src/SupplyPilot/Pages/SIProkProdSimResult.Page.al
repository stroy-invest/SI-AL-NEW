page 57077 "SI Prok Prod Sim Result"
{
    PageType = Card;
    Caption = 'Proktek Production Simulator — Step 7';
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Info)
            {
                Caption = 'Результат';
                field(Scenario; Scenario) { ApplicationArea = All; Caption = 'Сценарій'; Editable = false; }
            }
            group(GetProductionsRaw)
            {
                Caption = 'GetProductions — RAW JSON AS IS';
                field(ProductionsJson; ProductionsJson) { ApplicationArea = All; Caption = 'JSON'; Editable = false; MultiLine = true; }
            }
            group(GetProductionDetailsRaw)
            {
                Caption = 'GetProductionDetails — RAW JSON AS IS';
                field(DetailsJson; DetailsJson) { ApplicationArea = All; Caption = 'JSON'; Editable = false; MultiLine = true; }
            }
            group(GetMaterialsConfigRaw)
            {
                Caption = 'GetMaterialsConfig — RAW JSON AS IS';
                field(MaterialsJson; MaterialsJson) { ApplicationArea = All; Caption = 'JSON'; Editable = false; MultiLine = true; }
            }
            group(Canonical)
            {
                Caption = 'Canonical Production — після штатного parser';
                field(CanonicalJson; CanonicalJson) { ApplicationArea = All; Caption = 'JSON'; Editable = false; MultiLine = true; }
            }
            group(Analysis)
            {
                Caption = 'Correlation / Plan vs Actual analysis';
                field(AnalysisJson; AnalysisJson) { ApplicationArea = All; Caption = 'JSON'; Editable = false; MultiLine = true; }
            }
        }
    }

    procedure SetPayloads(NewScenario: Text; NewProductionsJson: Text; NewDetailsJson: Text; NewMaterialsJson: Text; NewCanonicalJson: Text; NewAnalysisJson: Text)
    begin
        Scenario := CopyStr(NewScenario, 1, MaxStrLen(Scenario));
        ProductionsJson := NewProductionsJson;
        DetailsJson := NewDetailsJson;
        MaterialsJson := NewMaterialsJson;
        CanonicalJson := NewCanonicalJson;
        AnalysisJson := NewAnalysisJson;
    end;

    var
        Scenario: Text[30];
        ProductionsJson: Text;
        DetailsJson: Text;
        MaterialsJson: Text;
        CanonicalJson: Text;
        AnalysisJson: Text;
}
