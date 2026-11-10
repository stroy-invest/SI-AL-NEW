table 57099 "SI Prok Production Plan"
{
    Caption = 'План виробництва бетону';
    DataClassification = CustomerContent;
    fields
    {
        field(1; "Prod. Request Entry No."; Integer) { Caption = '№ виробничої заявки'; TableRelation = "SI Concrete Prod Request"."Entry No."; }
        field(10; "Source No."; Code[30]) { Caption = 'Вихідна заявка'; Editable = false; }
        field(20; "Item No."; Code[20]) { Caption = 'Продукція'; Editable = false; }
        field(30; "Variant Code"; Code[10]) { Caption = 'Варіант'; Editable = false; }
        field(40; "Planned Quantity"; Decimal) { Caption = 'Плановий обсяг'; DecimalPlaces = 0 : 5; Editable = false; }
        field(50; "Unit of Measure Code"; Code[10]) { Caption = 'Одиниця виміру'; Editable = false; }
        field(60; "Recipe No."; Code[50]) { Caption = 'Рецептура'; Editable = false; }
        field(70; "Recipe Revision No."; Integer) { Caption = 'Ревізія'; Editable = false; }
        field(80; "Production BOM No."; Code[20]) { Caption = 'Виробнича специфікація'; Editable = false; }
        field(90; "Production BOM Version Code"; Code[20]) { Caption = 'Версія специфікації'; Editable = false; }
        field(100; "Created At"; DateTime) { Caption = 'Створено'; Editable = false; }
        field(110; "Created By"; Code[50]) { Caption = 'Створив'; Editable = false; }
        field(120; "BC Prod. Order Status"; Enum "Production Order Status") { Caption = 'Статус виробничого замовлення BC'; Editable = false; }
        field(130; "BC Prod. Order No."; Code[20]) { Caption = 'Виробниче замовлення BC'; Editable = false; TableRelation = "Production Order"."No." where(Status = field("BC Prod. Order Status")); }
    }
    keys { key(PK; "Prod. Request Entry No.") { Clustered = true; } }
}
