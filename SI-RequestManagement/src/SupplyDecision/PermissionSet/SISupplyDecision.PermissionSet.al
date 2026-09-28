permissionset 52049 "SI SUPPLY DECISION"
{
    Assignable = true;
    Caption = 'SI Supply Decision';

    Permissions =
        tabledata "SI Supply Decision Header" = RIMD,
        tabledata "SI Supply Decision Line" = RIMD,
        tabledata "SI Supply Allocation" = RIMD,
        table "SI Supply Decision Header" = X,
        table "SI Supply Decision Line" = X,
        table "SI Supply Allocation" = X,
        page "SI Supply Decision Card" = X,
        page "SI Supply Decision Lines" = X,
        page "SI Supply Allocations" = X,
        page "SI Supply Decisions" = X,
        page "SI Supply Creation Result" = X,
        codeunit "SI Supply Decision Mgt." = X;
}
