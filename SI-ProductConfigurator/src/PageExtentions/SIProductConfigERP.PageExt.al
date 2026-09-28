pageextension 53022 "SI Product Config ERP Ext" extends "SI Product Config. Card"
{
    layout
    {
        addafter(General)
        {
            group(ERPProjection)
            {
                Caption = 'ERP-проєкція';

                field(ERPItemNo; ERPItemNo)
                {
                    ApplicationArea = All;
                    Caption = 'Номер товару BC';
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Показує стандартний товар Business Central, пов’язаний із конфігурацією.';

                    trigger OnDrillDown()
                    var
                        Item: Record Item;
                    begin
                        if ERPItemNo = '' then
                            exit;

                        Item.Get(ERPItemNo);
                        Page.Run(Page::"Item Card", Item);
                    end;
                }

                field(ERPVariantCode; ERPVariantCode)
                {
                    ApplicationArea = All;
                    Caption = 'Код варіанта BC';
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Показує стандартний варіант товару Business Central, пов’язаний із конфігурацією.';
                }

                field(ERPProjectionStatus; ERPProjectionStatus)
                {
                    ApplicationArea = All;
                    Caption = 'Статус ERP-проєкції';
                    Editable = false;
                    ToolTip = 'Показує стан ERP-проєкції конфігурації.';
                }
            }
        }
    }

    actions
    {
        addlast(Processing)
        {
            action(PreviewERPProjection)
            {
                ApplicationArea = All;
                Caption = 'Перегляд ERP-проєкції';
                Image = ViewDetails;
                ToolTip = 'Формує та показує майбутній товар і варіант без створення об’єктів Business Central.';

                trigger OnAction()
                var
                    ERPProjectionMgt: Codeunit "SI ERP Projection Mgt.";
                begin
                    Rec.TestField("No.");
                    ERPProjectionMgt.OpenPreview(Rec."No.");
                end;
            }
        }

        addlast(Promoted)
        {
            actionref(PreviewERPProjectionProm; PreviewERPProjection)
            {
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        LoadProjection();
    end;

    local procedure LoadProjection()
    var
        ConfigProjection: Record "SI Config. ERP Projection";
    begin
        Clear(ERPItemNo);
        Clear(ERPVariantCode);
        Clear(ERPProjectionStatus);

        if Rec."No." = '' then
            exit;

        if not ConfigProjection.Get(Rec."No.") then
            exit;

        ERPItemNo := ConfigProjection."Item No.";
        ERPVariantCode := ConfigProjection."Variant Code";
        ERPProjectionStatus := ConfigProjection.Status;
    end;

    var
        ERPItemNo: Code[20];
        ERPVariantCode: Code[10];
        ERPProjectionStatus: Enum "SI ERP Projection Status";
}
