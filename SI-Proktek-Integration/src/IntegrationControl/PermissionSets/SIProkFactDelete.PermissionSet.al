permissionset 57963 "SI PROK FACT DELETE"
{
    Assignable = true;
    Caption = 'SI Proktek: видалення симуляцій';
    Permissions =
        codeunit "SI Prok Sim Fact Admin Delete" = X,
        tabledata "SI Prok Sim Fact Del Audit" = R,
        table "SI Prok Sim Fact Del Audit" = X;
}
