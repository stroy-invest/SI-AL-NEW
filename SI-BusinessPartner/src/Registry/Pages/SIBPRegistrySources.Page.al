page 54090 "SI BP Registry Sources"
{
    Caption = 'Джерела реєстрових даних';
    PageType = List;
    SourceTable = "SI BP Registry Source";
    ApplicationArea = All;
    UsageCategory = Administration;
    DelayedInsert = true;
    SourceTableView = sorting("Entity Type", Priority);

    layout
    {
        area(Content)
        {
            repeater(Sources)
            {
                field("Entity Type"; Rec."Entity Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Тип контрагента, для якого використовується джерело.';
                }
                field(Priority; Rec.Priority)
                {
                    ApplicationArea = All;
                    ToolTip = 'Менше число означає вищий пріоритет у межах типу контрагента.';
                }
                field("Source Code"; Rec."Source Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Виберіть налаштований маршрут EDS. Код, назва, сервіс та операція заповняться автоматично.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        if Rec.SelectEDSRoute() then begin
                            CurrPage.Update(true);
                            exit(true);
                        end;
                        exit(false);
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("EDS Service Code"; Rec."EDS Service Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("EDS Operation Code"; Rec."EDS Operation Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
