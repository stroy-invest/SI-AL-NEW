tableextension 58000 "SI Unit of Measure Ext." extends "Unit of Measure"
{
    fields
    {
        field(58000; "SI Symbol"; Text[20])
        {
            Caption = 'Символ SI';
            DataClassification = CustomerContent;
        }
        field(58001; "SI Measurement System"; Enum "SI Measurement System")
        {
            Caption = 'Система вимірювання';
            DataClassification = CustomerContent;
        }
        field(58002; "SI UoM Kind"; Enum "SI UoM Kind")
        {
            Caption = 'Тип од. вим.';
            DataClassification = CustomerContent;
            NotBlank = true;

            trigger OnValidate()
            var
                SIUoMMgt: Codeunit "SI UoM Mgt.";
            begin
                SIUoMMgt.HandleKindChange(Rec);
            end;
        }
        field(58003; "SI Reference UoM Code"; Code[10])
        {
            Caption = 'Базова од. вим.';
            DataClassification = CustomerContent;
            TableRelation = "Unit of Measure".Code where("SI Blocked" = const(false));

            trigger OnValidate()
            begin
                if "SI Reference UoM Code" = Code then
                    Error('Одиниця вимірювання не може посилатися сама на себе.');
            end;
        }
        field(58004; "SI Conversion Factor"; Decimal)
        {
            Caption = 'Коефіцієнт перерахунку';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 10;

            trigger OnValidate()
            begin
                if "SI Conversion Factor" < 0 then
                    Error('Коефіцієнт перерахунку не може бути від’ємним.');
            end;
        }
        field(58005; "SI Numerator UoM Code"; Code[10])
        {
            Caption = 'Одиниця чисельника';
            DataClassification = CustomerContent;
            TableRelation = "Unit of Measure".Code where("SI Blocked" = const(false));

            trigger OnValidate()
            begin
                if "SI Numerator UoM Code" = Code then
                    Error('Одиниця вимірювання не може використовувати саму себе як чисельник.');
            end;
        }
        field(58006; "SI Denominator UoM Code"; Code[10])
        {
            Caption = 'Одиниця знаменника';
            DataClassification = CustomerContent;
            TableRelation = "Unit of Measure".Code where("SI Blocked" = const(false));

            trigger OnValidate()
            begin
                if "SI Denominator UoM Code" = Code then
                    Error('Одиниця вимірювання не може використовувати саму себе як знаменник.');
            end;
        }
        field(58007; "SI Blocked"; Boolean)
        {
            Caption = 'Не використовується';
            DataClassification = CustomerContent;
            ToolTip = 'Визначає, що одиниця вимірювання більше не повинна використовуватися в нових налаштуваннях. Існуючі дані при цьому зберігаються.';
        }
		// Додано 11.08.2026
        field(58008; "SI Describe"; Text[100])
        {
            Caption = 'Опис одиниці виміру';
            DataClassification = CustomerContent;
        }		
        field(58009; "SI Numerator Quantity"; Decimal)
        {
            Caption = 'Кількість чисельника';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 10;

            trigger OnValidate()
            begin
                if "SI Numerator Quantity" <= 0 then
                    Error('Кількість чисельника має бути більшою за нуль.');
            end;
        }
        field(58010; "SI Denominator Quantity"; Decimal)
        {
            Caption = 'Кількість знаменника';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 10;

            trigger OnValidate()
            begin
                if "SI Denominator Quantity" <= 0 then
                    Error('Кількість знаменника має бути більшою за нуль.');
            end;
        }
    }
}