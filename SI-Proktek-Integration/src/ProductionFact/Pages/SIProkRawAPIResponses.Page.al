page 57098 "SI Prok Raw API Responses"
{
    PageType = List;
    SourceTable = "SI Prok Raw API Response";
    Caption = 'Архів відповідей Proktek';
    ApplicationArea = All;
    UsageCategory = Tasks;
    Editable = false;
    CardPageId = "SI Prok Raw API Response Card";
    SourceTableView = sorting("Entry No.") order(descending);
    layout
    {
        area(Content)
        {
            repeater(Responses)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field("Received At"; Rec."Received At") { ApplicationArea = All; }
                field("Connection Code"; Rec."Connection Code") { ApplicationArea = All; }
                field("API Operation"; Rec."API Operation") { ApplicationArea = All; }
                field("Production UUID"; Rec."Production UUID") { ApplicationArea = All; }
                field("Capture Mode"; Rec."Capture Mode") { ApplicationArea = All; }
                field("Intake Result"; Rec."Intake Result") { ApplicationArea = All; }
                field("Production Fact Entry No."; Rec."Production Fact Entry No.") { ApplicationArea = All; }
                field("Processing Status"; Rec."Processing Status") { ApplicationArea = All; }
                field("Error Message"; Rec."Error Message") { ApplicationArea = All; }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(DownloadRaw)
            {
                Caption = 'Завантажити первинний JSON';
                ApplicationArea = All;
                Image = Download;
                trigger OnAction()
                var I: InStream; FileName: Text;
                begin
                    Rec.CalcFields("Raw JSON");
                    if not Rec."Raw JSON".HasValue() then exit;
                    Rec."Raw JSON".CreateInStream(I, TextEncoding::UTF8);
                    FileName := StrSubstNo('Proktek_Raw_%1.json', Rec."Entry No.");
                    DownloadFromStream(I, '', '', '', FileName);
                end;
            }
        }
    }
}
