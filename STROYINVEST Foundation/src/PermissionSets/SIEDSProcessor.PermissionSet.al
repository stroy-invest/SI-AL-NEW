permissionset 50427 "SI EDS PROCESSOR"
{
    Assignable = true;
    Caption = 'SI EDS - Inbound Processor';

    Permissions =
        tabledata "SI EDS Inbound Event" = RM,
        table "SI EDS Inbound Event" = X;
}