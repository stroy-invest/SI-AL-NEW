pageextension 58003 "SI Item Attribute Card Ext." extends "Item Attribute"
{
    layout
    {
        /*
        modify(Type)
        {
            trigger OnAfterValidate()
            begin
                //UpdateUoMVisibility();
                CurrPage.Update(false);
            end;
        }
        */
        modify("Unit of Measure")
        {
            Visible = false;
        }

        addafter(Type)
        {
            field("SI UoM Code"; Rec."SI UoM Code")
            {
                ApplicationArea = All;
                Caption = 'Одиниця виміру';
                ToolTip = 'Specifies the controlled unit of measure for a numeric item attribute.';
                // Visible = UoMVisible;
            }
        }
    }

    trigger OnOpenPage()
    begin
        //UpdateUoMVisibility();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        //UpdateUoMVisibility();
    end;

    var
        UoMVisible: Boolean;

    local procedure UpdateUoMVisibility()
    begin
        UoMVisible :=
            (Rec.Type = Rec.Type::Integer) or
            (Rec.Type = Rec.Type::Decimal);
    end;
}