enum 56200 "SI Workforce Provider Type" implements "SI Workforce Provider"
{
    Extensible = true;
    Caption = 'SI Workforce Provider Type';

    value(0; IW)
    {
        Caption = 'IW HR & Payroll';
        Implementation = "SI Workforce Provider" = "SI IW Workforce Provider";
    }
}
