permissionset 57951 "SI PROK BAF API"
{
    Assignable = true;
    Caption = 'SI Proktek BAF API';

    Permissions =
        tabledata "SI Prok Export Request" = RIM,
        table "SI Prok Export Request" = X,
        page "SI Prok Export Requests API" = X,
        page "SI Prok Export Results API" = X,
        codeunit "SI Prok Export Request Mgt." = X,
        codeunit "SI Prok Export Job" = X,
        codeunit "SI Prok Export Execute" = X,
        codeunit "SI Prok Production Export Mgt." = X,
        codeunit "SI Prok Productions" = X,
        codeunit "SI Prok Auth Mgt." = X,
        codeunit "SI Prok Login Builder" = X,
        codeunit "SI Prok Login Resolver" = X,
        codeunit "SI Prok Connection Mgt." = X,
        codeunit "SI EDS Provider Context" = X,
        tabledata "SI Prok Production Export" = RIMD,
        tabledata "SI Prok Connection" = R,
        tabledata "SI Prok Session" = RIMD;
}
