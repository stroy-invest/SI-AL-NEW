page 50501 "SI Location Setup"
{
    PageType = Card;
    SourceTable = "SI Location Setup";
    Caption = 'Налаштування типів складів';
    ApplicationArea = All;
    UsageCategory = Administration;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Семантичні типи складів';
                field("Finished Goods Type"; Rec."Finished Goods Type") { ApplicationArea = All; }
                field("Main Warehouse Type"; Rec."Main Warehouse Type") { ApplicationArea = All; }
                field("Material Warehouse Type"; Rec."Material Warehouse Type") { ApplicationArea = All; }
                field("Metal Warehouse Type"; Rec."Metal Warehouse Type") { ApplicationArea = All; }
                field("Fuel Warehouse Type"; Rec."Fuel Warehouse Type") { ApplicationArea = All; }
                field("Project Location Type"; Rec."Project Location Type") { ApplicationArea = All; }
                field("Department Location Type"; Rec."Department Location Type") { ApplicationArea = All; }
                field("Vehicle Location Type"; Rec."Vehicle Location Type") { ApplicationArea = All; }
                field("Location No. Series"; Rec."Location No. Series")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає серію номерів для автоматичного створення системних складів STROYINVEST.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert(true);
            Rec.Get();
        end;
    end;
}
