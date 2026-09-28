page 57094 "SI Prok Order Diagnostic"
{
    PageType = StandardDialog;
    Caption = 'Порівняльна діагностика Proktek Order';

    layout
    {
        area(Content)
        {
            group(AnalysisGroup)
            {
                Caption = 'Результат порівняння';
                field(AnalysisText; AnalysisText)
                {
                    ApplicationArea = All;
                    Caption = 'Результат';
                    MultiLine = true;
                    Editable = false;
                }
            }
            group(BaselineGroup)
            {
                Caption = 'BASELINE — GET-ORDERS за сьогодні';
                field(BaselineRequestBody; BaselineRequestBody)
                {
                    ApplicationArea = All;
                    Caption = 'Request JSON';
                    MultiLine = true;
                    Editable = false;
                }
                field(BaselineResponseText; BaselineResponseText)
                {
                    ApplicationArea = All;
                    Caption = 'Response JSON';
                    MultiLine = true;
                    Editable = false;
                }
            }
            group(TargetGroup)
            {
                Caption = 'TARGET — GET-ORDERS за Required Date';
                field(TargetRequestBody; TargetRequestBody)
                {
                    ApplicationArea = All;
                    Caption = 'Request JSON';
                    MultiLine = true;
                    Editable = false;
                }
                field(TargetResponseText; TargetResponseText)
                {
                    ApplicationArea = All;
                    Caption = 'Response JSON';
                    MultiLine = true;
                    Editable = false;
                }
            }
        }
    }

    procedure SetDiagnostic(NewBaselineRequestBody: Text; NewBaselineResponseText: Text; NewTargetRequestBody: Text; NewTargetResponseText: Text; NewAnalysisText: Text)
    begin
        BaselineRequestBody := NewBaselineRequestBody;
        BaselineResponseText := NewBaselineResponseText;
        TargetRequestBody := NewTargetRequestBody;
        TargetResponseText := NewTargetResponseText;
        AnalysisText := NewAnalysisText;
    end;

    var
        BaselineRequestBody: Text;
        BaselineResponseText: Text;
        TargetRequestBody: Text;
        TargetResponseText: Text;
        AnalysisText: Text;
}
