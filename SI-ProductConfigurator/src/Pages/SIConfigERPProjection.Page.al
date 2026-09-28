page 53021 "SI Config. ERP Projection"
{
    PageType = Card;
    SourceTable = "SI Config. ERP Projection";
    ApplicationArea = All;
    Caption = 'ERP-проєкція конфігурації';
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(Context)
            {
                Caption = 'Конфігурація';

                field("Configuration No."; Rec."Configuration No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Визначає конфігурацію продукту.';
                }

                field("Family Code"; Rec."Family Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Визначає сімейство продукту.';
                }

                field("Item Projection Key"; Rec."Item Projection Key")
                {
                    ApplicationArea = All;
                    Editable = false;
                    MultiLine = true;
                    ToolTip = 'Визначає ключ, сформований із параметрів з роллю «Формує товар».';
                }

                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Визначає стан ERP-проєкції.';
                }
            }

            group(ERPObjects)
            {
                Caption = 'Об’єкти Business Central';

                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    Editable = ProjectionEditable;
                    ToolTip = 'Визначає стандартний товар Business Central, що відповідає параметрам рівня Item.';
                }

                field("Item Description"; Rec."Item Description")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Визначає назву вибраного товару.';
                }

                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    Editable = ProjectionEditable;
                    ToolTip = 'Визначає стандартний варіант товару Business Central, що відповідає повній конфігурації.';
                }

                field("Variant Description"; Rec."Variant Description")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Визначає назву вибраного варіанта товару.';
                }

                field("Item Projection Entry No."; Rec."Item Projection Entry No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Визначає запис спільної ERP-проєкції товару.';
                }
            }

            group(Audit)
            {
                Caption = 'Фіксація проєкції';

                field("Projected At"; Rec."Projected At")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Визначає дату й час фіксації ERP-проєкції.';
                }

                field("Projected By"; Rec."Projected By")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Визначає користувача, який зафіксував ERP-проєкцію.';
                }

                field("Last Error"; Rec."Last Error")
                {
                    ApplicationArea = All;
                    Editable = false;
                    MultiLine = true;
                    ToolTip = 'Визначає текст останньої помилки проєкції.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Refresh)
            {
                ApplicationArea = All;
                Caption = 'Оновити проєкцію';
                Image = Refresh;
                Enabled = ProjectionEditable;
                ToolTip = 'Перебудовує ключі та згенеровані значення ERP-проєкції з актуальних параметрів конфігурації.';

                trigger OnAction()
                var
                    ERPProjectionMgt: Codeunit "SI ERP Projection Mgt.";
                begin
                    ERPProjectionMgt.PopulateProjectionFromConfiguration(Rec);
                    Rec.Modify(true);
                    CurrPage.Update(false);
                end;
            }

            action(OpenPreview)
            {
                ApplicationArea = All;
                Caption = 'Попередній перегляд';
                Image = View;
                ToolTip = 'Формує та відкриває актуальний попередній перегляд ERP-проєкції.';

                trigger OnAction()
                var
                    ERPProjectionMgt: Codeunit "SI ERP Projection Mgt.";
                begin
                    Rec.TestField("Configuration No.");
                    ERPProjectionMgt.OpenPreview(Rec."Configuration No.");
                end;
            }

            action(OpenItem)
            {
                ApplicationArea = All;
                Caption = 'Відкрити товар';
                Image = Item;
                ToolTip = 'Відкриває картку стандартного товару Business Central.';

                trigger OnAction()
                var
                    Item: Record Item;
                begin
                    Rec.TestField("Item No.");
                    Item.Get(Rec."Item No.");
                    Page.Run(Page::"Item Card", Item);
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

                    if ProductConfig.Get(ConfigurationNo) then
                        ERPProjectionMgt.DeleteProjection(ConfigurationNo)
                    else
                        CleanupMgt.ForceDeleteUnmaterialized(Rec);

                    CurrPage.Close();
                end;
            }

            action(OpenVariant)
            {
                ApplicationArea = All;
                Caption = 'Відкрити варіанти';
                Image = ItemVariant;
                ToolTip = 'Відкриває список варіантів вибраного товару.';

                trigger OnAction()
                var
                    ItemVariant: Record "Item Variant";
                begin
                    Rec.TestField("Item No.");
                    ItemVariant.SetRange("Item No.", Rec."Item No.");
                    if Rec."Variant Code" <> '' then
                        ItemVariant.SetRange(Code, Rec."Variant Code");
                    Page.Run(Page::"Item Variants", ItemVariant);
                end;
            }
        }

        area(Promoted)
        {
            actionref(RefreshPromoted; Refresh)
            {
            }

            actionref(OpenPreviewPromoted; OpenPreview)
            {
            }

            actionref(OpenItemPromoted; OpenItem)
            {
            }

            actionref(CleanupProjectionPromoted; CleanupProjection)
            {
            }
        }
    }

    trigger OnOpenPage()
    begin
        UpdatePageState();
    end;

    trigger OnAfterGetRecord()
    begin
        UpdatePageState();
    end;

    local procedure UpdatePageState()
    var
        CleanupMgt: Codeunit "SI ERP Projection Cleanup Mgt.";
    begin
        ProjectionEditable := Rec.Status <> Rec.Status::Projected;
        CleanupAllowed := CleanupMgt.IsForceDeleteAllowed(Rec);
    end;

    var
        ProjectionEditable: Boolean;
        CleanupAllowed: Boolean;
}
