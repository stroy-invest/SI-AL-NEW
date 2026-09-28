permissionset 60000 "SI CP ADMIN"
{
    Assignable = true;
    Caption = 'SI Construction Project Admin';

    Permissions =
        tabledata Customer = RIM,
        tabledata Job = RM,
        tabledata "Job Task" = RIM,
        tabledata Location = R,
        tabledata Employee = R,
        tabledata "SI Location Setup" = R,
        tabledata "SI Project Role" = RIMD,
        tabledata "SI Project Assignment" = RIMD,
        tabledata "SI Employee Project Role" = RIMD,
        tabledata "SI Construction Site" = RIM,
        tabledata "SI Site Assignment" = RIMD,
        table "SI Project Role" = X,
        table "SI Project Assignment" = X,
        table "SI Employee Project Role" = X,
        table "SI Construction Site" = X,
        table "SI Site Assignment" = X,
        codeunit "SI Internal Customer Mgt." = X,
        codeunit "SI Construction Project Mgt." = X,
        codeunit "SI Project Assignment Mgt." = X,
        codeunit "SI Construction Site Mgt." = X,
        codeunit "SI Job Task Mgt." = X,
        codeunit "SI Site Assignment Mgt." = X,
        page "SI Construction Projects" = X,
        page "SI Construction Project Card" = X,
        page "SI Project Assignments Part" = X,
        page "SI Project Roles" = X,
        page "SI Project System FactBox" = X,
        page "SI Project Admin Console" = X,
        page "SI Employee Project Roles Part" = X,
        page "SI Employee Project Roles" = X,
        page "SI Construction Sites" = X,
        page "SI Construction Site Card" = X,
        page "SI Site Job Tasks" = X,
        page "SI Site Assignments Part" = X;
}
