page 63256 "SI Vehicle Models"
{
    PageType = List;
    SourceTable = "SI Vehicle Model";
    CardPageId = "SI Vehicle Model Card";
    Caption = 'Моделі транспорту';
    ApplicationArea = All;
    UsageCategory = Lists;
    layout
    {
        area(Content)
        {
            repeater(Models)
            {
                field("Brand Code"; Rec."Brand Code") { ApplicationArea = All; }
                field(Code; Rec.Code) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
                field("Vehicle Type Code"; Rec."Vehicle Type Code") { ApplicationArea = All; }
                field(Blocked; Rec.Blocked) { ApplicationArea = All; }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(OpenModelCard)
            {
                Caption = 'Відкрити картку моделі';
                ApplicationArea = All;
                Image = EditLines;
                trigger OnAction()
                begin
                    Page.Run(Page::"SI Vehicle Model Card", Rec);
                end;
            }
            action(MigrateLegacyCapacities)
            {
                Caption = 'Перенести характеристики ТЗ на моделі';
                ApplicationArea = All;
                Image = Process;
                trigger OnAction()
                var
                    Migration: Codeunit "SI Vehicle Capacity Migration";
                begin
                    Migration.MigrateLegacyCapacities();
                end;
            }
        }
    }
}
