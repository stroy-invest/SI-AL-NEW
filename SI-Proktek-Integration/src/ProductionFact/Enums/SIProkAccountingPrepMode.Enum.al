enum 57115 "SI Prok Accounting Prep Mode"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'Режими облікової перевірки більше не використовуються.';
    ObsoleteTag = '1.0.0.79';
    Extensible = false;
    value(0; Production) { Caption = 'Реальний облік'; }
    value(1; Simulation) { Caption = 'Застаріле значення (не використовується)'; }
}
