permissionset 57952 "SI PROK PLANFACT"
{
    Assignable = true;
    Caption = 'SI Proktek: звіт план/факт (читання)';

    Permissions =
        tabledata "SI Concrete Prod Request" = R,
        tabledata "SI Prok Production Plan" = R,
        tabledata "SI Prok Production Plan Line" = R,
        tabledata "SI Prok Production Fact" = R,
        tabledata "SI Prok Prod Fact Material" = R,
        tabledata "SI Prok Shipment" = R,
        tabledata "SI Supply Req Header" = R,
        tabledata Item = R,
        tabledata Job = R,
        table "SI Prok Fact Tree Buffer" = X,
        table "SI Prok PF Material Buffer" = X,
        page "SI Prok Fact Hierarchy" = X,
        codeunit "SI Prok PF Link Resolver" = X,
        codeunit "SI Prok Plan Fact Excel" = X,
        codeunit "SI Prok PF Template Writer" = X,
        table "SI Prok PF Concrete Group" = X,
        table "SI Prok PF Sum Fact Index" = X,
        page "SI Prok PF Sum Period" = X,
        codeunit "SI Prok PF Period Summary" = X,
        codeunit "SI Prok PF Sum Writer" = X,
        codeunit "SI Item UoM Conversion" = X;
}
