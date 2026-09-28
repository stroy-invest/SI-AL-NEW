page 61036 "SI Vendor Supply Cap. Card"
{
    PageType = Card;
    SourceTable = "SI Vendor Supply Capability";
    Caption = 'Канал постачання постачальника';
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Загальне';

                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Показує системний код каналу постачання.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                    ToolTip = 'Визначає зрозумілу назву каналу постачання.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає поточний стан каналу. Для використання у sourcing канал має бути активним.';
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                    ToolTip = 'Визначає постачальника для цього каналу.';
                }
                field("Vendor Name"; Rec."Vendor Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Показує назву постачальника.';
                }
                field(CategoryDisplayName; CategoryDisplayName)
                {
                    ApplicationArea = All;
                    Caption = 'Категорія товару';
                    ShowMandatory = true;
                    AssistEdit = true;
                    ToolTip = 'Виберіть категорію товарів через єдиний селектор категорій STROYINVEST.';

                    trigger OnAssistEdit()
                    var
                        CategorySelector: Codeunit "SI Category Selector Mgt.";
                        CategoryCode: Code[20];
                    begin
                        CategoryCode := Rec."Item Category Code";
                        if not CategorySelector.SelectCategory(CategoryCode) then
                            exit;

                        Rec.Validate("Item Category Code", CategoryCode);
                        Rec.Modify(true);
                        CategoryDisplayName := CategorySelector.GetCategoryDisplayName(CategoryCode);
                        CurrPage.Update(false);
                    end;

                    trigger OnValidate()
                    var
                        CategorySelector: Codeunit "SI Category Selector Mgt.";
                    begin
                        CategoryDisplayName := CategorySelector.GetCategoryDisplayName(Rec."Item Category Code");
                    end;
                }
            }
            group(SupplyTerms)
            {
                Caption = 'Умови постачання';

                field("Shipment Method Code"; Rec."Shipment Method Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає стандартний спосіб або умови поставки Business Central для цього каналу.';
                }
                field("UoM Code"; Rec."UoM Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає одиницю виміру для мінімальної кількості та кратності замовлення.';
                }
                field("Minimum Order Quantity"; Rec."Minimum Order Quantity")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає мінімальну кількість замовлення для цього постачальника і каналу.';
                }
                field("Order Multiple"; Rec."Order Multiple")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає кратність замовлення для цього постачальника і каналу.';
                }
                field("Lead Time Calculation"; Rec."Lead Time Calculation")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає строк постачання через цей канал у стандартному форматі DateFormula Business Central.';
                }
                field("Valid From"; Rec."Valid From")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає дату початку дії каналу постачання.';
                }
                field("Valid To"; Rec."Valid To")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає дату завершення дії каналу постачання.';
                }
                field(Notes; Rec.Notes)
                {
                    ApplicationArea = All;
                    MultiLine = true;
                    ToolTip = 'Визначає додаткові умови або обмеження каналу постачання.';
                }
            }
            part(Manufacturers; "SI VSC Manufacturers")
            {
                ApplicationArea = All;
                Caption = 'Виробники';
                SubPageLink = "Capability Code" = field(Code);
                UpdatePropagation = Both;
            }
        }
    }
    trigger OnAfterGetRecord()
    var
        CategorySelector: Codeunit "SI Category Selector Mgt.";
    begin
        CategoryDisplayName := CategorySelector.GetCategoryDisplayName(Rec."Item Category Code");
    end;

    var
        CategoryDisplayName: Text[250];

}
