page 54080 "SI BP Template Settings"
{
    PageType = List;
    SourceTable = "SI BP Template Setting";
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'Налаштування шаблонів контрагентів';
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Settings)
            {
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає країну або регіон контрагента.';
                }
                field("Role Type"; Rec."Role Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає тип ролі контрагента, для якої застосовується правило.';
                }
                field("VAT Status"; Rec."VAT Status")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає статус платника ПДВ, для якого застосовується правило.';
                }
                field("Template Code"; Rec."Template Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає стандартний шаблон Business Central. Для покупця відкриваються шаблони клієнтів, для постачальника — шаблони постачальників.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        TemplateSelector: Codeunit "SI BP Template Selector";
                        SelectedTemplateCode: Code[20];
                    begin
                        if TemplateSelector.SelectTemplate(Rec."Role Type", SelectedTemplateCode) then begin
                            Rec.Validate("Template Code", SelectedTemplateCode);
                            Text := SelectedTemplateCode;
                            exit(true);
                        end;

                        exit(false);
                    end;
                }
                field(Active; Rec.Active)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає, чи бере правило участь в автоматичному виборі шаблону.';
                }
            }
        }
    }
}
