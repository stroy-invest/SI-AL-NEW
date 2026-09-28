pageextension 55014 "SI Config Wizard Mfr Name" extends "SI Product Config. Wizard"
{
    layout
    {
        addafter(CompactDescriptionPartsField)
        {
            field("SI Show Manufacturer in Name"; Rec."SI Show Manufacturer in Name")
            {
                ApplicationArea = All;
                Caption = 'Виводити назву виробника';
                Importance = Promoted;
                ToolTip = 'Якщо вимкнено, у назві використовується тільки назва схваленого продукту виробника. Якщо ввімкнено, після назви продукту додається назва виробника в дужках. За замовчуванням вимкнено.';

                trigger OnValidate()
                var
                    ProductConfig: Record "SI Product Config.";
                begin
                    if Rec."No." = '' then
                        exit;

                    if not ProductConfig.Get(Rec."No.") then
                        exit;

                    ProductConfig."SI Show Manufacturer in Name" :=
                        Rec."SI Show Manufacturer in Name";
                    ProductConfig.Modify(false);

                    // Refresh Step 2 so the base wizard recalculates live name preview.
                    CurrPage.Update(false);
                end;
            }
        }
    }
}
