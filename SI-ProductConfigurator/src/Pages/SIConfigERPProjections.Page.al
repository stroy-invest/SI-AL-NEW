page 53022 "SI Config. ERP Projections"
{
    PageType = List;
    SourceTable = "SI Config. ERP Projection";
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'ERP-проєкції конфігурацій';
    CardPageId = "SI Config. ERP Projection";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Projections)
            {
                field("Configuration No."; Rec."Configuration No.")
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    ToolTip = 'Визначає конфігурацію продукту.';
                }

                field("Family Code"; Rec."Family Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає сімейство продукту.';
                }

                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    ToolTip = 'Визначає стандартний товар Business Central.';
                }

                field("Item Description"; Rec."Item Description")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає назву товару.';
                }

                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    ToolTip = 'Визначає стандартний варіант товару Business Central.';
                }

                field("Variant Description"; Rec."Variant Description")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає назву варіанта.';
                }

                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає стан ERP-проєкції.';
                }

                field("Projected At"; Rec."Projected At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає дату й час фіксації проєкції.';
                }

                field("Projected By"; Rec."Projected By")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає користувача, який зафіксував проєкцію.';
                }
            }
        }
    }


    actions
    {
        area(Processing)
        {
            action(RepairInvalidSharedItemMapping)
            {
                ApplicationArea = All;
                Caption = 'Виправити помилковий зв’язок';
                Image = Refresh;
                Enabled = RepairAllowed;
                ToolTip = 'Видаляє помилкове зіставлення різних семантичних ERP-проєкцій з одним товаром. Сам товар Business Central не видаляється.';

                trigger OnAction()
                var
                    CleanupMgt: Codeunit "SI ERP Projection Cleanup Mgt.";
                begin
                    CleanupMgt.RepairInvalidSharedItemMapping(Rec);
                    CurrPage.Update(false);
                end;
            }

            action(CleanupProjection)
            {
                ApplicationArea = All;
                Caption = 'Очистити проєкцію';
                Image = Delete;
                Enabled = CleanupAllowed;
                ToolTip = 'Якщо стандартний товар/варіант уже відсутній, видаляє пов’язану конфігурацію разом зі службовою ERP-проєкцією. Стандартні товари та варіанти Business Central не видаляються.';

                trigger OnAction()
                var
                    ProductConfig: Record "SI Product Config.";
                    CleanupMgt: Codeunit "SI ERP Projection Cleanup Mgt.";
                    ERPProjectionMgt: Codeunit "SI ERP Projection Mgt.";
                    ConfigurationNo: Code[20];
                begin
                    ConfigurationNo := Rec."Configuration No.";

                    if ProductConfig.Get(ConfigurationNo) then begin
                        if ERPProjectionMgt.DeleteProjection(ConfigurationNo) then
                            CurrPage.Update(false);
                    end else begin
                        CleanupMgt.ForceDeleteUnmaterialized(Rec);
                        CurrPage.Update(false);
                    end;
                end;
            }
        }

        area(Promoted)
        {
            actionref(RepairInvalidSharedItemMappingPromoted; RepairInvalidSharedItemMapping)
            {
            }

            actionref(CleanupProjectionPromoted; CleanupProjection)
            {
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        UpdatePageState();
    end;

    local procedure UpdatePageState()
    var
        CleanupMgt: Codeunit "SI ERP Projection Cleanup Mgt.";
    begin
        CleanupAllowed := CleanupMgt.IsForceDeleteAllowed(Rec);
        RepairAllowed := CleanupMgt.CanRepairInvalidSharedItemMapping(Rec);
    end;

    var
        CleanupAllowed: Boolean;
        RepairAllowed: Boolean;
}
