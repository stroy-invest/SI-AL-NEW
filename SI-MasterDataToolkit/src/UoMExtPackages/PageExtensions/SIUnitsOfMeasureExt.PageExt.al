pageextension 58000 "SI Units of Measure Ext." extends "Units of Measure"
{
    layout
    {
        addafter(Description)
        { // Додано 11.08.2026
            field("SI Description"; Rec."SI Describe")
            {
                ApplicationArea = All;
                ToolTip = 'Визначає розгорнутий опис одиниці вимірювання';
				Caption = 'Опис одиниці виміру';
            }
			
            field("SI Symbol"; Rec."SI Symbol")
            {
                ApplicationArea = All;
                ToolTip = 'Визначає коротке позначення одиниці вимірювання, наприклад кг, м³ або шт.';
            }

            field("SI Measurement System"; Rec."SI Measurement System")
            {
                ApplicationArea = All;
                ToolTip = 'Визначає систему, до якої належить одиниця вимірювання.';
            }

            field("SI UoM Kind"; Rec."SI UoM Kind")
            {
                ApplicationArea = All;
                ShowMandatory = true;
                ToolTip = 'Визначає структурний тип одиниці: базова, масштабована або похідна.';
            }

            field("SI Blocked"; Rec."SI Blocked")
            {
                ApplicationArea = All;
                Caption = 'Не використовується';
                ToolTip = 'Визначає, що одиниця вимірювання більше не використовується в нових налаштуваннях. Існуючі дані при цьому зберігаються.';
            }
        }
    }

    actions
    {
        addfirst(Processing)
        {
            action("SI Open UoM Card")
            {
                ApplicationArea = All;
                Caption = 'Відкрити картку';
                Image = EditLines;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Відкриває картку для повного налаштування одиниці вимірювання.';

                trigger OnAction()
                var
                    UnitOfMeasure: Record "Unit of Measure";
                begin
                    UnitOfMeasure := Rec;

                    Page.RunModal(
                        Page::"SI Unit of Measure Card",
                        UnitOfMeasure);

                    CurrPage.Update(false);
                end;
            }
        }
    }
}