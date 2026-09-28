page 53015 "SI Wiz. Family Params"
{
    PageType = List;
    SourceTable = "SI Family Parameter";
    ApplicationArea = All;
    Caption = 'Параметри сімейства';
    UsageCategory = None;

    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    SourceTableView =
        sorting(
            "Family Code",
            "Parameter Order",
            "Parameter Code");

    layout
    {
        area(Content)
        {
            repeater(Parameters)
            {
                field("Parameter Code"; Rec."Parameter Code")
                {
                    ApplicationArea = All;
                    Caption = 'Параметр';
                    Importance = Promoted;
                    ToolTip = 'Визначає параметр вибраного сімейства.';
                }

                field("Parameter Order"; Rec."Parameter Order")
                {
                    ApplicationArea = All;
                    Caption = 'Порядок';
                    ToolTip = 'Визначає порядок параметра в моделі сімейства.';
                }

                field(Mandatory; Rec.Mandatory)
                {
                    ApplicationArea = All;
                    Caption = 'Обов’язковий';
                    ToolTip = 'Визначає, чи є параметр обов’язковим.';
                }

                field("ERP Projection Role"; Rec."ERP Projection Role")
                {
                    ApplicationArea = All;
                    Caption = 'Роль в ERP';
                    ToolTip = 'Визначає роль параметра в ERP-проєкції.';
                }
            }
        }
    }
}