enum 61007 "SI Concrete Unloading Method"
{
    Extensible = true;
    Caption = 'Спосіб вивантаження бетону';

    value(0; " ") { Caption = ''; }
    value(10; "Self Discharge") { Caption = 'Самозлив'; }
    value(20; "Concrete Pump") { Caption = 'Бетононасос'; }
    value(30; Hopper) { Caption = 'Бункер'; }
    value(40; Other) { Caption = 'Інше'; }
}
